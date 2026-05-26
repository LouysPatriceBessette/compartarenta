import 'package:flutter/foundation.dart';

/// Pending navigation after a housing notification tap.
class HousingNavigationIntent {
  HousingNavigationIntent._();

  static String? pendingRealizedExpenseReviewId;
  static final ValueNotifier<int> reviewRequestTick = ValueNotifier<int>(0);

  static void requestReview(String expenseId) {
    pendingRealizedExpenseReviewId = expenseId;
    reviewRequestTick.value = reviewRequestTick.value + 1;
  }

  static String? takePendingReview() {
    final id = pendingRealizedExpenseReviewId;
    pendingRealizedExpenseReviewId = null;
    return id;
  }
}
