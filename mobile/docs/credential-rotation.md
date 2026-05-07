# Credential rotation / revocation runbook

This document describes how to rotate/revoke credentials used for mobile signing and store submissions.

## Android (Play App Signing upload key)

### Rotate upload key
1. Generate a new upload key keystore (`upload-keystore.jks`).
2. In Play Console, request an **upload key reset** (Play App Signing section).
3. Update CI secrets with the new keystore + passwords.
4. Verify a signed production AAB can be uploaded.

### If exposure is suspected
1. Rotate the upload key immediately (above).
2. Review CI logs and secret access history.
3. If you believe the app signing key is compromised (rare with Play App Signing), follow Google’s incident guidance.

## iOS (certificates, provisioning, App Store Connect API keys)

### Rotate App Store Connect API key
1. Create a new key in App Store Connect.
2. Update CI secrets (`ISSUER_ID`, `KEY_ID`, `P8_BASE64`).
3. Revoke the old key.

### Rotate certificates/profiles (Automatic signing)
1. Revoke compromised certificates in Apple Developer.
2. Recreate certificates and provisioning as needed.
3. Validate CI build/sign and TestFlight upload.

### Rotate `match` (if used)
1. Generate new certs via `fastlane match nuke` (carefully) or by revoking and re-issuing.
2. Update match storage and CI secrets.
3. Validate build/sign and TestFlight upload.

