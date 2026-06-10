import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:abomination/services/combat_manager.dart';
import 'package:abomination/services/combat_unit_factory.dart';

void main() {
  test('Artillery Barrage Lifecycle simulation', () {
    final manager = CombatManager();
    manager.startCombat();

    // 1. Spawn Alphonse (player character)
    final alphonse = CombatUnitFactory.createAlphonse();
    final spawnedAlphonse = manager.spawnUnit(alphonse, CombatSide.player, x: 50.0, y: 42.5);
    debugPrint('Alphonse spawn: $spawnedAlphonse');

    final barrage = CombatUnitFactory.createArtilleryBarrage();
    debugPrint('Barrage initial stats: unitType=${barrage.combatStats?.unitType}, deploymentTime=${barrage.combatStats?.deploymentTime}');

    final spawned = manager.spawnUnit(barrage, CombatSide.player, x: 50.0, y: 42.5);
    debugPrint('Spawn successful: $spawned');

    final combatant = manager.combatants.firstWhere((c) => c.npc.name.contains('Barrage'));
    debugPrint('Spawned Combatant: name=${combatant.npc.name}, activeDeploymentTimer=${combatant.activeDeploymentTimer}, supportDurationRemaining=${combatant.supportDurationRemaining}');

    // Let's tick 0.5s at a time for 7 seconds.
    for (int i = 1; i <= 14; i++) {
      manager.update(0.5);
      final list = manager.combatants.where((c) => c.npc.name.contains('Barrage')).toList();
      if (list.isEmpty) {
        debugPrint('Tick $i (Time elapsed: ${i * 0.5}s): Barrage unit is dead/vanished!');
      } else {
        final c = list.first;
        debugPrint('Tick $i (Time elapsed: ${i * 0.5}s): activeDeploymentTimer=${c.activeDeploymentTimer}, supportDurationRemaining=${c.supportDurationRemaining}, isDead=${c.isDead}');
      }
    }
  });
}
