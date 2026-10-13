# Super Squad

Jogo de esquadrão de heróis feito para o Trabalho 1 de Desenvolvimento para Dispositivos Móveis (UFRN). Consome a API de super-heróis servida pelo json-server.

## Como rodar

1. Crie um projeto Flutter novo com o mesmo nome do pacote (isso gera as pastas `android/`, `ios/` etc. já configuradas):

   ```
   flutter create super_squad
   ```

2. Copie para dentro dele, substituindo o que existir: a pasta `lib/`, a pasta `assets/`, o `pubspec.yaml` e o `analysis_options.yaml`. Apague a pasta `test/` gerada (o teste padrão do Flutter não existe neste app).

3. Instale as dependências:

   ```
   flutter pub get
   ```

4. Confira o endereço da API em `lib/core/di/configure_providers.dart` (`apiBaseUrl`). Está configurado para o Render; para usar o json-server local no emulador, troque por `http://10.0.2.2:3000`.

5. Rode no emulador ou no celular:

   ```
   flutter run
   ```

Para gerar um APK de release, adicione `<uses-permission android:name="android.permission.INTERNET"/>` no `android/app/src/main/AndroidManifest.xml` (as builds de debug já têm essa permissão).

## Estrutura

```
lib/
  main.dart                     ponto de entrada
  core/di/                      injeção de dependências (Provider)
  core/theme/                   cores e tipografia
  domain/                       modelos (Agent, StatType, MissionRound) e exceções
  data/network/                 ApiClient (Dio) e resposta paginada
  data/database/                SQLite: cache do catálogo e tabela do esquadrão
  data/preferences/             shared_preferences: data e id do contrato diário
  data/repository/              regras de negócio (offline-first, limite de 15, sorteio diário)
  ui/state/                     ChangeNotifiers: esquadrão (global), contrato diário e missão
  ui/pages/                     telas
  ui/widgets/                   componentes reutilizáveis
```

## Onde cada requisito está

| Requisito | Arquivo |
|---|---|
| Lista com PagedListView (infinite_scroll_pagination) | `ui/pages/agents_page.dart` |
| Download do catálogo completo ao abrir o app | `data/repository/agent_repository.dart` (`syncAll`), chamado em `core/di/configure_providers.dart` |
| Cache no SQLite e leitura offline | `data/repository/agent_repository.dart`, `data/database/agent_dao.dart` |
| Imagens com cached_network_image | `ui/widgets/common.dart` (`AgentImage`) |
| Barras de powerstats com primer_progress_bar | `ui/widgets/agent_widgets.dart` (`PowerStatBars`) |
| Sorteio 1x por dia com shared_preferences | `data/repository/daily_contract_repository.dart`, `data/preferences/daily_contract_store.dart` |
| Limite de 15 agentes | `data/repository/squad_repository.dart` |
| Dispensar com confirmação (awesome_dialog) | `ui/pages/my_agent_details_page.dart` |
| Missão: mínimo de 5 agentes, 3 a 5 rounds, grid 3x5, agente uma vez por missão | `ui/pages/mission_page.dart` |
| Feedback final com awesome_dialog e +1 em powerstat | `ui/pages/mission_page.dart` (`_finishMission`) |

## Gerenciamento de estado

O Provider tem dois papéis no app. Ele entrega os repositórios para as telas (injeção de dependências, como no projeto base) e também gerencia o estado com `ChangeNotifier`, sem `setState`:

- `SquadNotifier` é global, registrado no `configure_providers.dart`. Qualquer tela que use `Provider.of<SquadNotifier>(context)` (listen padrão, `true`) se atualiza sozinha quando um agente é recrutado, dispensado ou ganha bônus.
- `DailyContractNotifier` e `MissionNotifier` pertencem a uma tela cada. São criados com `ChangeNotifierProvider` dentro da própria página e descartados quando ela fecha.
- A lista do catálogo usa o `PagingController`, que já é um notifier; o aviso de offline usa um `ValueNotifier`; as telas de detalhes usam `FutureBuilder` para a consulta à API.

A fonte Chakra Petch (títulos) está em `assets/fonts/` sob a licença SIL Open Font License (`OFL.txt`).
