import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/models/game_item.dart';
import 'package:abomination/models/npc_intent.dart';

void main() {
  final gameState = GameState();
  gameState.initializeNewGame(
    firstName: "Science",
    lastName: "Tester",
    estateName: "Lab Estate",
    deathCause: DeathCause.disease,
    age: 40,
    gilesTrait: GilesTrait.sage,
    objective: LifeObjective.science,
  );

  final ratMeat = GameItem.create(
    name: 'Rat Meat',
    type: 'meat_rat',
    category: ItemCategory.food,
    quantity: 2,
  );

  gameState.addItemToRoom('kitchen', ratMeat);
  gameState.updateResource('potato', 5);
  gameState.updateResource('salt', 5);

  final cookTask = GameTask(
    id: 'cook_stew',
    npcId: gameState.npcs.first.id,
    priority: IntentPriority.normal,
    type: TaskType.cook,
    targetId: 'kitchen',
    recipeId: 'protein_mistery_stew',
    minutesRemaining: 1,
  );

  gameState.completeTaskManually(gameState.npcs.first.id, cookTask);

  final updatedKitchen = gameState.rooms.firstWhere((r) => r.id == 'kitchen');
  print("KITCHEN INVENTORY:");
  for (var item in updatedKitchen.inventory) {
    print("- ${item.type}: ${item.quantity}");
  }
  print("MEALS RESOURCE: ${gameState.resources['meals']}");
}
