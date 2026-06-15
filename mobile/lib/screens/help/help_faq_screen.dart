import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/screen_body_padding.dart';

/// FAQ anchor ids used by in-app links (fragment after `#`).
abstract final class HelpFaqAnchors {
  static const housingInviteParticipant = 'housing-invite-participant';
}

/// Frequently asked questions (in-app). Section anchors match [HelpFaqAnchors].
class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key, this.initialAnchor});

  final String? initialAnchor;

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final _housingInviteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitialAnchor());
  }

  void _scrollToInitialAnchor() {
    final anchor = widget.initialAnchor;
    if (anchor == null || anchor.isEmpty) return;
    GlobalKey? key;
    if (anchor == HelpFaqAnchors.housingInviteParticipant) {
      key = _housingInviteKey;
    }
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      alignment: 0.05,
    );
  }

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
          _FaqSection(
            sectionKey: _housingInviteKey,
            title: l10n.helpFaqHousingInviteParticipantTitle,
            body: l10n.helpFaqHousingInviteParticipantBody,
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection({
    required this.sectionKey,
    required this.title,
    required this.body,
  });

  final GlobalKey sectionKey;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: sectionKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(body),
          ],
        ),
      ),
    );
  }
}

/// Opens [HelpFaqScreen] scrolled to [anchor].
void openHelpFaq(BuildContext context, {String? anchor}) {
  final path = anchor == null || anchor.isEmpty
      ? '/help/faq'
      : '/help/faq#$anchor';
  context.push(path);
}
