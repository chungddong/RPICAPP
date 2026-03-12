import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/code_block.dart';
import '../models/device.dart';
import 'connection_provider.dart';

// 현재 실행 중인 코드블록 ID (null = 실행 없음)
final runningCodeIdProvider = StateProvider<String?>((ref) => null);

// 코드블록별 실행 상태 맵
final executionStateProvider =
    StateProvider<Map<String, ExecutionState>>((ref) => {});

class ExecutionService {
  final Ref _ref;
  ExecutionService(this._ref);

  Future<ExecutionResult?> runCode(CodeBlock block) async {
    final ble = _ref.read(bleServiceProvider);
    if (_ref.read(connectionProvider) == null) return null;

    // 상태 업데이트: running
    _ref.read(executionStateProvider.notifier).update(
          (s) => {...s, block.id: ExecutionState.running},
        );
    _ref.read(runningCodeIdProvider.notifier).state = block.id;

    try {
      final result = await ble.sendCode(block.code);

      // 상태 업데이트: success / error
      _ref.read(executionStateProvider.notifier).update(
            (s) => {
              ...s,
              block.id: result.success
                  ? ExecutionState.success
                  : ExecutionState.error,
            },
          );
      return result;
    } finally {
      _ref.read(runningCodeIdProvider.notifier).state = null;
    }
  }

  Future<void> stop() async {
    final ble = _ref.read(bleServiceProvider);
    await ble.stopExecution();
    _ref.read(runningCodeIdProvider.notifier).state = null;
  }
}

final executionServiceProvider = Provider<ExecutionService>(
  (ref) => ExecutionService(ref),
);
