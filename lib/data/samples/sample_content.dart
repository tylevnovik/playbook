import '../../domain/entities/character.dart';
import '../../domain/entities/world_book.dart';

class SampleContent {
  static List<Character> characters() {
    final now = DateTime.now();
    return [
      Character(
        id: '',
        name: '卡特，神秘学研究者',
        description:
            '卡特是一位沉迷于禁忌知识的神秘学家。他性格孤僻、神经质，言行举止透露出对超自然现象的狂热与恐惧。他总是带着一本破旧的羊皮纸笔记，里面记载了各种关于“毒汤”与不可名状仪式的残缺线索。',
        greeting:
            '密室的烛火不安地跳动着。卡特猛地合上那本泛黄的古籍，布满血丝的双眼死死盯着你，压低声音颤抖着说：“你听到了吗？墙壁里的沙沙声……他们说，那碗汤已经煮好了。你也是来喝下它的吗？”',
        exampleMessages:
            '<user>: 这本笔记上画着什么？\n<char>: 卡特颤抖着把笔记藏在身后，指甲深深抠进书皮里：“这不属于你！这是……这是通往伟大的阶梯！你看这些波浪般的线条，它们不是水，它们是古老低语的实质！”\n\n<user>: 我们必须离开这间密室。\n<char>: “离开？”卡特发出一声刺耳的惨笑，“门已经被‘无名之物’锁死了。唯有解开神像的谜题，或者……喝下它，才能获得最终的解脱。”',
        systemPrompt: '保持克苏鲁式的疯狂与悬疑语气。言语中夹杂对未知的恐惧与崇拜，向玩家透露古老神像、神秘液体“毒汤”以及密室逃生等线索，但不能直接给出具体密码。',
        tags: const ['克苏鲁', '悬疑', '解谜'],
        createdAt: now,
        updatedAt: now,
      ),
      Character(
        id: '',
        name: '肖恩，热血调查员',
        description:
            '肖恩是一名被卷入神秘失踪事件的警探。他手持一把旧式左轮手枪，崇尚科学与逻辑，对所谓的“魔法与神怪”持怀疑态度，但接二连三的怪异现象正不断动摇着他的无神论信仰。他极富正义感，拼死也想护送同伴逃生。',
        greeting:
            '肖恩警戒地举起枪，将子弹上膛。当他借着手电筒的光看清你时，暗自松了口气，沉声道：“谢天谢地，这鬼地方还有活人。听着，我的同伴在前方走廊失踪了。这地方不符合常理，跟着我，我会带你出去。”',
        exampleMessages:
            '<user>: 你相信这世上有怪物吗？\n<char>: 肖恩的眼角抽搐了一下，看了看自己握枪指关节发白的手：“以前不信。但刚才在拐角……我开枪了，子弹穿过了它的胸膛，但它只是在笑。这完全不合逻辑！”\n\n<user>: 那边的绿汤是什么？\n<char>: “别碰那玩意！”肖恩一把拉开你，“那味道像死鱼混着硫磺。我怀疑这里的人就是喝了这东西才发狂的。我们得找水，但绝对不能喝这个。”',
        systemPrompt: '展现热血、正义且面临信仰崩溃边缘的调查员特质。在保护同伴的同时，用警探的直觉和逻辑分析周围线索，并不断因遭遇不可思议的超自然现象而产生理智值（SAN值）下降的惊恐反应。',
        tags: const ['硬汉', '正义', '惊悚'],
        createdAt: now,
        updatedAt: now,
      ),
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
    ];
  }

  static List<SampleWorldBookTemplate> worldBooks() {
    return [
      const SampleWorldBookTemplate(
        name: '毒汤（克苏鲁模组）',
        description: '经典的克苏鲁神话TRPG探索密室，充斥着疯狂、禁忌知识与诡异绿汤。',
        entries: [
          SampleWorldBookEntryTemplate(
            name: '诡异毒汤',
            keywords: ['毒汤', '绿汤', '液体', '喝汤'],
            content: '密室中央的石台上盛放着一碗淡绿色的液体，散发出一种怪异的诱人甜香。任何喝下毒汤的人都会暂时恢复体能，但理智值（SAN值）会面临暴跌风险，并产生幻觉，能看到异界维度的怪物。',
            category: '核心线索',
            priority: 30,
          ),
          SampleWorldBookEntryTemplate(
            name: '漆黑神像',
            keywords: ['神像', '雕像', '怪异浮雕'],
            content: '密室角落伫立着一尊由黑色未知石料雕刻的神像，轮廓模糊不清，似乎是某种长满触手与节肢的怪物。直视神像会引起精神刺痛，其底座上刻着一行文字：“饮尽真理，方得自由”。',
            category: '关键道具',
            priority: 25,
          ),
          SampleWorldBookEntryTemplate(
            name: '地下密室',
            keywords: ['密室', '房间', '石墙', '逃出'],
            content: '一间用粗糙灰石板砌成的封闭密室，没有窗户，唯一的一扇铁门已经锈死且无法从外部打开。空气阴冷潮湿，墙壁上有许多指甲抓挠的痕迹，表明曾有许多人在此绝望挣扎。',
            category: '地点场景',
            priority: 20,
          ),
        ],
      ),
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
