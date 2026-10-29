# Segurança dos Filhos

App de **controle parental transparente** — dois aplicativos (um para o responsável, outro para o
aparelho da criança) e um backend em Firebase, feito para famílias com crianças pequenas.

> **Princípio do projeto:** monitoramento **com transparência e consentimento**. O aparelho
> monitorado deixa claro que está sendo acompanhado (ícone visível + notificação persistente).
> É o que diferencia controle parental de *stalkerware* — e o que mantém o app dentro das regras
> das lojas e da lei.

## Estrutura

```
seguranca-dos-filhos/
├── apps/
│   ├── responsavel/   # App do pai/mãe: mapa, escuta, sinal sonoro, contatos
│   └── crianca/       # App do aparelho da criança: coleta e responde (com aviso visível)
├── packages/
│   └── shared/        # Modelos e serviços compartilhados (Dart)
└── backend/
    └── functions/     # Cloud Functions + regras do Firestore
```

Stack: **Flutter** (um código para os dois apps) + **Firebase** (Auth, Firestore em tempo real,
Cloud Messaging, Storage).

## Funcionalidades

| Recurso | Status | Observação |
|---|---|---|
| 🔐 Login (responsável) | ✅ pronto | e-mail/senha (Firebase Auth) |
| 🔗 Pareamento do aparelho | ✅ pronto | código de 6 dígitos gerado no app do responsável |
| 📍 Localização em tempo real | ✅ pronto | GPS enviado via serviço em primeiro plano |
| 🗺️ Movimentação / histórico | ✅ pronto | trilha dos deslocamentos no mapa |
| 🔊 Escuta online | ✅ pronto | **ao vivo (WebRTC)**, **com indicador de microfone do Android visível** |
| 🔔 Sinal sonoro | ✅ pronto | toca alarme para localizar o aparelho |
| 🛡️ Proteção contra desinstalação | ✅ pronto | Device Admin, **ícone visível** (ver CONFIGURACAO.md) |

## Fora do escopo (intencionalmente)

Para manter o app publicável e dentro da lei, **não** implementa:

- Escuta de ambiente oculta (sem indicador de microfone).
- Interceptação/leitura de mensagens privadas de terceiros (WhatsApp etc.) via acessibilidade.
- App oculto / sem ícone / indetectável.

Essas capacidades são as de *stalkerware*: funcionam igual contra qualquer adulto, violam as
políticas do Google Play e do WhatsApp, e são crime em muitos lugares. Para ler o WhatsApp de uma
criança pequena cujo aparelho você controla, use o recurso **Aparelhos conectados** do próprio
WhatsApp (conecta a conta dela ao seu celular).

## Compilar pelo GitHub (sem computador)

O GitHub Actions compila os dois APKs na nuvem a cada push (workflow
`.github/workflows/build-apks.yml`).

**Baixar os APKs:** repositório → aba **Actions** → clique na execução mais
recente (verde) → seção **Artifacts** → baixe `apk-responsavel` e `apk-crianca`.

**Para os apps funcionarem de verdade** (login, localização, escuta), adicione
em Settings → Secrets and variables → Actions:

| Secret | Conteúdo |
|---|---|
| `GOOGLE_SERVICES_RESPONSAVEL` | o `google-services.json` do app responsável, em base64 |
| `GOOGLE_SERVICES_CRIANCA` | o `google-services.json` do app criança, em base64 |
| `MAPS_API_KEY` | a chave do Google Maps |

Sem esses secrets, o build usa uma configuração **provisória**: os APKs
instalam e abrem, mas não conectam ao Firebase.

## Começando (no seu computador, alternativa)

Pré-requisitos: Flutter SDK, conta Firebase, FlutterFire CLI.

O passo a passo completo (gerar as pastas Android, configurar o Firebase, chave do Maps,
permissões, regras e a proteção contra desinstalação) está em **[CONFIGURACAO.md](CONFIGURACAO.md)**.

Resumo:

```bash
# 1. gerar as pastas de plataforma
cd apps/responsavel && flutter create --platforms=android --org com.seguranca .
cd ../crianca && flutter create --platforms=android --org com.seguranca .

# 2. configurar Firebase em cada app (gera google-services.json)
flutterfire configure

# 3. rodar
cd apps/responsavel && flutter run   # celular do responsável
cd apps/crianca && flutter run       # aparelho da criança
```

### Fluxo de uso
1. App do responsável: criar conta → **Adicionar** criança → anotar o **código**.
2. Aparelho da criança: digitar o código → **Ativar monitoramento**.
3. Mapa, sinal sonoro e escuta online (com indicador de microfone) funcionando.
