# Xcode Support

Use this folder when you want to turn the Swift package into a full macOS app target inside Xcode.

## Recommended setup

1. Create a new macOS App project in Xcode.
2. Copy the Swift files from `native-app/Sources/CleanMacAssistantNative/` into the new target.
3. Replace the target's default asset catalog with `native-app/XcodeSupport/Assets.xcassets`.
4. Set the app icon to `AppIcon` in the target settings if Xcode does not pick it automatically.
5. Disable App Sandbox for the target if you want shell tasks, Terminal automation, and administrator prompts to work.

## Two-app setup

If you want a separate public app and an internal preview build, use two Xcode targets:

1. Create your normal target: `CleanMac Assistant`
2. Duplicate it as: `CleanMac Assistant Developer`
3. Give the developer target its own bundle identifier, for example: `nl.easycompzeeland.cleanmac-assistant.dev`
4. Set the developer target display name to something obvious such as: `CleanMac Assistant Dev`
5. Add `DEVELOPER_BUILD` to `Other Swift Flags` for the developer target, or define it in that target's Swift compiler custom flags
6. Do not define `DEVELOPER_BUILD` for the release target

What this does in code:

- `DEVELOPER_BUILD` enables the preview tools, placebo mode, developer menu, and live language switching
- the app window title and version label clearly identify the developer build
- the release target stays clean and does not ship those temporary controls

## Why this folder exists

- `Assets.xcassets` contains the generated app icon set from the existing CleanMac Assistant artwork.
- The package itself is enough to build and test the native UI.
- A dedicated Xcode app target is the better route when you want a polished `.app` bundle, signing, archive builds, and a real Dock icon.
