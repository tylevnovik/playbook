import '../../domain/entities/character.dart';
import '../../domain/entities/world_book.dart';

class SampleContent {
  static List<Character> characters() {
    final now = DateTime.now();
    return [
      Character(
        id: '',
        name: '林夜，旧城档案员',
        description:
            '林夜是雾港旧城档案馆的夜班管理员。她谨慎、敏锐，习惯用提问推进真相，不会立刻相信任何人的说辞。她熟悉旧城失踪案、禁书目录和码头暗号，但会把危险信息分层透露。',
        greeting:
            '档案馆的钟刚敲过十一下。林夜把一盏绿色台灯推到你面前，低声说：“如果你来查三年前那场失火，先告诉我，你是想找真相，还是想找一个能活着回去的答案？”',
        exampleMessages:
            '<user>: 我在码头捡到这枚铜扣。\n<char>: 林夜戴上薄手套，把铜扣翻到背面。“雾港船工不会用这种纹样。它属于旧剧院的制服，而且是事故前的款式。”\n\n<user>: 你是不是已经知道凶手是谁？\n<char>: “我知道几个人在撒谎。”她合上档案夹，“但凶手这个词太快了。快到会让真正重要的细节逃走。”',
        systemPrompt: '保持悬疑调查语气。不要一次性揭示全部真相；优先给出可追问的线索、矛盾和现场细节。',
        tags: const ['悬疑', '调查', '慢热'],
        createdAt: now,
        updatedAt: now,
      ),
      Character(
        id: '',
        name: 'Mara，星港调停员',
        description:
            'Mara 是远星货运站的中立调停员，专门处理走私嫌疑、船员纠纷和殖民地商约。她冷静、幽默、重视证据，擅长把紧张场面拆成可谈判的问题。',
        greeting:
            '警报灯把谈判室染成红色。Mara 把三份互相矛盾的航行记录摊在桌上，对你笑了笑：“好消息是，没人开火。坏消息是，每个人都在撒谎。你想先听哪一份？”',
        exampleMessages:
            '<user>: 船长说货舱是空的。\n<char>: “那他一定也能解释为什么空货舱需要三倍冷却剂。”Mara 指了指读数，“我不介意谎言，但我讨厌懒惰的谎言。”\n\n<user>: 我们能和平解决吗？\n<char>: “能，只要每个人都相信开战比签字更贵。”',
        systemPrompt: '以科幻政治与谈判为核心。回答应给出局势、筹码、风险和下一步选择，而不是替用户直接决定。',
        tags: const ['科幻', '谈判', '群像'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static List<SampleWorldBookTemplate> worldBooks() {
    return [
      const SampleWorldBookTemplate(
        name: '雾港旧城',
        description: '一座潮湿、守旧、被火灾和旧案缠住的港口城区。',
        entries: [
          SampleWorldBookEntryTemplate(
            name: '旧钟楼',
            keywords: ['钟楼', '十一点', '铜钟'],
            content: '旧钟楼位于雾港中央广场。三年前失火当晚，钟楼在没有守钟人的情况下敲响了十一下。当地人认为这是某种警告。',
            category: '地点',
            priority: 20,
          ),
          SampleWorldBookEntryTemplate(
            name: '灰潮帮',
            keywords: ['灰潮帮', '码头', '暗号'],
            content: '灰潮帮控制旧城东侧码头。他们使用三短一长的敲击作为安全暗号，但只在真正信任的人面前承认这一点。',
            category: '势力',
            priority: 15,
          ),
          SampleWorldBookEntryTemplate(
            name: '旧剧院火灾',
            keywords: ['剧院', '火灾', '三年前'],
            content: '旧剧院火灾造成七人失踪，却没有发现遗体。官方结论是煤气事故，档案馆内部记录则暗示有人提前锁死了后台出口。',
            category: '事件',
            priority: 30,
          ),
        ],
      ),
      const SampleWorldBookTemplate(
        name: '远星货运站',
        description: '殖民航线边缘的中立补给站，所有交易都在摄像头和谎言之间发生。',
        entries: [
          SampleWorldBookEntryTemplate(
            name: '环港公约',
            keywords: ['公约', '中立', '调停'],
            content: '环港公约规定货运站不得主动扣押任何注册船只，但可以在安全威胁下冻结泊位十二小时。这是调停员最常用的谈判窗口。',
            category: '规则',
            priority: 25,
          ),
          SampleWorldBookEntryTemplate(
            name: '冷舱走私',
            keywords: ['冷舱', '冷却剂', '走私'],
            content: '远星航线常见的走私方式是把生物样本藏入过量冷却的空货舱。冷却剂消耗异常通常比货单更可信。',
            category: '线索',
            priority: 20,
          ),
          SampleWorldBookEntryTemplate(
            name: '第七码头',
            keywords: ['第七码头', '货运站', '泊位'],
            content: '第七码头被称为“没有记录的地方”。它的监控死角只有九十秒，但足够完成一次货箱交换或一次误会。',
            category: '地点',
            priority: 10,
          ),
        ],
      ),
    ];
  }
}

class SampleWorldBookTemplate {
  final String name;
  final String description;
  final List<SampleWorldBookEntryTemplate> entries;

  const SampleWorldBookTemplate({
    required this.name,
    required this.description,
    required this.entries,
  });

  WorldBook toWorldBook() {
    final now = DateTime.now();
    return WorldBook(
      id: '',
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class SampleWorldBookEntryTemplate {
  final String name;
  final List<String> keywords;
  final String content;
  final String category;
  final int priority;

  const SampleWorldBookEntryTemplate({
    required this.name,
    required this.keywords,
    required this.content,
    required this.category,
    required this.priority,
  });

  WorldBookEntry toEntry(String worldBookId) {
    final now = DateTime.now();
    return WorldBookEntry(
      id: '',
      worldBookId: worldBookId,
      name: name,
      keywords: keywords,
      content: content,
      category: category,
      priority: priority,
      enabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}
