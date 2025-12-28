# Launch Agent Installation Guide

## Overview
This guide explains how to configure Sight to auto-start when you log in to your Mac.

## Automatic Installation (Recommended)

The app will prompt on first launch:
"Would you like Sight to start automatically when you log in?"

Click **Allow** to enable auto-start.

---

## Manual Installation

If you need to manually install the launch agent:

### 1. Copy Launch Agent File

```bash
cp /Applications/Sight.app/Contents/Resources/com.kumargaurav.Sight.plist \
   ~/Library/LaunchAgents/
```

### 2. Load Launch Agent

```bash
launchctl load ~/Library/LaunchAgents/com.kumargaurav.Sight.plist
```

### 3. Verify Installation

```bash
launchctl list | grep com.kumargaurav.Sight
```

You should see the agent listed.

---

## Uninstallation

To disable auto-start:

### 1. Unload Launch Agent

```bash
launchctl unload ~/Library/LaunchAgents/com.kumargaurav.Sight.plist
```

### 2. Remove File

```bash
rm ~/Library/LaunchAgents/com.kumargaurav.Sight.plist
```

---

## Troubleshooting

### App Not Starting on Login

1. Check if launch agent is loaded:
   ```bash
   launchctl list | grep Sight
   ```

2. Check logs for errors:
   ```bash
   cat /tmp/com.kumargaurav.Sight.err
   ```

3. Verify app path:
   ```bash
   ls /Applications/Sight.app/Contents/MacOS/Sight
   ```

### Disable via System Settings

macOS Ventura+:
1. System Settings → General → Login Items
2. Find "Sight" in the list
3. Toggle off or remove

---

## Launch Agent Configuration

The launch agent (`com.kumargaurav.Sight.plist`) is configured with:

- **RunAtLoad**: `true` - Starts when you log in
- **KeepAlive**: `false` - Won't auto-restart if quit
- **ProcessType**: `Interactive` - Runs in user session
- **SessionType**: `Aqua` - GUI apps only

This ensures Sight starts automatically but respects user quit actions.
