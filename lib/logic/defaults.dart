/// Wartości startowe ustawień (przy pierwszym uruchomieniu).
library;

import 'models.dart';
import 'scaling.dart';

/// Cele z prototypu przeskalowane do ~3000 kcal (×1,2). Do poprawienia w aplikacji.
const defaultSettings = Settings(
  target: Macros(kcal: 3000, p: 180, f: 90, c: 366),
  trainingExtraKcal: 250,
  trainingExtraFrom: Macro.c,
);

const defaultMealSlots = [
  MealSlot(name: 'Śniadanie', prep: false),
  MealSlot(name: 'Drugie śniadanie', prep: true),
  MealSlot(name: 'Obiad', prep: true),
  MealSlot(name: 'Przekąska', prep: false),
  MealSlot(name: 'Kolacja', prep: true),
];
