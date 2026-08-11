# Libria — Seu Guia Literário

App Flutter que consome a API pública da [Open Library](https://openlibrary.org/):
busca de livros, detalhes da obra, estante local de favoritos e login com Firebase.

## Como rodar

```bash
cp .env.example .env      # obrigatório: o .env é asset declarado no pubspec
flutter pub get
flutter run
```

O `.env` **não é versionado**. Sem ele, o build falha por asset ausente; com ele
vazio, o app sobe com os valores públicos padrão da Open Library e **sem login**.

### Habilitando o login (Firebase)

1. Crie um projeto no [Console do Firebase](https://console.firebase.google.com/).
2. Em **Authentication > Sign-in method**, habilite *E-mail/senha* e *Google*.
3. Em **Configurações do projeto > Seus aplicativos**, copie as chaves para o `.env`:

```
FIREBASE_API_KEY=...
FIREBASE_APP_ID=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_PROJECT_ID=...
```

Enquanto esses quatro campos estiverem vazios, a autenticação fica desligada e o
app abre direto no acervo — que é público de qualquer forma.

> As chaves entram pelo `.env` em vez do `firebase_options.dart` gerado pelo
> `flutterfire configure` justamente para não versionar credenciais. Ainda assim,
> em Flutter o `.env` viaja como asset dentro do APK/IPA: ele tira segredo do Git,
> mas não protege de quem tem o binário. Credenciais sensíveis de verdade
> pertencem a um backend.

## Arquitetura

Clean Architecture + MVC, com dependências apontando sempre para dentro:

```
presentation  →  domain  ←  data
   (View/Controller)        (Models, Datasources, Repositories)
```

- **domain** — entidades, contratos de repositório e casos de uso. Sem Flutter,
  sem HTTP, sem JSON.
- **data** — models com `fromJson` tolerante, datasources (remoto/local) e as
  implementações dos repositórios. É a fronteira onde `AppException` vira `Failure`.
- **presentation** — controllers (`ChangeNotifier`) expondo `UiState` imutável e
  views que só renderizam o estado.
- **core** — contratos e utilitários transversais: HTTP client, erros, `Result`,
  tema, responsividade, DI e configuração.

```
lib/
├── core/
│   ├── config/          AppConfig (.env), FirebaseEnv
│   ├── constants/       endpoints da Open Library
│   ├── di/              service locator (get_it)
│   ├── error/           exceptions, failures, Result<T>
│   ├── network/         IHttpClient + implementação
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
- **Busca com debounce + descarte de respostas obsoletas**: uma requisição lenta
  não sobrescreve um resultado mais novo.
- **Null Object para autenticação**: sem Firebase configurado, a DI resolve uma
  fonte desabilitada em vez de espalhar `if (temFirebase)` pelas telas.

## Testes

```bash
flutter test
flutter analyze
```

Cobrem os pontos onde o erro dói: parsing tolerante dos models, debounce e race
de respostas na busca, paginação com duplicatas, rollback da remoção na estante e
validação/erros do login.

## API

| Recurso  | Endpoint                                        |
| -------- | ----------------------------------------------- |
| Busca    | `GET /search.json?q=&fields=&limit=&page=`      |
| Obra     | `GET /works/{id}.json`                          |
| Capas    | `https://covers.openlibrary.org/b/id/{id}-L.jpg`|

A busca pede só os campos usados (`fields=...`), o que reduz bastante o payload.
