import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/screen_body_padding.dart';
import '../../widgets/welcome_intro_content.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

/// FAQ anchor ids used by in-app links (fragment after `#`).
abstract final class HelpFaqAnchors {
  static const housingInviteParticipant = 'housing-invite-participant';
  static const vehicleFuelTank = 'vehicle-fuel-tank';
}

/// One FAQ accordion section. Add entries in [_buildFaqSections] only.
final class _FaqSectionData {
  const _FaqSectionData({
    required this.title,
    required this.children,
    this.anchor,
  });

  /// Fragment id for deep links; omit when the section has no anchor.
  final String? anchor;
  final String title;
  final List<Widget> children;
}

List<_FaqSectionData> _buildFaqSections(AppLocalizations l10n) => [
  _FaqSectionData(
    title: l10n.onboardingWelcomeTitle,
    children: const [WelcomeIntroContent()],
  ),
  _FaqSectionData(
    anchor: HelpFaqAnchors.housingInviteParticipant,
    title: l10n.helpFaqHousingInviteParticipantTitle,
    children: [Text(l10n.helpFaqHousingInviteParticipantBody)],
  ),
  _FaqSectionData(
    anchor: HelpFaqAnchors.vehicleFuelTank,
    title: l10n.helpFaqVehicleFuelTankTitle,
    children: [Text(l10n.helpFaqVehicleFuelTankBody)],
  ),
];

/// Frequently asked questions (in-app). Section anchors match [HelpFaqAnchors].
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key, this.initialAnchor});

  final String? initialAnchor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpFaqTitle)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          Text(
            l10n.helpFaqIntro,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _FaqExclusiveAccordionList(
            sections: _buildFaqSections(l10n),
            initialAnchor: initialAnchor,
          ),
        ],
      ),
    );
  }
}

/// At most one [ExpansionTile] expanded; new FAQ rows inherit this via [_buildFaqSections].
class _FaqExclusiveAccordionList extends StatefulWidget {
  const _FaqExclusiveAccordionList({
    required this.sections,
    this.initialAnchor,
  });

  final List<_FaqSectionData> sections;
  final String? initialAnchor;

  @override
  State<_FaqExclusiveAccordionList> createState() =>
      _FaqExclusiveAccordionListState();
}

class _FaqExclusiveAccordionListState extends State<_FaqExclusiveAccordionList> {
  late final List<ExpansibleController> _controllers;
  late final List<GlobalKey> _sectionKeys;

  @override
  void initState() {
    super.initState();
    _initControllersAndKeys();
    _expandInitialAnchorIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _FaqExclusiveAccordionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      for (final c in _controllers) {
        c.dispose();
      }
      _initControllersAndKeys();
      _expandInitialAnchorIfNeeded();
    }
  }

  void _initControllersAndKeys() {
    final count = widget.sections.length;
    _controllers = List.generate(count, (_) => ExpansibleController());
    _sectionKeys = List.generate(count, (_) => GlobalKey());
  }

  void _expandInitialAnchorIfNeeded() {
    final anchor = widget.initialAnchor;
    if (anchor == null || anchor.isEmpty) return;
    final index = widget.sections.indexWhere((s) => s.anchor == anchor);
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controllers[index].expand();
      _scrollToSection(index);
    });
  }

  void _scrollToSection(int index) {
    final context = _sectionKeys[index].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      alignment: 0.05,
    );
  }

  void _onExpansionChanged(int index, bool expanded) {
    if (!expanded) return;
    for (var i = 0; i < _controllers.length; i++) {
      if (i != index) {
        _controllers[i].collapse();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Card(
            key: _sectionKeys[i],
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                controller: _controllers[i],
                title: Text(
                  widget.sections[i].title,
                  style: theme.textTheme.titleMedium,
                ),
                onExpansionChanged: (expanded) =>
                    _onExpansionChanged(i, expanded),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: widget.sections[i].children,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Opens [HelpFaqScreen] scrolled to [anchor].
void openHelpFaq(BuildContext context, {String? anchor}) {
  final path = anchor == null || anchor.isEmpty
      ? '/help/faq'
      : '/help/faq#$anchor';
  navigateToChild(context, path);
}
