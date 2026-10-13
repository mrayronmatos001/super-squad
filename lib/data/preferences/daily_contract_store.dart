import 'package:shared_preferences/shared_preferences.dart';

/// Guarda a data do último sorteio e o id do herói convocado no dia,
/// usando shared_preferences (chave e valor, persistente no aparelho).
class DailyContractStore {
  static const _dateKey = 'daily_contract_date';
  static const _agentIdKey = 'daily_contract_agent_id';

  /// Devolve o id do herói sorteado em [day], ou null se o último sorteio
  /// foi em outro dia (ou se nunca houve sorteio).
  Future<int?> getAgentIdFor(String day) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_dateKey) != day) return null;
    return prefs.getInt(_agentIdKey);
  }

  Future<void> save({required String day, required int agentId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, day);
    await prefs.setInt(_agentIdKey, agentId);
  }
}

/// Data de hoje no formato "2026-10-12". Comparar só a data (sem hora)
/// garante que o sorteio muda exatamente na virada do dia.
String todayKey([DateTime? now]) {
  final date = now ?? DateTime.now();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
