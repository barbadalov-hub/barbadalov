import 'models.dart';

/// The seven memory fragments (see missed_call/docs/design.md). Collecting all
/// of them is the path to the true ending, «Голосовое».
const List<MemoryFragment> kFragments = <MemoryFragment>[
  MemoryFragment(
    id: 'mirror',
    title: 'Зеркало',
    clock: '03:19',
    cost: 12,
    brief: 'В отражении — ты. Взгляд чужой. Это твой дом, твой телефон.',
  ),
  MemoryFragment(
    id: 'clothes',
    title: 'Мокрая одежда',
    clock: '03:24',
    cost: 12,
    brief: 'Куртка на стуле тёмная от влаги. Ты выходил ночью. Куда?',
  ),
  MemoryFragment(
    id: 'photo',
    title: 'Чужой телефон',
    clock: '03:29',
    cost: 12,
    brief: 'На столе — второй телефон, Артёма. На экране — фото того двора.',
  ),
  MemoryFragment(
    id: 'calls',
    title: 'Три пропущенных',
    clock: '03:34',
    cost: 14,
    brief: '23:14, 23:19, 23:31. Все — тебе. Он звонил тебе последним.',
  ),
  MemoryFragment(
    id: 'quarrel',
    title: 'Ссора',
    clock: '03:38',
    cost: 12,
    brief: 'Кухня, смех — и вдруг резкие слова. Хлопнувшая дверь.',
  ),
  MemoryFragment(
    id: 'ice',
    title: 'Двор. Лёд.',
    clock: '03:42',
    cost: 14,
    brief: 'Тонкий лёд, темнота, один неверный шаг. И никого рядом.',
  ),
  MemoryFragment(
    id: 'voice',
    title: 'Голосовое',
    clock: '03:46',
    cost: 14,
    brief: 'Он записал его для тебя. «Это не твоя вина. Слышишь? Живи.»',
  ),
];
