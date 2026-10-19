# Configuração (Android)

Passos necessários para o mapa e a localização funcionarem.

## 1. Projeto Firebase

1. Crie um projeto em https://console.firebase.google.com (plano gratuito "Spark").
2. Ative **Authentication**, **Cloud Firestore** e **Cloud Messaging**.
3. Instale a CLI e gere a configuração em cada app:
   ```bash
   dart pub global activate flutterfire_cli
   cd apps/responsavel && flutterfire configure
   cd ../crianca && flutterfire configure
   ```
   Isso baixa o `google-services.json` (está no `.gitignore`, não vai pro Git).
4. Publique as regras de `backend/firestore.rules`.

## 2. Chave do Google Maps (app do responsável)

Gere uma chave em https://console.cloud.google.com (API "Maps SDK for Android")
e adicione em `apps/responsavel/android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
  <application ...>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="SUA_CHAVE_AQUI"/>
  </application>
</manifest>
```

## 3. Permissões (app da criança)

Em `apps/crianca/android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- Exigido pela política de monitoramento do Google Play: marca o app como
     ferramenta de monitoramento, para o Play Protect avisar o usuário. -->
<application ...>
  <meta-data android:name="isMonitoringTool" android:value="true"/>
</application>
```

> O `ACCESS_BACKGROUND_LOCATION` precisa ser concedido manualmente pelo usuário
> em "Permitir o tempo todo". O serviço em primeiro plano mantém a notificação
> persistente visível enquanto coleta a localização.

## 4. Rodar

```bash
cd apps/responsavel && flutter run   # celular do responsável
cd apps/crianca && flutter run       # celular/aparelho da criança
```
