import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP client for the entitlement service (Phase A housing APIs).
class EntitlementClient {
  EntitlementClient({
    required this.baseUrl,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 10),
  })  : _client = httpClient ?? http.Client(),
        _timeout = timeout;

  final Uri baseUrl;
  final http.Client _client;
  final Duration _timeout;

  void close() => _client.close();

  Future<void> registerInstallation(String participantInstallationId) async {
    final uri = baseUrl.resolve('/v1/installations/register');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'participant_installation_id': participantInstallationId,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 204) {
      throw EntitlementClientError._fromResponse('installations_register', res);
    }
  }

  Future<void> reportPlanRoster({
    required String planId,
    required String revisionId,
    required List<String> participantInstallationIds,
  }) async {
    final uri = baseUrl.resolve('/v1/housing/plan-roster');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'plan_id': planId,
            'revision_id': revisionId,
            'participant_installation_ids': participantInstallationIds,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 204) {
      throw EntitlementClientError._fromResponse('housing_plan_roster', res);
    }
  }

  Future<void> reportActiveUse({required String planId}) async {
    final uri = baseUrl.resolve('/v1/housing/active-use');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'plan_id': planId}),
        )
        .timeout(_timeout);
    if (res.statusCode != 204) {
      throw EntitlementClientError._fromResponse('housing_active_use', res);
    }
  }

  Future<void> reportExpenseDecision({
    required String planId,
    required String expenseId,
    required String participantInstallationId,
    required String decisionKind,
  }) async {
    final uri = baseUrl.resolve('/v1/housing/expense-decision');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'plan_id': planId,
            'expense_id': expenseId,
            'participant_installation_id': participantInstallationId,
            'decision_kind': decisionKind,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 204) {
      throw EntitlementClientError._fromResponse('housing_expense_decision', res);
    }
  }
}

class EntitlementClientError implements Exception {
  EntitlementClientError({
    required this.endpoint,
    required this.statusCode,
    required this.code,
    required this.detail,
  });

  final String endpoint;
  final int statusCode;
  final String code;
  final String detail;

  factory EntitlementClientError._fromResponse(
    String endpoint,
    http.Response res,
  ) {
    String code = 'http_${res.statusCode}';
    String detail = res.reasonPhrase ?? '';
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      code = (body['error'] as String?) ?? (body['code'] as String?) ?? code;
      detail = (body['message'] as String?) ?? (body['detail'] as String?) ?? detail;
    } catch (_) {
      // Non-JSON body.
    }
    return EntitlementClientError(
      endpoint: endpoint,
      statusCode: res.statusCode,
      code: code,
      detail: detail,
    );
  }

  @override
  String toString() =>
      'EntitlementClientError($endpoint, status=$statusCode, code=$code, detail=$detail)';
}
