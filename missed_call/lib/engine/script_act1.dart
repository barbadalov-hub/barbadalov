import 'models.dart';

/// Id of the first node of Act I.
const String kActOneStart = 'ring';

/// Act I — the prologue, as a data-driven scene graph.
///
/// Wake at 03:14 → first contact with «М.» → a branching first choice → a warm
/// memory insert → end of the vertical slice. Writing lives here as data so an
/// artist fills CGs and a writer edits lines without touching engine code
/// (the same "single source of truth" idea as LifeOS's `kTodaySections`).
final Map<String, VnNode> actOneScript = <String, VnNode>{
  'ring': const VnNode(
    id: 'ring',
    cg: CgSpec(
      id: 'cg01_ring',
      mood: Mood.night,
      brief:
          'Почти чёрный кадр. Единственный свет — прожжённое пятно экрана '
          'телефона на тумбе. Силуэт спящего со спины, холодный лунный кант.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration, 'Ты не сразу понимаешь, что это твой телефон.'),
      VnLine(Speaker.narration,
          'Он звонит уже давно — экран прожёг в темноте бледное пятно, и оно '
          'пульсирует, как чужое сердце.'),
    ],
    next: 'wake',
  ),
  'wake': const VnNode(
    id: 'wake',
    cg: CgSpec(
      id: 'cg02_wake',
      mood: Mood.night,
      brief:
          'Он садится в кровати. Слева окно с луной (холодный кант на лице), '
          'справа тёплое пятно лампы. Двойной аниме-контровой. Взгляд в пустоту.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration,
          'Ты садишься. В окне — луна и чужой синий свет. Голова тяжёлая, будто '
          'ты не спал, а куда-то проваливался и еле выбрался обратно.'),
      VnLine(Speaker.thought, '…сколько я так лежал?'),
    ],
    next: 'clock',
  ),
  'clock': const VnNode(
    id: 'clock',
    cg: CgSpec(
      id: 'cg03_clock',
      mood: Mood.night,
      brief:
          'Макро на электронные часы, красные цифры в боке. На переднем плане '
          'размытая тянущаяся рука. Красный свет ложится на пальцы.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration,
          'Часы горят красным. 03:14. Ты не помнишь, чтобы ложился.'),
      VnLine(Speaker.narration, 'Телефон вздрагивает снова. Не звонок — сообщение.'),
    ],
    next: 'message',
  ),
  'message': const VnNode(
    id: 'message',
    cg: CgSpec(
      id: 'cg04_message',
      mood: Mood.night,
      brief:
          'Экран телефона заполняет кадр, холодное свечение снизу подсвечивает '
          'пол-лица героя — видны только глаза. В глазах отражаются строки.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.mira, 'Ты не спишь? Мне больше некому написать.'),
      VnLine(Speaker.mira,
          'Я в квартире Артёма. Дверь была открыта. Его нет, а телефон лежит на '
          'столе — не выключен.'),
      VnLine(Speaker.thought, 'Почему её номер сохранён без имени? Просто «М.»…'),
    ],
    choices: <VnChoice>[
      VnChoice(
          label: 'Где ты? Опиши, что видишь вокруг.',
          goto: 'branch_where',
          tag: 'расследование'),
      VnChoice(
          label: 'Успокойся. Я сам сейчас ему позвоню.',
          goto: 'branch_call',
          tag: 'действие'),
      VnChoice(
          label: 'Кто ты вообще? Откуда у тебя мой номер?',
          goto: 'branch_who',
          tag: 'доверие −'),
    ],
  ),
  'branch_where': const VnNode(
    id: 'branch_where',
    cg: CgSpec(
      id: 'cg04_message',
      mood: Mood.night,
      brief: 'Тот же кадр телефона; в чат приходят новые строки.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.mira, 'Кухня. Свет горит, чайник ещё тёплый.'),
      VnLine(Speaker.mira, 'У него открыт чат… и это переписка не со мной.'),
    ],
    next: 'memory',
  ),
  'branch_call': const VnNode(
    id: 'branch_call',
    cg: CgSpec(
      id: 'cg04_message',
      mood: Mood.dread,
      brief: 'Палитра холодеет в тревогу: что-то не так с самой идеей позвонить.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.mira, 'Не надо. Пожалуйста, не звони ему.'),
      VnLine(Speaker.mira, 'Просто… доверься мне ещё пару минут.'),
    ],
    next: 'memory',
  ),
  'branch_who': const VnNode(
    id: 'branch_who',
    cg: CgSpec(
      id: 'cg04_message',
      mood: Mood.dread,
      brief: 'Пауза в переписке затягивается. «печатает…» гаснет и появляется снова.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.mira, 'Ты правда не помнишь?'),
      VnLine(Speaker.mira, '…Тогда не спрашивай меня. Смотри вокруг.'),
    ],
    next: 'memory',
  ),
  'memory': const VnNode(
    id: 'memory',
    cg: CgSpec(
      id: 'cg05_memory',
      mood: Mood.memory,
      brief:
          'Резкая смена на тёплый янтарь. Заснеженный двор детства, двое '
          'мальчишек смеются, снег в свете фонаря как боке. Flashback-фильтр.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration,
          'На секунду — не эта ночь. Двор, снег, фонарь. Вы оба смеётесь, и '
          'кто-то из вас младше на целую жизнь.'),
      VnLine(Speaker.narration,
          'Потом гаснет. Синий свет телефона возвращается.'),
      VnLine(Speaker.thought, 'Почему я вспомнил именно это?'),
    ],
    next: 'slice_end',
  ),
  'slice_end': const VnNode(
    id: 'slice_end',
    cg: CgSpec(
      id: 'cg01_ring',
      mood: Mood.night,
      brief: 'Возврат в холод. Экран телефона — единственный свет.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration, '— конец вертикального среза Акта I —'),
      VnLine(Speaker.thought,
          'Дальше — таймер ночи, воспоминания и 14 путей, по которым может '
          'закончиться этот разговор.'),
    ],
    choices: <VnChoice>[
      VnChoice(label: 'Прожить ночь заново', goto: 'ring', tag: 'петля'),
    ],
  ),
};
