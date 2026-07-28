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
    anchor: 'A', // checkpoint: after this, a death loop skips the wake montage.
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
      VnChoice(
          label: 'Отложить телефон и не отвечать.',
          goto: 'ending_leave',
          tag: 'уйти'),
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
      VnLine(Speaker.thought,
          'Рядом — его телефон. Иконка пропущенных вызовов мигает красным.'),
    ],
    choices: <VnChoice>[
      VnChoice(
          label: 'Прочитать сообщения и осмотреться.',
          goto: 'memory',
          tag: 'расследование'),
      VnChoice(
          label: 'Открыть историю звонков.',
          goto: 'ending_guilt',
          tag: 'правда'),
    ],
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
    choices: <VnChoice>[
      VnChoice(label: 'Хорошо. Пару минут.', goto: 'memory', tag: 'доверие +'),
      VnChoice(
          label: 'Я всё равно наберу его номер.',
          goto: 'death_line',
          tag: 'тупик'),
    ],
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
    choices: <VnChoice>[
      VnChoice(label: 'Ладно… осмотрюсь.', goto: 'memory', tag: 'расследование'),
      VnChoice(
          label: 'Хватит игр. Отвечай, кто ты!',
          goto: 'death_paralysis',
          tag: 'тупик'),
    ],
  ),
  // --- Horror dead-ends: playing them out loops the night back to 03:14. ---
  'death_paralysis': const VnNode(
    id: 'death_paralysis',
    isDeath: true,
    cg: CgSpec(
      id: 'death_sleep',
      mood: Mood.dread,
      brief:
          'Сонный паралич. Почти чёрный кадр, туннельная виньетка. У изножья '
          'сгущается силуэт; матрас проминается — оно забирается на кровать.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration,
          'Ты моргнул — и глаза открылись не там. Ты снова в кровати, но не '
          'можешь пошевелиться.'),
      VnLine(Speaker.narration,
          'Телефон звонит. Рука не слушается. Матрас проминается у изножья — '
          'оно забирается на кровать.'),
      VnLine(Speaker.mira,
          'Не надо было спрашивать. Некоторые двери держат закрытыми не просто так.'),
      VnLine(Speaker.narration,
          'Оно садится тебе на грудь и наклоняется к лицу. Это твоё лицо. Пустое.'),
    ],
  ),
  'death_line': const VnNode(
    id: 'death_line',
    isDeath: true,
    cg: CgSpec(
      id: 'death_caller',
      mood: Mood.dread,
      brief:
          'Экран телефона крупно, гаснет сам. В чёрном стекле — твоё отражение, '
          'улыбающееся не в такт.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration,
          'Гудок. Ещё. На третьем — снимают. Но это не голос: дыхание, помехи, '
          'ветер как из трубы.'),
      VnLine(Speaker.narration,
          'Оно произносит твоё имя — правильно, с маминым ударением. Экран '
          'гаснет сам.'),
      VnLine(Speaker.narration,
          'В чёрном зеркале стекла — твоё отражение. Оно улыбается не в такт.'),
      VnLine(Speaker.mira, 'ты звал. я пришёл. теперь я не уйду.'),
    ],
  ),
  // Time-up death — triggered by the night timer, not a choice (see controller).
  'death_time': const VnNode(
    id: 'death_time',
    isDeath: true,
    cg: CgSpec(
      id: 'death_time',
      mood: Mood.dread,
      brief:
          'Комната растворяется по краям, как недогруженная картинка. Трещина '
          'бежит по экрану телефона и по отражению.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration, 'Часы на тумбе щёлкают: 03:46… 03:47.'),
      VnLine(Speaker.narration,
          'На телефоне вспыхивает «Прочитано 03:47». Больше М. не отвечает. '
          'Никогда.'),
      VnLine(Speaker.narration,
          'Комната растворяется по краям. Трещина бежит по экрану, по зеркалу, '
          'по твоему лицу — и рывком тебя выбрасывает обратно.'),
    ],
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
    next: 'memory_hub',
  ),
  'memory_hub': const VnNode(
    id: 'memory_hub',
    isMemoryHub: true,
    anchor: 'B', // deeper checkpoint: resume straight into the memory phase.
    cg: CgSpec(
      id: 'memory_hub',
      mood: Mood.memory,
      brief: 'Твоя память — тёмная комната. Что-то в ней ещё можно разглядеть.',
    ),
    next: 'slice_end',
  ),
  // --- Endings (see docs/story.md for the full map of 14). ---
  'ending_guilt': const VnNode(
    id: 'ending_guilt',
    endsNight: true,
    cg: CgSpec(
      id: 'ending_guilt',
      mood: Mood.dread,
      brief: 'История звонков крупным планом. Три строки «пропущенный» — все тебе.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration,
          'Ты открываешь историю звонков Артёма. Три пропущенных: 23:14, 23:19, '
          '23:31.'),
      VnLine(Speaker.narration,
          'Все — тебе. Он звонил тебе последним, а ты не взял трубку.'),
      VnLine(Speaker.mira, 'Я всё ждала, когда ты сам это увидишь.'),
    ],
    choices: <VnChoice>[
      VnChoice(label: 'Прожить ночь заново', goto: 'ring', tag: 'петля'),
    ],
  ),
  'ending_leave': const VnNode(
    id: 'ending_leave',
    endsNight: true,
    cg: CgSpec(
      id: 'ending_leave',
      mood: Mood.night,
      brief: 'Телефон ложится экраном вниз. Свет гаснет. Комната в темноте.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration,
          'Ты кладёшь телефон экраном вниз. Некоторые двери лучше не открывать.'),
      VnLine(Speaker.narration,
          'Утром ты не узнаешь правды — и научишься с этим жить. Это тоже выбор.'),
    ],
    choices: <VnChoice>[
      VnChoice(label: '…или всё-таки ответить', goto: 'ring', tag: 'петля'),
    ],
  ),
  // True ending — reached only when all 7 fragments are collected.
  'ending_true': const VnNode(
    id: 'ending_true',
    endsNight: true,
    cg: CgSpec(
      id: 'ending_voice',
      mood: Mood.dawn,
      brief:
          'Возврат цвета, рассвет в окне. На телефоне — непрослушанное '
          'голосовое, записанное для тебя.',
    ),
    lines: <VnLine>[
      VnLine(Speaker.narration,
          'Семь осколков сложились в одно. Ты наконец решаешься нажать «play».'),
      VnLine(Speaker.narration,
          'Голос Артёма — тёплый, живой, записанный за минуты до.'),
      VnLine(Speaker.artem,
          'Что бы ни случилось — это не твоя вина. Слышишь? Не твоя. Живи.'),
      VnLine(Speaker.narration,
          'Впервые за всю ночь — тишина, в которой можно дышать. За окном '
          'светлеет. Часы идут дальше.'),
    ],
    choices: <VnChoice>[
      VnChoice(
          label: 'Проснуться — по-настоящему',
          goto: 'ring',
          tag: 'новый круг'),
    ],
  ),
  'slice_end': const VnNode(
    id: 'slice_end',
    endsNight: true,
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
