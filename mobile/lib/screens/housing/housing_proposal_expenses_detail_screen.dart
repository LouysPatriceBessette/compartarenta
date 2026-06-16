import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/expense_form/expense_plan_line_view_data.dart';
import '../../housing/expense_form/housing_expense_line_presentation_card.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/screen_body_padding.dart';

/// Swipeable read-only expense cards for a housing proposal preview.
class HousingProposalExpensesDetailScreen extends StatefulWidget {
  const HousingProposalExpensesDetailScreen({
    super.key,
    required this.db,
    required this.planId,
    required this.participantIds,
    required this.participantNames,
    required this.defaultCurrency,
    required this.dateFormat,
    this.initialPageIndex = 0,
  });

  final AppDatabase db;
  final String planId;
  final List<String> participantIds;
  final List<String> participantNames;
  final String defaultCurrency;
  final String dateFormat;
  final int initialPageIndex;

  @override
  State<HousingProposalExpensesDetailScreen> createState() =>
      _HousingProposalExpensesDetailScreenState();
}

class _HousingProposalExpensesDetailScreenState
    extends State<HousingProposalExpensesDetailScreen> {
  late final PageController _pageController;
  late int _pageIndex;
  Future<_ExpensesDetailPayload>? _payloadFuture;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _payloadFuture ??= _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<_ExpensesDetailPayload> _load() async {
    final l10n = AppLocalizations.of(context);
    final lines = await widget.db.listPlanLines(widget.planId);
    final sorted = [...lines]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final views = <ExpensePlanLineViewData?>[];
    for (final line in sorted) {
      views.add(
        await ExpensePlanLineViewData.load(
          db: widget.db,
          planId: widget.planId,
          line: line,
          participantIds: widget.participantIds,
          participantNames: widget.participantNames,
          l10n: l10n,
          dateFormat: widget.dateFormat,
          defaultCurrency: widget.defaultCurrency,
        ),
      );
    }
    return _ExpensesDetailPayload(lines: sorted, views: views);
  }

  void _goToPage(int index, int pageCount) {
    if (index < 0 || index >= pageCount) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.housingInviteExpensesDetailTitle),
      ),
      body: FutureBuilder<_ExpensesDetailPayload>(
        future: _payloadFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final payload = snap.data!;
          if (payload.lines.isEmpty) {
            return Center(child: Text(l10n.housingInviteSunburstEmptyHint));
          }
          final pageCount = payload.lines.length;
          final pageIndex = _pageIndex.clamp(0, pageCount - 1);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  l10n.housingInviteExpensesDetailSwipeHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: l10n.housingInviteExpensesDetailPrevious,
                      onPressed: pageIndex > 0
                          ? () => _goToPage(pageIndex - 1, pageCount)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      l10n.housingInviteExpensesDetailPageIndicator(
                        pageIndex + 1,
                        pageCount,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.housingInviteExpensesDetailNext,
                      onPressed: pageIndex < pageCount - 1
                          ? () => _goToPage(pageIndex + 1, pageCount)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pageCount,
                    onPageChanged: (i) => setState(() => _pageIndex = i),
                    itemBuilder: (context, index) {
                      final view = payload.views[index];
                      if (view == null) {
                        return Center(
                          child: Text(l10n.housingInviteExpensesDetailLoadError),
                        );
                      }
                      return SingleChildScrollView(
                        padding: screenBodyScrollPadding(
                          context,
                          content: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        ),
                        child: HousingExpenseLinePresentationCard(viewData: view),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpensesDetailPayload {
  _ExpensesDetailPayload({required this.lines, required this.views});

  final List<PlanLine> lines;
  final List<ExpensePlanLineViewData?> views;
}
