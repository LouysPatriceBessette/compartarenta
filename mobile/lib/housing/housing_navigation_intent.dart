/// Pending navigation after a housing notification tap.
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
