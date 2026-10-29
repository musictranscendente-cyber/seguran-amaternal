#!/usr/bin/env python3
"""Aplica a configuração Android necessária depois de `flutter create`.

Uso:
  python3 tool/preparar_android.py <app_dir> [--crianca] [--maps-key CHAVE]

Patch idempotente de:
  - AndroidManifest.xml (permissões, isMonitoringTool, Maps key, Device Admin)
  - settings.gradle / app build.gradle (plugin google-services, minSdk 23)
  - arquivos do Device Admin (app da criança)
"""
import argparse
import os
import re
import sys

PERMS_COMUNS = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
]
PERMS_CRIANCA = [
    "android.permission.ACCESS_BACKGROUND_LOCATION",
    "android.permission.RECORD_AUDIO",
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_LOCATION",
    "android.permission.FOREGROUND_SERVICE_MICROPHONE",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
]

GMS_VERSAO = "4.4.2"


def ler(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def escrever(p, c):
    with open(p, "w", encoding="utf-8") as f:
        f.write(c)
    print(f"  escrito: {p}")


def patch_manifest(app_dir, crianca, maps_key, pacote):
    p = os.path.join(app_dir, "android/app/src/main/AndroidManifest.xml")
    m = ler(p)

    perms = PERMS_COMUNS + (PERMS_CRIANCA if crianca else [])
    linhas = ""
    for perm in perms:
        if f'android:name="{perm}"' not in m:
            linhas += f'    <uses-permission android:name="{perm}"/>\n'
    if linhas:
        m = re.sub(r"(<manifest[^>]*>\n)", r"\1" + linhas, m, count=1)

    # Itens dentro de <application>
    extras = ""
    if crianca and "isMonitoringTool" not in m:
        extras += (
            '        <meta-data android:name="isMonitoringTool" '
            'android:value="true"/>\n'
        )
    if (not crianca) and maps_key and "com.google.android.geo.API_KEY" not in m:
        extras += (
            '        <meta-data android:name="com.google.android.geo.API_KEY" '
            f'android:value="{maps_key}"/>\n'
        )
    if crianca and ".AdminReceiver" not in m:
        extras += (
            '        <receiver android:name=".AdminReceiver"\n'
            '            android:permission="android.permission.BIND_DEVICE_ADMIN"\n'
            '            android:exported="true">\n'
            '            <meta-data android:name="android.app.device_admin"\n'
            '                android:resource="@xml/device_admin"/>\n'
            '            <intent-filter>\n'
            '                <action android:name="android.app.action.DEVICE_ADMIN_ENABLED"/>\n'
            '            </intent-filter>\n'
            '        </receiver>\n'
        )
    if extras:
        # insere antes do fechamento da tag <application>
        m = re.sub(r"(\n\s*</application>)", "\n" + extras + r"\1", m, count=1)

    escrever(p, m)


def patch_device_admin(app_dir, pacote):
    # res/xml/device_admin.xml
    xml_dir = os.path.join(app_dir, "android/app/src/main/res/xml")
    os.makedirs(xml_dir, exist_ok=True)
    escrever(
        os.path.join(xml_dir, "device_admin.xml"),
        '<device-admin xmlns:android="http://schemas.android.com/apk/res/android">\n'
        "  <uses-policies>\n"
        "    <force-lock/>\n"
        "  </uses-policies>\n"
        "</device-admin>\n",
    )
    # AdminReceiver.kt no pacote do app
    kt_dir = os.path.join(
        app_dir, "android/app/src/main/kotlin", *pacote.split(".")
    )
    os.makedirs(kt_dir, exist_ok=True)
    escrever(
        os.path.join(kt_dir, "AdminReceiver.kt"),
        f"package {pacote}\n\n"
        "import android.app.admin.DeviceAdminReceiver\n\n"
        "class AdminReceiver : DeviceAdminReceiver()\n",
    )


def patch_gradle(app_dir):
    # settings.gradle (groovy) — declara o plugin google-services
    for nome in ("settings.gradle", "settings.gradle.kts"):
        sp = os.path.join(app_dir, "android", nome)
        if not os.path.exists(sp):
            continue
        s = ler(sp)
        if "com.google.gms.google-services" in s:
            break
        if nome.endswith(".kts"):
            linha = f'    id("com.google.gms.google-services") version "{GMS_VERSAO}" apply false\n'
        else:
            linha = f'    id "com.google.gms.google-services" version "{GMS_VERSAO}" apply false\n'
        # adiciona dentro do primeiro bloco plugins { ... }
        s2 = re.sub(r"(plugins\s*\{\n)", r"\1" + linha, s, count=1)
        if s2 != s:
            escrever(sp, s2)
        break

    # app/build.gradle — aplica o plugin + minSdk 23
    for nome in ("build.gradle", "build.gradle.kts"):
        bp = os.path.join(app_dir, "android/app", nome)
        if not os.path.exists(bp):
            continue
        b = ler(bp)
        if "com.google.gms.google-services" not in b:
            if nome.endswith(".kts"):
                linha = '    id("com.google.gms.google-services")\n'
            else:
                linha = '    id "com.google.gms.google-services"\n'
            b = re.sub(r"(plugins\s*\{\n)", r"\1" + linha, b, count=1)
        # minSdk >= 23 (exigido pelo flutter_webrtc)
        b = re.sub(r"minSdk(Version)?\s*=?\s*flutter\.minSdkVersion",
                   "minSdk = 23", b)
        b = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion",
                   "minSdkVersion 23", b)
        escrever(bp, b)
        break


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("app_dir")
    ap.add_argument("--crianca", action="store_true")
    ap.add_argument("--maps-key", default="")
    args = ap.parse_args()

    nome_app = os.path.basename(os.path.normpath(args.app_dir))
    pacote = f"com.seguranca.{nome_app}"

    print(f"Preparando {args.app_dir} (pacote {pacote})")
    patch_manifest(args.app_dir, args.crianca, args.maps_key, pacote)
    patch_gradle(args.app_dir)
    if args.crianca:
        patch_device_admin(args.app_dir, pacote)
    print("OK")


if __name__ == "__main__":
    sys.exit(main())
