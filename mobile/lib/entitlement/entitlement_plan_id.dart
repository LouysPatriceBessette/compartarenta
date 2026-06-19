import 'dart:convert';

/// Stable entitlement [`plan_id`] shared across author and received devices.
///
/// Author plans use local ids like `housing:default`; imported peers use
/// `received:<token>` where the token is derived from `pkg:<localPlanId>`.
/// Relay gates and roster HTTP must use this canonical id so introspection
/// hits the same entitlement plan record on every device.
String entitlementPlanIdForLocalPlan(String localPlanId) {
  if (localPlanId.startsWith('received:')) {
    return localPlanId;
  }
  final packageId = 'pkg:$localPlanId';
  final token = base64Url.encode(utf8.encode(packageId)).replaceAll('=', '');
  return 'received:$token';
}
