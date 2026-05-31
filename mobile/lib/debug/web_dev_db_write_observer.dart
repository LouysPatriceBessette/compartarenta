import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

typedef DebugWebDbWriteHook = void Function();

DebugWebDbWriteHook? debugWebDbWriteHook;

/// While restoring a host snapshot, Drift import must not schedule a PUT that
/// could overwrite the host file with prefs that are not imported yet.
bool suppressDevHostSessionWriteObserver = false;

QueryExecutor devHostSessionWriteObserver(QueryExecutor inner) {
  return inner.interceptWith(_DevHostSessionWriteInterceptor());
}

final class _DevHostSessionWriteInterceptor extends QueryInterceptor {
  void _notifyWrite(String sql) {
    if (!kDebugMode || suppressDevHostSessionWriteObserver) return;
    final trimmed = sql.trimLeft().toUpperCase();
    if (trimmed.startsWith('INSERT') ||
        trimmed.startsWith('UPDATE') ||
        trimmed.startsWith('DELETE') ||
        trimmed.startsWith('REPLACE')) {
      debugWebDbWriteHook?.call();
    }
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) async {
    await super.runBatched(executor, statements);
    if (kDebugMode && !suppressDevHostSessionWriteObserver) {
      debugWebDbWriteHook?.call();
    }
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    await super.runCustom(executor, statement, args);
    _notifyWrite(statement);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await super.runDelete(executor, statement, args);
    _notifyWrite(statement);
    return result;
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await super.runInsert(executor, statement, args);
    _notifyWrite(statement);
    return result;
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await super.runUpdate(executor, statement, args);
    _notifyWrite(statement);
    return result;
  }
}
