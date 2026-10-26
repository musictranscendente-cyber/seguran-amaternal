# Configuração — passo a passo

Guia para colocar os dois apps no ar. Tudo no plano **gratuito** do Firebase.

## 0. Gerar as pastas de plataforma (uma vez)

O repositório traz só o código Dart. Gere as pastas `android/` em cada app:

```bash
cd apps/responsavel && flutter create --platforms=android --org com.seguranca .
cd ../crianca && flutter create --platforms=android --org com.seguranca .
```

## 1. Projeto Firebase

1. Crie um projeto em https://console.firebase.google.com (plano "Spark", grátis).
2. Ative:
   - **Authentication** → método **E-mail/senha** (app do responsável) e
     **Anônimo** (app da criança).
   - **Cloud Firestore**.
   - **Storage** (clipes da escuta).
3. Gere a configuração em cada app:
   ```bash
   dart pub global activate flutterfire_cli
   cd apps/responsavel && flutterfire configure
   cd ../crianca && flutterfire configure
   ```
   (baixa o `google-services.json` — já está no `.gitignore`).
4. Publique as regras:
   ```bash
   firebase deploy --only firestore:rules,storage
   ```
   (usando `backend/firestore.rules` e `backend/storage.rules`).

## 2. Chave do Google Maps (app do responsável)

API "Maps SDK for Android" no Google Cloud. Em
`apps/responsavel/android/app/src/main/AndroidManifest.xml`, dentro de
`<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="SUA_CHAVE_AQUI"/>
```

## 3. Permissões (app da criança)

Em `apps/crianca/android/app/src/main/AndroidManifest.xml`, antes de
`<application>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

E dentro de `<application>` a flag exigida pela política de monitoramento:

```xml
<meta-data android:name="isMonitoringTool" android:value="true"/>
```

> `ACCESS_BACKGROUND_LOCATION` precisa ser concedido como "Permitir o tempo
> todo". O serviço em primeiro plano mantém a notificação persistente visível.

## 4. Proteção contra desinstalação — Device Admin (app da criança)

Impede desinstalar sem antes desativar o administrador (protegido pelo PIN do
aparelho). O ícone continua **visível** — é a forma permitida.

**a.** `apps/crianca/android/app/src/main/res/xml/device_admin.xml`:

```xml
<device-admin xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-policies>
    <force-lock/>
  </uses-policies>
</device-admin>
```

**b.** `apps/crianca/android/app/src/main/kotlin/com/seguranca/crianca/AdminReceiver.kt`:

```kotlin
package com.seguranca.crianca

import android.app.admin.DeviceAdminReceiver

class AdminReceiver : DeviceAdminReceiver()
```

**c.** No `AndroidManifest.xml`, dentro de `<application>`:

```xml
<receiver
    android:name=".AdminReceiver"
    android:permission="android.permission.BIND_DEVICE_ADMIN"
    android:exported="true">
  <meta-data
      android:name="android.app.device_admin"
      android:resource="@xml/device_admin"/>
  <intent-filter>
    <action android:name="android.app.action.DEVICE_ADMIN_ENABLED"/>
  </intent-filter>
</receiver>
```

**d.** No aparelho da criança, ative em: Configurações → Segurança →
Apps de administração do dispositivo → "Segurança dos Filhos".

## 5. Rodar

```bash
cd apps/responsavel && flutter run   # celular do responsável
cd apps/crianca && flutter run       # aparelho da criança
```

## Fluxo de uso

1. No app do responsável: criar conta → "Adicionar" criança → anota o **código**.
2. No aparelho da criança: digita o código → "Ativar monitoramento".
3. Pronto: localização no mapa, sinal sonoro, e escuta online (com indicador).
