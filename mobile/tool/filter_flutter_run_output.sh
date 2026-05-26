#!/usr/bin/env bash
set -euo pipefail

awk '
function is_logcat_line(line) {
  return line ~ /^[VDIWEF]\/[^:]+[[:space:]]*\([0-9]+\): /
}

function is_flutter_line(line) {
  return line ~ /^[VDIWEF]\/flutter[[:space:]]*\([0-9]+\): /
}

function has_useful_keyword(line) {
  return line ~ /housing_/ ||
         line ~ /realized_expense/ ||
         line ~ /Handshake/ ||
         line ~ /steady inbox/ ||
         line ~ /local_storage_startup/ ||
         line ~ /Drift web storage/ ||
         line ~ /ClosedAppPushRegistrationService/ ||
         line ~ /Browser notification permission/ ||
         line ~ /relay/ ||
         line ~ /imported/ ||
         line ~ /posted/ ||
         line ~ /delivered/ ||
         line ~ /TimeoutException/
}

function is_noise_flutter_line(line) {
  return line ~ /Using the Impeller rendering backend/ ||
         line ~ /Width is zero\. 0,0/
}

function is_known_noise_error_line(line) {
  return line ~ /^E\/BufferQueueProducer/ ||
         line ~ /BufferQueue has been abandoned/
}

{
  if (!is_logcat_line($0)) {
    print
    fflush()
    next
  }

  if (($0 ~ /^[EF]\//) && !is_known_noise_error_line($0)) {
    print
    fflush()
    next
  }

  if (is_flutter_line($0) || has_useful_keyword($0)) {
    if (!is_noise_flutter_line($0)) {
      print
      fflush()
    }
    next
  }

  next
}
'
