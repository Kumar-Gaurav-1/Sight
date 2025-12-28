# Localization Guide

## Overview
This guide explains how to add multi-language support to Sight.

## Setup Localization

### 1. Create Localizable.strings

For each supported language, create:
```
Resources/
├── en.lproj/
│   └── Localizable.strings
├── es.lproj/
│   └── Localizable.strings
├── fr.lproj/
│   └── Localizable.strings
└── de.lproj/
    └── Localizable.strings
```

### 2. Example Localizable.strings (English)

```
/* Menu Bar */
"menu.start" = "Start";
"menu.pause" = "Pause";
"menu.break" = "Take Break";
"menu.postpone" = "+5 min";
"menu.settings" = "Settings";
"menu.quit" = "Quit";

/* Break Messages */
"break.title" = "Time for a break!";
"break.message" = "Look at something 20 feet away for 20 seconds";
"break.skip" = "Skip Break";

/* Statistics */
"stats.breaks" = "Breaks";
"stats.streak" = "Streak";
"stats.goal" = "Goal";

/* Preferences */
"prefs.general" = "General";
"prefs.breaks" = "Breaks";
"prefs.wellness" = "Wellness Reminders";
"prefs.achievements" = "Achievements";
"prefs.statistics" = "Statistics";
"prefs.shortcuts" = "Shortcuts";
"prefs.about" = "About";

/* Notifications */
"notif.prebreak.title" = "Break coming soon";
"notif.prebreak.body" = "Break starting in %d seconds";
"notif.break.title" = "Time for a break!";
"notif.break.body" = "Take 20 seconds to rest your eyes";
```

### 3. Use NSLocalizedString in Code

Replace hardcoded strings:

**Before:**
```swift
Text("Take Break")
```

**After:**
```swift
Text(NSLocalizedString("menu.break", comment: "Take break button in menu"))
```

### 4. Update Info.plist

Add supported languages:

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>es</string>
    <string>fr</string>
    <string>de</string>
</array>

<key>CFBundleDevelopmentRegion</key>
<string>en</string>
```

---

## Translation Workflow

### 1. Extract Strings

```bash
# Generate strings file from code
genstrings -o Resources/en.lproj/ Sources/**/*.swift
```

### 2. Translate

Send `Localizable.strings` to translators or use services:
- Lokalise
- Crowdin
- POEditor

### 3. Import Translations

Place translated `.strings` files in respective `.lproj` folders.

### 4. Test

```bash
# Test Spanish
defaults write com.kumargaurav.Sight AppleLanguages '(es)'
open -a Sight

# Reset to English
defaults delete com.kumargaurav.Sight AppleLanguages
```

---

## Common Patterns

### Plurals

```swift
String.localizedStringWithFormat(
    NSLocalizedString("breaks.count", comment: ""),
    count
)
```

In Localizable.strings:
```
"breaks.count" = "%d breaks";
```

### Formatted Strings

```swift
String(format: NSLocalizedString("time.remaining", comment: ""), minutes, seconds)
```

```
"time.remaining" = "%d:%02d remaining";
```

---

## RTL Language Support

For Arabic, Hebrew, etc:

```swift
.environment(\.layoutDirection, .rightToLeft) // Test RTL
```

Ensure UI uses:
- `.leading` instead of `.left`
- `.trailing` instead of `.right`

---

## Priority Languages

Recommended order:
1. **English** (en) - Base
2. **Spanish** (es) - Large market
3. **French** (fr) - European market
4. **German** (de) - European market
5. **Japanese** (ja) - Asian market
6. **Chinese Simplified** (zh-Hans) - Asian market

---

## Current Status

**Phase 3**: Localization infrastructure documented

**Implementation Pending:**
- Create `.lproj` folders
- Extract all UI strings
- Replace hardcoded text with NSLocalizedString
- Translate to priority languages

This provides the foundation for future international expansion.
