abstract class EntitySyncer {
  /// 把本地 pending 推到服务端
  Future<void> pushPending();

  /// 从服务端拉取最新数据写入本地
  Future<void> pull({DateTime? since});
}