/// Pending navigation after a housing expense notification tap.
class HousingNavigationIntent {
  HousingNavigationIntent._();

  static String? pendingRealizedExpenseReviewId;

  static void requestReview(String expenseId) {
    pendingRealizedExpenseReviewId = expenseId;
  }

  static String? takePendingReview() {
    final id = pendingRealizedExpenseReviewId;
    pendingRealizedExpenseReviewId = null;
    return id;
  }
}
