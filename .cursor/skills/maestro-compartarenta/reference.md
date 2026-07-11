# Maestro Compartarenta — reference

## Shared subflows (contacts)

| File | Purpose |
|------|---------|
| `_enter_contacts_hub.yaml` | Cold start → home → contacts (empty or FAB) |
| `_on_contacts_hub.yaml` | Warm app → contacts without launch |
| `_return_to_contacts_list.yaml` | From invitations/home → contacts (`qa-contacts-redeem-open`) |
| `_accept_notification_prompt.yaml` | Oui + system Allow |
| `_dismiss_notification_prompt.yaml` | Delegates to accept (project policy) |

## Shared subflows (housing)

| File | Purpose |
|------|---------|
| `_enter_housing_hub.yaml` | Launch → housing tile → active hub |
| `_dismiss_ime_done.yaml` | Gboard checkmark after `inputText` |
| `_save_expense_line.yaml` | IME dismiss + tap expense save |

## Handshake flow names

| Flow | Device | Notes |
|------|--------|-------|
| `contact_handshake_inviter_generate.yaml` | Proposer | Ends on short-code screen |
| `contact_handshake_invitee_redeem_wait_connected.yaml` | Recipient | Asserts contact row |
| `contact_handshake_inviter_standby.yaml` | Proposer | Wait redeem + return contacts |
| `contact_handshake_inviter_dismiss_merge_dialog.yaml` | Proposer | Post–Louys drift merge dialog |
| `contact_handshake_invitee_probe_duplicate_monica.yaml` | Recipient | **Positive** probe (expects duplicate UI) |
| `contact_handshake_invitee_assert_no_duplicate_monica.yaml` | Recipient | Clean guard (`index: 1` not visible) |

## Multi-scenario run

```bash
./tool/melosw run qa:run-multi-scenario -- housing_proposal_bug_122
./tool/melosw run qa:run-scenario -- settlement_open
./tool/melosw run qa:verify
```

## Maestro MCP setup

1. `./tool/melosw run qa:install-maestro` (once)
2. Cursor: enable MCP server **maestro** (`.cursor/mcp.json`)
3. Start emulators / run scenario seed so devices appear in `list_devices`
4. Toggle MCP off/on in Cursor after Maestro CLI upgrade

## Coordinator probe return codes (`housing_proposal.sh`)

| `_run_maestro_probe` result | Meaning |
|----------------------------|---------|
| 0 | Symptom **present** (maestro probe flow passed) |
| 1 | Symptom **absent** (maestro failed — expected for clean negative) |
| 2 | Infra (device offline, etc.) |

Do not treat invitee delivery/hub success as proof when the bug is on **contacts list**.
