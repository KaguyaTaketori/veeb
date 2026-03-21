import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../syncer_interface.dart';

// 目前服务端没有对应路由，先做本地存储
class ScheduledBillSyncer implements EntitySyncer {
  final Ref _ref;
  ScheduledBillSyncer(this._ref);

  @override
  Future<void> pushPending() async {
    // TODO: 服务端实现 /scheduled-bills 后补充
    debugPrint('[ScheduledBillSyncer] 暂未实现云端同步');
  }

  @override
  Future<void> pull({DateTime? since}) async {
    // TODO
  }
}