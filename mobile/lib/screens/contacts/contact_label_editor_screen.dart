import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';

import '../../contacts/avatar_palette.dart';
import '../../contacts/contact_display.dart';
import '../../db/app_database.dart';
import '../../db/repositories/contacts_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../widgets/screen_body_padding.dart';

/// Edit how this device shows a connected (or disconnected) contact: local
/// label and notes only. Peer canonical name and avatar are read-only.
class ContactLabelEditorScreen extends StatefulWidget {
  const ContactLabelEditorScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<ContactLabelEditorScreen> createState() =>
      _ContactLabelEditorScreenState();
}

class _ContactLabelEditorScreenState extends State<ContactLabelEditorScreen> {
  AppDatabase get _db => AppDatabase.processScope;
  late final ContactsRepository _repo = ContactsRepository(_db);

  final _labelController = TextEditingController();
  final _notesController = TextEditingController();
  Contact? _contact;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _repo.get(widget.contactId);
    if (!mounted) return;
    setState(() {
      _contact = c;
      _loading = false;
      if (c != null) {
        _labelController.text = c.localDisplayLabel ?? '';
        _notesController.text = c.notes;
      }
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _save() async {
    final c = _contact;
    if (c == null || _saving) return;
    _dismissKeyboard();
    setState(() => _saving = true);
    await _repo.setLocalDisplayLabel(c.id, _labelController.text);
    await _repo.setNotes(c.id, _notesController.text);
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch != null && c.kind == 'connected') {
      unawaited(orch.notifyPeerOfLocalDisplayLabelChange(c.id));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.contactsLabelEditorScreenTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final c = _contact;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.contactsLabelEditorScreenTitle)),
        body: Center(child: Text(l10n.contactsDetailMissing)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactsLabelEditorScreenTitle)),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: screenBodyScrollPadding(context),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      AvatarPalette.iconFor(c.avatarId),
                      size: 32,
                    ),
                  ),
                  if (c.showsDistinctPeerCanonicalForDisplay) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.contactsFieldTheirNameLabel,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            c.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: l10n.contactsFieldNameLabel,
                  hintText: l10n.contactsLabelEditorHint,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.contactsFieldAvatarReadOnlyFootnote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.contactsFieldNotesLabel,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.contactsFieldNotesFootnote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () {
                            _dismissKeyboard();
                            context.pop();
                          },
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.commonSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
