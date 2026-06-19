import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

typedef DebugWebDbWriteHook = void Function();

DebugWebDbWriteHook? debugWebDbWriteHook;

/// While restoring a host snapshot, Drift import must not schedule a PUT that
/// could overwrite the host file with prefs that are not imported yet.
bool suppressDevHostSessionWriteObserver = false;

/// Open Drift transactions on the dev host database (web only).
///
/// Snapshot export must wait until this reaches zero: Drift's web remote
/// executor rejects concurrent reads while a transaction is active.
int devHostDriftOpenTransactions = 0;

/// Waits until no Drift transaction is open on the dev host database.
Future<void> waitForDevHostDriftTransactionsIdle({
  Duration timeout = const Duration(seconds: 15),
  Duration pollInterval = const Duration(milliseconds: 25),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (devHostDriftOpenTransactions > 0) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError(
        'Drift transaction still open after ${timeout.inMilliseconds}ms '
        '(depth=$devHostDriftOpenTransactions)',
      );
    }
    await Future<void>.delayed(pollInterval);
  }
}

QueryExecutor devHostSessionWriteObserver(QueryExecutor inner) {
  return inner.interceptWith(_DevHostSessionWriteInterceptor());
}

final class _DevHostSessionWriteInterceptor extends QueryInterceptor {
  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    devHostDriftOpenTransactions++;
    return super.beginTransaction(parent);
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    try {
      await super.commitTransaction(inner);
    } finally {
      devHostDriftOpenTransactions--;
    }
  }

  @override
  Future<void> rollbackTransaction(TransactionExecutor inner) async {
    try {
      await super.rollbackTransaction(inner);
    } finally {
      devHostDriftOpenTransactions--;
    }
  }

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
