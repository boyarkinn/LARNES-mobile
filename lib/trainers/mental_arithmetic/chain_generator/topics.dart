/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/topics.ts`

enum TopicBlock { simple, brother, friend, transition, friendBrother, anzan }

enum TopicStatus { mvp, later }

class TopicMeta {
  const TopicMeta({
    required this.block,
    required this.id,
    required this.label,
    required this.status,
    required this.totalRods,
  });

  final TopicBlock block;
  final String id;
  final String label;
  final TopicStatus status;
  final int totalRods;
}

const _simpleDigitTopics = [1, 2, 3, 4, 5, 6, 7, 8, 9];
const _brotherNs = [4, 3, 2, 1];
const _friendNs = [9, 8, 7, 6, 5, 4, 3, 2, 1];
const _friendBrotherNs = [6, 7, 8, 9];

List<TopicMeta> _buildTopicCatalog() {
  final topics = <TopicMeta>[];

  for (final digit in _simpleDigitTopics) {
    topics.add(
      TopicMeta(
        block: TopicBlock.simple,
        id: 'simple-$digit',
        label: 'Просто $digit',
        status: TopicStatus.mvp,
        totalRods: 1,
      ),
    );
  }

  topics.addAll(const [
    TopicMeta(
      block: TopicBlock.simple,
      id: 'simple-tens',
      label: 'Просто десятки',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.simple,
      id: 'simple-11-19',
      label: 'Просто 11–19',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.simple,
      id: 'simple-2digit',
      label: 'Просто двузначные',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.simple,
      id: 'simple-2digit-1digit',
      label: 'Просто двузначные + однозначные',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.simple,
      id: 'simple-hundreds',
      label: 'Просто сотни',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.simple,
      id: 'simple-3digit',
      label: 'Просто трёхзначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.simple,
      id: 'simple-3digit-1digit',
      label: 'Просто трёхзначные + однозначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.simple,
      id: 'simple-3digit-2digit',
      label: 'Просто трёхзначные + двузначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.simple,
      id: 'simple-3digit-2digit-1digit',
      label: 'Просто трёхзначные + однозначные + двузначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
  ]);

  for (final n in _brotherNs) {
    topics.add(
      TopicMeta(
        block: TopicBlock.brother,
        id: 'brother-$n-1digit',
        label: 'Брат $n однозначные',
        status: TopicStatus.mvp,
        totalRods: 1,
      ),
    );
    topics.add(
      TopicMeta(
        block: TopicBlock.brother,
        id: 'brother-$n-2digit',
        label: 'Брат $n двузначные',
        status: TopicStatus.mvp,
        totalRods: 2,
      ),
    );
    topics.add(
      TopicMeta(
        block: TopicBlock.brother,
        id: 'brother-$n-2digit-1digit',
        label: 'Брат $n двузначные + однозначные',
        status: TopicStatus.mvp,
        totalRods: 2,
      ),
    );
  }

  topics.addAll(const [
    TopicMeta(
      block: TopicBlock.brother,
      id: 'brother-3digit',
      label: 'Братья трёхзначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.brother,
      id: 'brother-3digit-1digit',
      label: 'Братья трёхзначные + однозначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.brother,
      id: 'brother-3digit-2digit',
      label: 'Братья трёхзначные + двузначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.brother,
      id: 'brother-3digit-2digit-1digit',
      label: 'Братья трёхзначные + однозначные + двузначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
  ]);

  for (final n in _friendNs) {
    topics.add(
      TopicMeta(
        block: TopicBlock.friend,
        id: 'friend-$n-1digit',
        label: 'Друг $n однозначные',
        status: TopicStatus.mvp,
        totalRods: 2,
      ),
    );
    topics.add(
      TopicMeta(
        block: TopicBlock.friend,
        id: 'friend-$n-2digit',
        label: 'Друг $n двузначные',
        status: TopicStatus.mvp,
        totalRods: 2,
      ),
    );
    topics.add(
      TopicMeta(
        block: TopicBlock.friend,
        id: 'friend-$n-2digit-1digit',
        label: 'Друг $n двузначные + однозначные',
        status: TopicStatus.mvp,
        totalRods: 2,
      ),
    );
  }

  topics.addAll(const [
    TopicMeta(
      block: TopicBlock.friend,
      id: 'friend-3digit',
      label: 'Друзья трёхзначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.friend,
      id: 'friend-3digit-1digit',
      label: 'Друзья трёхзначные + однозначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.friend,
      id: 'friend-3digit-2digit',
      label: 'Друзья трёхзначные + двузначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.friend,
      id: 'friend-3digit-2digit-1digit',
      label: 'Друзья трёхзначные + однозначные + двузначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
  ]);

  topics.addAll(const [
    TopicMeta(
      block: TopicBlock.transition,
      id: 'transition-50',
      label: 'Переход через 50',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.transition,
      id: 'transition-100',
      label: 'Переход через 100',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
  ]);

  for (final n in _friendBrotherNs) {
    topics.add(
      TopicMeta(
        block: TopicBlock.friendBrother,
        id: 'friend-brother-$n-1digit',
        label: 'Друг + брат $n однозначные',
        status: TopicStatus.mvp,
        totalRods: 2,
      ),
    );
    topics.add(
      TopicMeta(
        block: TopicBlock.friendBrother,
        id: 'friend-brother-$n-2digit',
        label: 'Друг + брат $n двузначные',
        status: TopicStatus.mvp,
        totalRods: 3,
      ),
    );
  }

  topics.addAll(const [
    TopicMeta(
      block: TopicBlock.anzan,
      id: 'anzan-1digit-add',
      label: 'Анзан однозначные сложение',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.anzan,
      id: 'anzan-1digit-sub',
      label: 'Анзан однозначные вычитание',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.anzan,
      id: 'anzan-1digit-mix',
      label: 'Анзан однозначные',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.anzan,
      id: 'anzan-2digit',
      label: 'Анзан двузначные',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.anzan,
      id: 'anzan-2digit-1digit',
      label: 'Анзан двузначные + однозначные',
      status: TopicStatus.mvp,
      totalRods: 2,
    ),
    TopicMeta(
      block: TopicBlock.anzan,
      id: 'anzan-3digit',
      label: 'Анзан трёхзначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.anzan,
      id: 'anzan-3digit-1digit',
      label: 'Анзан трёхзначные + однозначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.anzan,
      id: 'anzan-3digit-2digit',
      label: 'Анзан трёхзначные + двузначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
    TopicMeta(
      block: TopicBlock.anzan,
      id: 'anzan-3digit-2digit-1digit',
      label: 'Анзан трёхзначные + однозначные + двузначные',
      status: TopicStatus.mvp,
      totalRods: 3,
    ),
  ]);

  return topics;
}

final List<TopicMeta> topicCatalog = List.unmodifiable(_buildTopicCatalog());

final List<String> topicIds =
    List.unmodifiable(topicCatalog.map((topic) => topic.id));

final Map<String, TopicMeta> _topicById = {
  for (final topic in topicCatalog) topic.id: topic,
};

bool isTopicId(String value) => _topicById.containsKey(value);

TopicMeta getTopicMeta(String topicId) {
  final meta = _topicById[topicId];
  if (meta == null) {
    throw ArgumentError('Unknown topicId: $topicId');
  }
  return meta;
}

List<TopicMeta> listTopicsByStatus(TopicStatus status) {
  return topicCatalog.where((topic) => topic.status == status).toList();
}

List<TopicMeta> listTopicsByBlock(TopicBlock block) {
  return topicCatalog.where((topic) => topic.block == block).toList();
}
