# 📦 How to Include Pre-Installed Patches in the IPA

## Overview
You can bundle `.xpatch` files directly into the IPA so they appear automatically when users install the app.

---

## 🚀 Quick Guide

### Step 1: Add Your Patches
1. Place your `.xpatch` files in:
   ```
   ThreeOneOSFive/PreinstalledPatches/
   ```

2. Example:
   ```
   ThreeOneOSFive/PreinstalledPatches/
   ├── GameMod.xpatch
   ├── UITweak.xpatch
   └── CustomTheme.xpatch
   ```

### Step 2: Add to Xcode Project
1. Open `ThreeOneOSFive.xcodeproj` in Xcode
2. Right-click on `PreinstalledPatches` folder in the sidebar
3. Click **"Add Files to ThreeOneOSFive..."**
4. Select your `.xpatch` files
5. ✅ Check **"Copy items if needed"**
6. ✅ Select target: **"X"**
7. Click **Add**

### Step 3: Build the IPA
```bash
# Build with CodeMagic or locally
xcodebuild -project ThreeOneOSFive.xcodeproj \
  -scheme X \
  -configuration Release \
  -destination "generic/platform=iOS" \
  CODE_SIGNING_ALLOWED=NO \
  build
```

The patches will be embedded in `X.app/PreinstalledPatches/`

---

## 🎯 How It Works

### Automatic Installation
When a user opens the app for the **first time**:

1. ✅ App checks if preinstalled patches have been copied
2. ✅ Copies all `.xpatch` files from bundle to user's patch library
3. ✅ Patches appear immediately in the **Patches** tab
4. ✅ Works with encrypted/password-protected patches too

### Technical Details
- **Source:** `Bundle.main/PreinstalledPatches/*.xpatch`
- **Destination:** `Application Support/PatchProjects/*.xpatch`
- **Trigger:** `PreinstalledPatchLoader.installIfNeeded()` in `App.swift`
- **One-time:** Uses `UserDefaults` to track installation

---

## 📝 Notes

### Supported Formats
- ✅ `.xpatch` files (new format)
- ❌ `.3105` files (old format - rename to `.xpatch`)

### Patch Properties
- **Password-protected patches:** ✅ Supported
- **Encrypted patches:** ✅ Supported
- **Read-only:** Patches are installed as regular patches (users can apply/restore/delete)

### File Size
- Keep total size reasonable (< 50MB recommended)
- Large patches increase IPA size

### Updates
- If you release a new IPA with different patches:
  - Old patches remain (not deleted)
  - New patches are added
  - Duplicates are skipped (by filename)

---

## 🔧 Advanced: Reset Installation (Testing)

If you want to test re-installation during development:

```swift
// In debug builds, add this somewhere:
PreinstalledPatchLoader.resetInstallationFlag()
```

This forces patches to be re-copied on next launch.

---

## 🎨 Example Use Cases

### 1. Game Mods Bundle
```
ThreeOneOSFive/PreinstalledPatches/
├── UnlimitedCoins.xpatch
├── AllLevelsUnlocked.xpatch
└── CustomSkins.xpatch
```

### 2. System Tweaks
```
ThreeOneOSFive/PreinstalledPatches/
├── RemoveAds.xpatch
├── DarkMode.xpatch
└── PerformanceBoost.xpatch
```

### 3. App Themes
```
ThreeOneOSFive/PreinstalledPatches/
├── MinimalUI.xpatch
├── NeonTheme.xpatch
└── ClassicLook.xpatch
```

---

## ⚠️ Important

1. **Always test** the IPA before distributing
2. **Don't include** copyrighted content without permission
3. **Test patches** to ensure they work on target iOS versions
4. **Document** what each patch does for users

---

## 📱 User Experience

When users install your IPA:
1. Install app with ESign/Sideloadly
2. Open app
3. Go to **Patches** tab
4. ✅ Patches are already there!
5. Tap patch → Apply

No importing needed! 🎉

---

## Repository
https://github.com/bnxyung7/Ragex

## Developer
Bnxyung7
