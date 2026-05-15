import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../contacts/avatar_palette.dart';
import '../../contacts/contact_display.dart';
import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../relay/handshake_orchestrator.dart';

/// Post-onboarding editing of the user's own display name and avatar.
class ProfileIdentitySettingsScreen extends StatefulWidget {
  const ProfileIdentitySettingsScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  State<ProfileIdentitySettingsScreen> createState() =>
      _ProfileIdentitySettingsScreenState();
}

class _ProfileIdentitySettingsScreenState
    extends State<ProfileIdentitySettingsScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.prefs.displayName);
  late String _avatarId = widget.prefs.avatarId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _avatarId.trim().isNotEmpty;

  Future<List<Contact>> _connectedContacts() async {
    final repo = ContactsRepository(AppDatabase.processScope);
    final all = await repo.list();
    return all.where((c) => c.kind == 'connected').toList();
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    await widget.prefs.setProfileIdentity(
      displayName: _name.text.trim(),
      avatarId: _avatarId,
    );
    final repo = ContactsRepository(AppDatabase.processScope);
    await repo.clearTheirLabelForMeWhenMatchesCanonical(_name.text.trim());
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch != null) {
      orch.steadyStateInboxTick.value = orch.steadyStateInboxTick.value + 1;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  Widget _appearancesTable(
    BuildContext context,
    AppLocalizations l10n,
    AsyncSnapshot<List<Contact>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    final connected = snapshot.data ?? const <Contact>[];
    if (connected.isEmpty) {
      return Text(
        l10n.settingsProfileAppearancesEmpty,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final withShared = connected
        .where((c) => (c.theirLabelForMe ?? '').trim().isNotEmpty)
        .toList();
    if (withShared.isEmpty) {
      return Text(
        l10n.settingsProfileAppearancesNoSharedLabels,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                l10n.settingsProfileAppearancesColumnPeer,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                l10n.settingsProfileAppearancesColumnTheirLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final c in withShared) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  c.effectiveDisplayName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  c.theirLabelForMe!.trim(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsProfileIdentityTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.settingsProfileIdentitySubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.onboardingNameLabel,
                hintText: l10n.onboardingNameHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.onboardingAvatarTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: AvatarPalette.length,
                itemBuilder: (context, index) {
                  final id = AvatarPalette.idFor(index);
                  final selected = id == _avatarId;
                  return InkWell(
                    onTap: () => setState(() => _avatarId = id),
                    borderRadius: BorderRadius.circular(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                          width: selected ? 2 : 1,
                        ),
                        color: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                      ),
                      child: Icon(AvatarPalette.iconAt(index)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.settingsProfileAppearancesTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.settingsProfileAppearancesBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            HandshakeOrchestrator.maybeInstance == null
                ? FutureBuilder<List<Contact>>(
                    future: _connectedContacts(),
                    builder: (context, snapshot) =>
                        _appearancesTable(context, l10n, snapshot),
                  )
                : ListenableBuilder(
                    listenable:
                        HandshakeOrchestrator.maybeInstance!.steadyStateInboxTick,
                    builder: (context, _) {
                      return FutureBuilder<List<Contact>>(
                        key: ValueKey<int>(
                          HandshakeOrchestrator.maybeInstance!
                              .steadyStateInboxTick.value,
                        ),
                        future: _connectedContacts(),
                        builder: (context, snapshot) =>
                            _appearancesTable(context, l10n, snapshot),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => context.pop(),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSave && !_saving ? _save : null,
                  child: Text(l10n.commonSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
