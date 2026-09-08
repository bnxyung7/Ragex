# Preinstalled Patches

## How to include patches in the IPA:

1. **Place your .xpatch files in this folder**
   - Put all your patches here before building the IPA
   - Example: `MyPatch.xpatch`, `GameMod.xpatch`, etc.

2. **Add them to Xcode project**
   - In Xcode, right-click this folder → "Add Files to Project"
   - Make sure "Copy items if needed" is checked
   - Target membership: Select "X" target

3. **The app will auto-install them on first launch**
   - Patches are copied to the user's PatchProjects folder automatically
   - Users will see them in the Patches tab immediately

## Notes:
- Only .xpatch files are supported
- Encrypted/password-protected patches work too
- These patches are read-only until user exports them
