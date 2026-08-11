# Libria — Seu Guia Literário

App Flutter que consome a API pública da [Open Library](https://openlibrary.org/):
busca de livros, ficha completa da obra, estante pessoal e login com Firebase.

A Open Library mantém o registro aberto de milhões de obras, mas a interface é de
um arquivo, não de uma estante. O Libria é a camada de leitura em cima disso.

| | |
| --- | --- |
| **Plataformas** | Web, Android, iOS, Windows |
| **Arquitetura** | Clean Architecture + MVC |
| **Testes** | 31, em 6 arquivos |
| **Código** | 64 arquivos Dart em `lib/` |

---

## Requisitos

**Flutter 3.44.9 ou superior.** O `pubspec.yaml` exige `sdk: ^3.12.2`, e um Flutter
mais antigo falha já no `pub get`, sem nem chegar a compilar:

```
Because libria requires SDK version ^3.12.2, version solving failed.
```

Confira e atualize com:

```bash
flutter --version     # precisa reportar Dart 3.12.2+
flutter upgrade
```

Para rodar na web você também precisa do Chrome instalado — `flutter doctor` deve
mostrar `[√] Chrome - develop for the web`.

---

## Rodando

```bash
cp .env.example .env      # obrigatório: o .env é asset declarado no pubspec
flutter pub get
flutter run -d chrome     # ou: -d android, -d windows
```

O `.env` **não é versionado**. Sem o arquivo o build falha por asset ausente; com
ele vazio o app sobe com os valores públicos padrão da Open Library e **sem login**
— que é o estado normal para desenvolver, porque o acervo é público.

### Ver o build de produção

O `flutter run -d web-server` em modo debug prende o bootstrap ao primeiro cliente
que conectar; recarregar numa segunda aba trava esperando o canvas. Para inspecionar
o app fora do fluxo de desenvolvimento, use o build de release:

```bash
flutter build web --release
# sirva a pasta build/web com qualquer servidor estático
```

---

## Habilitando o login (Firebase)

O login é **opcional por decisão de projeto**. Sem as chaves configuradas o app
abre direto na busca em vez de travar numa tela de login inútil.

### 1. Criar o projeto e registrar o app

No [Console do Firebase](https://console.firebase.google.com/):

1. Crie um projeto
2. **⚙️ Configurações do projeto** → aba **Geral** → seção **Seus aplicativos**
3. Clique no ícone da plataforma que você vai usar (`</>` para web, ou Android/iOS)
4. Para web: apelido `Libria Web`, **sem** Firebase Hosting

### 2. Copiar as chaves para o `.env`

O console mostra um bloco `firebaseConfig`. O mapeamento é:

| No console | No `.env` | Obrigatório |
| --- | --- | --- |
| `apiKey` | `FIREBASE_API_KEY` | **sim** |
| `appId` | `FIREBASE_APP_ID` | **sim** |
| `messagingSenderId` | `FIREBASE_MESSAGING_SENDER_ID` | **sim** |
| `projectId` | `FIREBASE_PROJECT_ID` | **sim** |
| `authDomain` | `FIREBASE_AUTH_DOMAIN` | sim, na web |
| `storageBucket` | `FIREBASE_STORAGE_BUCKET` | não |

Enquanto os quatro primeiros estiverem vazios, `FirebaseEnv.isConfigured` é `false`,
o app registra um Null Object para autenticação e segue funcionando sem login. O
console de debug diz exatamente o que faltou:

```
[Libria] Firebase desativado: faltam FIREBASE_API_KEY, ... no .env.
```

### 3. Habilitar os provedores

**Authentication → Sign-in method** → ativar **E-mail/senha** e **Google**. O
provedor Google pede um e-mail de suporte do projeto.

Em **Authentication → Settings → Authorized domains**, confirme que `localhost`
está na lista — é o que libera o popup de login rodando local.

### Uma plataforma por `.env`

O Firebase emite um **`appId` diferente para cada plataforma**, e normalmente uma
`apiKey` diferente também. O `FirebaseEnv` guarda um único conjunto de chaves, então
o `.env` serve **uma plataforma de cada vez**: preencher com as chaves de web e rodar
no Android entrega ao `initializeApp` um `appId` que não é o do Android.

Para suportar web e Android ao mesmo tempo, o caminho é chaves por plataforma
(`FIREBASE_WEB_APP_ID`, `FIREBASE_ANDROID_APP_ID`, …) com o bootstrap escolhendo por
`kIsWeb`/`defaultTargetPlatform`. Ainda não implementado.

### Login com Google no Android exige SHA-1

O fluxo usa `signInWithProvider`, que dispensa o pacote `google_sign_in` mas exige
que a impressão digital do certificado esteja cadastrada no console. Sem ela, o
login por e-mail funciona e o Google falha.

```bash
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore -storepass android -keypass android
```

Cadastre o `SHA1` em **Configurações do projeto → Seus aplicativos → (app Android)
→ Adicionar impressão digital**. O keystore de **release** tem outro SHA-1 e precisa
ser cadastrado à parte, senão o login Google funciona em debug e quebra em produção.

### Por que não existe `firebase_options.dart`

O `flutterfire configure` gera esse arquivo com as chaves dentro, e ele iria para o
Git. Aqui as chaves entram pelo `.env`, que é ignorado.

Vale ser honesto sobre o alcance disso: em Flutter o `.env` viaja **como asset dentro
do APK/IPA**. Ele tira credencial do controle de versão e permite trocar de ambiente
sem recompilar, mas não protege segredo de quem tem o binário. As chaves do Firebase,
aliás, são identificadores públicos por design — quem protege a conta são as regras
de acesso. Segredo de verdade pertence a um backend intermediário.

### Nome do pacote

O `applicationId` é `com.example.libria`. **O Google Play rejeita `com.example.*`.**
Trocar antes de registrar no Firebase custa uma edição em quatro arquivos; trocar
depois exige registrar um app novo, com novo `appId` e novo SHA-1.

---

## Landing page

Página de apresentação em HTML + Tailwind, separada do app, em [`landing/`](landing/).
Identidade de ficha de catálogo de biblioteca: papel manilha, número de chamada
datilografado e carimbo em tinta violeta.

Abre direto no navegador depois do clone — o CSS compilado é versionado de propósito:

```bash
open landing/index.html      # ou duplo clique
```

Para mexer no estilo:

```bash
cd landing
npm install
npx @tailwindcss/cli -i src/input.css -o dist/style.css --watch
```

Os tokens de cor e tipografia vivem no bloco `@theme` de
[`landing/src/input.css`](landing/src/input.css). O tema escuro redefine só os tokens,
nos três estados possíveis: sem marcação (`prefers-color-scheme`), `data-theme="dark"`
e `data-theme="light"` vencendo um sistema escuro.

> O Tailwind vale **apenas** para a landing. O app Flutter não usa CSS — o tema dele
> é Dart, em [`lib/core/theme/app_theme.dart`](lib/core/theme/app_theme.dart).

---

## Arquitetura

Clean Architecture + MVC, com as dependências apontando sempre para dentro:

```
presentation  →  domain  ←  data
   (View/Controller)        (Models, Datasources, Repositories)
```

- **domain** — entidades, contratos de repositório e casos de uso. Sem Flutter, sem
  HTTP, sem JSON.
- **data** — models com `fromJson` tolerante, datasources (remoto/local) e as
  implementações dos repositórios. É a fronteira onde `AppException` vira `Failure`.
- **presentation** — controllers (`ChangeNotifier`) expondo `UiState` imutável e
  views que só renderizam estado.
- **core** — contratos e utilitários transversais.

```
lib/
├── core/
│   ├── config/          AppConfig (.env), FirebaseEnv
│   ├── constants/       endpoints da Open Library
│   ├── di/              service locator (get_it)
│   ├── error/           exceptions, failures, Result<T>
│   ├── network/         IHttpClient + implementação
│   ├── session/         ISessionScope — dono dos dados locais
│   ├── state/           UiState<T> selado
│   ├── theme/           Material 3 + tokens
│   ├── usecases/        contrato UseCase<T, P>
│   └── utils/           Debouncer, Responsive
├── features/
│   ├── auth/            data · domain · presentation
│   └── book/            data · domain · presentation
└── main.dart            composition root
```

### Decisões que valem nota

- **`Result<T>` (Ok/Err)** em vez de exceções atravessando camadas: o contrato do
  repositório declara que pode falhar, e o compilador cobra o tratamento.
- **`UiState<T>` selado**: o `switch` na View é verificado pelo compilador — não
  existe estado de tela esquecido (carregando, vazio, erro, sucesso).
- **Grid responsivo por largura real** (`SliverLayoutBuilder`), não por breakpoint
  fixo; a altura do card considera a escala de fonte do sistema.
- **Busca com debounce + descarte de respostas obsoletas**: uma requisição lenta não
  sobrescreve um resultado mais novo.
- **Null Object para autenticação**: sem Firebase configurado, a DI resolve uma fonte
  desabilitada em vez de espalhar `if (temFirebase)` pelas telas.
- **Estante por conta**: a chave do armazenamento local deriva do uid via
  `ISessionScope`, então num aparelho compartilhado a estante de quem sai não fica
  visível para quem entra. A estante criada antes do primeiro login é transferida
  para a primeira conta que entrar — movendo, não copiando, para a segunda conta não
  herdar os livros de quem usou o app antes.

---

## Testes

```bash
flutter test
flutter analyze
```

31 testes cobrindo os pontos onde o erro dói:

| Arquivo | O que garante |
| --- | --- |
| `app_config_test.dart` | fallback do `.env`, headers, HTTP Basic |
| `book_model_test.dart` | parsing tolerante, round-trip da persistência |
| `home_controller_test.dart` | debounce, resposta obsoleta, paginação sem duplicatas |
| `favorites_controller_test.dart` | rollback da remoção otimista |
| `book_local_datasource_test.dart` | isolamento da estante entre contas |
| `login_controller_test.dart` | validação de credenciais e mensagens de erro |

---

## API

| Recurso | Endpoint |
| --- | --- |
| Busca | `GET /search.json?q=&fields=&limit=&page=` |
| Obra | `GET /works/{id}.json` |
| Capas | `https://covers.openlibrary.org/b/id/{id}-L.jpg` |

A busca pede só os campos usados (`fields=...`), o que reduz bastante o payload. O
`User-Agent` leva um e-mail de contato, conforme as boas práticas de uso da API —
configure o seu em `OPENLIBRARY_CONTACT_EMAIL`.

---

## Armadilhas conhecidas

**Os arquivos em `windows/flutter/` aparecem como modificados sem mudança nenhuma.**
São gerados a cada `flutter pub get`, e o Flutter os grava com fim de linha LF
enquanto o Git no Windows espera CRLF. O conteúdo é idêntico — `git diff` sai vazio.
Para limpar a marcação:

```bash
git add --renormalize windows/
```

**`flutter run -d web-server` trava na segunda aba.** Em modo debug o servidor
vincula o bootstrap ao primeiro cliente. Use `flutter build web --release` com um
servidor estático quando precisar abrir mais de uma sessão.

**Login Google funciona em debug e falha em release no Android.** Falta cadastrar o
SHA-1 do keystore de release no console.

**`flutter run -d windows` falha por falta do Windows 10 SDK.** Instale-o pelo Visual
Studio Installer, ou use outra plataforma.
