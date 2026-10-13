import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/database/agent_dao.dart';
import '../../data/database/app_database.dart';
import '../../data/database/squad_dao.dart';
import '../../data/network/api_client.dart';
import '../../data/preferences/daily_contract_store.dart';
import '../../data/repository/agent_repository.dart';
import '../../data/repository/daily_contract_repository.dart';
import '../../data/repository/squad_repository.dart';
import '../../ui/state/squad_notifier.dart';

/// Endereço da API (json-server).
/// - Publicada no Render: 'https://super-heroes-api-a979.onrender.com'
/// - Local, no emulador Android: 'http://10.0.2.2:3000'
const String apiBaseUrl = 'https://super-heroes-api-a979.onrender.com';

class ConfigureProviders {
  final List<SingleChildWidget> providers;

  ConfigureProviders({required this.providers});

  static Future<ConfigureProviders> createDependencyTree() async {
    final apiClient = ApiClient(baseUrl: apiBaseUrl);
    final appDatabase = AppDatabase();
    final agentDao = AgentDao(appDatabase);
    final squadDao = SquadDao(appDatabase);

    final agentRepository = AgentRepository(apiClient: apiClient, agentDao: agentDao);

    // Baixa todos os heróis para o banco local. Sem "await": o download
    // roda em segundo plano e a tela inicial abre sem esperar por ele.
    agentRepository.syncAll();
    final squadRepository = SquadRepository(squadDao: squadDao);
    final dailyContractRepository = DailyContractRepository(
      store: DailyContractStore(),
      agentRepository: agentRepository,
      squadRepository: squadRepository,
    );

    return ConfigureProviders(providers: [
      Provider<AgentRepository>.value(value: agentRepository),
      Provider<SquadRepository>.value(value: squadRepository),
      Provider<DailyContractRepository>.value(value: dailyContractRepository),
      // Estado compartilhado do esquadrão. Com "create", o próprio Provider
      // cria o notifier e cuida do dispose. O "..load()" já carrega a lista.
      ChangeNotifierProvider<SquadNotifier>(
        create: (_) => SquadNotifier(squadRepository)..load(),
      ),
    ]);
  }
}
