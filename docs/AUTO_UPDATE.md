# Auto-Update Integration Guide

## Recommended: Sparkle Framework

[Sparkle](https://sparkle-project.org/) is the industry-standard auto-update framework for macOS apps.

## Integration Steps

### 1. Add Sparkle as Dependency

Add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.5.0")
],
targets: [
    .executableTarget(
        name: "Sight",
        dependencies: ["Sparkle"]
    )
]
```

### 2. Initialize Sparkle

In `AppDelegate.swift`:

```swift
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Sparkle
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
}
```

### 3. Configure Info.plist

Add to Info.plist:

```xml
<key>SUFeedURL</key>
<string>https://your-domain.com/appcast.xml</string>

<key>SUEnableAutomaticChecks</key>
<true/>

<key>SUScheduledCheckInterval</key>
<integer>86400</integer>

<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
```

### 4. Create Appcast Feed

Generate EdDSA keys:

```bash
./bin/generate_keys
```

Create `appcast.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Sight Changelog</title>
        <item>
            <title>Version 1.1.0</title>
            <sparkle:version>1.1.0</sparkle:version>
            <sparkle:releaseNotesLink>https://your-domain.com/release-notes.html</sparkle:releaseNotesLink>
            <pubDate>Mon, 28 Dec 2024 12:00:00 +0000</pubDate>
            <enclosure url="https://your-domain.com/Sight-1.1.0.dmg"
                       sparkle:edSignature="SIGNATURE_HERE"
                       length="5000000"
                       type="application/octet-stream"/>
        </item>
    </channel>
</rss>
```

### 5. Sign Updates

```bash
./bin/sign_update Sight-1.1.0.dmg -f appcast.xml
```

---

## Alternative: Custom Update Checker

For simpler needs, implement a lightweight custom checker:

### Create Update Manager

```swift
import Foundation

class UpdateManager {
    static let shared = UpdateManager()
    private let updateURL = URL(string: "https://api.github.com/repos/Kumar-Gaurav-1/Sight/releases/latest")!
    
    func checkForUpdates() async throws -> UpdateInfo? {
        let (data, _) = try await URLSession.shared.data(from: updateURL)
        let release = try JSONDecoder().decode(GitHubRelease.struct, from: data)
        
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        
        if release.tagName.compare(currentVersion, options: .numeric) == .orderedDescending {
            return UpdateInfo(
                version: release.tagName,
                downloadURL: release.assets.first?.browserDownloadURL,
                releaseNotes: release.body
            )
        }
        return nil
    }
}

struct GitHubRelease: Codable {
    let tagName: String
    let body: String
    let assets: [Asset]
    
    struct Asset: Codable {
        let browserDownloadURL: URL
    }
}

struct UpdateInfo {
    let version: String
    let downloadURL: URL?
    let releaseNotes: String
}
```

### Add to Menu

```swift
Button("Check for Updates...") {
    Task {
        do {
            if let update = try await UpdateManager.shared.checkForUpdates() {
                showUpdateAlert(update)
            } else {
                showNoUpdateAlert()
            }
        } catch {
            showErrorAlert(error)
        }
    }
}
```

---

##Deployment Checklist

- [ ] Set up update server/CDN
- [ ] Configure SSL certificate
- [ ] Generate and secure signing keys
- [ ] Create CI/CD pipeline for releases
- [ ] Test update flow thoroughly
- [ ] Document rollback procedure

---

## Current Status

**Phase 3 Recommendation**: Document auto-update integration

The infrastructure is documented but **not implemented** to keep dependencies minimal for Phase 3.

**For production deployment:**
1. Choose Sparkle (recommended) or custom solution
2. Set up hosting for appcast/releases
3. Generate signing keys
4. Integrate update UI into preferences

This allows users to decide their preferred update mechanism based on distribution method (direct download vs Mac App Store).
