#!/usr/bin/env python3
"""Escreve android/app/google-services.json.

Uso:
  python3 tool/google_services.py <app_dir> <package_name> [base64_opcional]

Se o conteúdo em base64 for passado (segredo do GitHub com o arquivo real do
Firebase), ele é usado. Caso contrário, grava um arquivo PROVISÓRIO só para a
compilação passar — o app compila, mas só conecta no Firebase de verdade depois
que você colocar o arquivo real.
"""
import base64
import json
import os
import sys

PLACEHOLDER = {
    "project_info": {
        "project_number": "000000000000",
        "project_id": "placeholder-seguranca",
        "storage_bucket": "placeholder-seguranca.appspot.com",
    },
    "client": [
        {
            "client_info": {
                "mobilesdk_app_id":
                    "1:000000000000:android:0000000000000000000000",
                "android_client_info": {"package_name": "__PKG__"},
            },
            "oauth_client": [],
            "api_key": [
                {"current_key": "AIzaSyPLACEHOLDER0000000000000000000000000"}
            ],
            "services": {
                "appinvite_service": {"other_platform_oauth_client": []}
            },
        }
    ],
    "configuration_version": "1",
}


def main():
    app_dir, pacote = sys.argv[1], sys.argv[2]
    b64 = sys.argv[3] if len(sys.argv) > 3 else ""
    destino = os.path.join(app_dir, "android/app/google-services.json")

    if b64.strip():
        conteudo = base64.b64decode(b64).decode("utf-8")
        print(f"google-services.json REAL gravado em {destino}")
    else:
        dados = json.loads(json.dumps(PLACEHOLDER))
        dados["client"][0]["client_info"]["android_client_info"][
            "package_name"] = pacote
        conteudo = json.dumps(dados, indent=2)
        print(f"google-services.json PROVISÓRIO gravado em {destino} "
              f"(pacote {pacote})")

    with open(destino, "w", encoding="utf-8") as f:
        f.write(conteudo)


if __name__ == "__main__":
    main()
