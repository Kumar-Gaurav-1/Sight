# Production Code Signing Guide

## Prerequisites

1. **Apple Developer Account** ($99/year)
   - Required for Developer ID certificates
   - Enables notarization

2. **Developer ID Application Certificate**
   ```bash
   # Request certificate in Xcode:
   # Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application
   ```

3. **App-Specific Password** (for notarization)
   ```bash
   # Generate at: appleid.apple.com → Security → App-Specific Passwords
   # Store in keychain:
   xcrun notarytool store-credentials "notarytool-profile" \
     --apple-id "your@email.com" \
     --team-id "TEAM_ID" \
     --password "app-specific-password"
   ```

---

## Production Build Script

Create `scripts/build-production.sh`:

```bash
#!/bin/bash
set -e

DEVELOPER_ID="Developer ID Application: Your Name (TEAM_ID)"
BUNDLE_ID="com.kumargaurav.Sight"

# Build with hardened runtime
swift build -c release --arch arm64 --arch x86_64

# Create universal binary
lipo -create \
    .build/arm64-apple-macosx/release/Sight \
    .build/x86_64-apple-macosx/release/Sight \
    -output .build/release/Sight

# Sign with hardened runtime and entitlements
codesign --force \
    --options runtime \
    --entitlements Sight.entitlements \
    --sign "$DEVELOPER_ID" \
    --timestamp \
    build/Sight.app

# Verify signature
codesign --verify --deep --strict --verbose=2 build/Sight.app

# Create DMG (with background)
./scripts/create-dmg.sh

# Sign DMG
codesign --sign "$DEVELOPER_ID" Sight-Installer.dmg

# Notarize
xcrun notarytool submit Sight-Installer.dmg \
    --keychain-profile "notarytool-profile" \
    --wait

# Staple notarization ticket
xcrun stapler staple Sight-Installer.dmg

echo "✅ Production DMG ready for distribution!"
```

---

## Entitlements for Hardened Runtime

The existing `Sight.entitlements` is already configured for hardened runtime:
- ✓ Apple Events automation
- ✓ Network client access
- ✓ JIT disabled (security)
- ✓ Unsigned executable memory disabled

---

## Verification Commands

```bash
# Check architecture
lipo -info build/Sight.app/Contents/MacOS/Sight
# Should show: arm64 x86_64

# Verify signature
codesign -dv --verbose=4 build/Sight.app

# Check hardened runtime
codesign -d --entitlements - build/Sight.app

# Verify notarization
spctl -a -vv -t install Sight-Installer DMG
# Should show: accepted
```

---

## Troubleshooting

### Code Signing Fails
- Ensure Developer ID certificate is installed
- Check certificate validity: `security find-identity -v -p codesigning`

### Notarization Fails
- Run: `xcrun notarytool log <submission-id> --keychain-profile "notarytool-profile"`
- Common issues:
  - Missing Info.plist keys
  - Invalid entitlements
  - Unsigned frameworks

### Gatekeeper Blocks App
- App not notarized
- Run: `xattr -cr Sight.app` to clear quarantine (development only)

---

## CI/CD Integration

For automated builds (GitHub Actions):

```yaml
- name: Import Code Signing Certificates
  env:
    P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
    P12_BASE64: ${{ secrets.P12_BASE64 }}
  run: |
    echo $P12_BASE64 | base64 --decode > certificate.p12
    security create-keychain -p "" build.keychain
    security import certificate.p12 -k build.keychain -P $P12_PASSWORD -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain
```

---

## Current Status

**Development (ad-hoc signing):** ✅ Working
- Local testing enabled
- Users must bypass Gatekeeper

**Production (Developer ID):** 📋 Requires Apple Developer Account
- Follow steps above to enable
- Recommended for public distribution
