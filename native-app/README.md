# CleanMac Assistant Native

This folder contains a real macOS SwiftUI front-end for CleanMac Assistant.

## What it does

- Presents the maintenance routines as native modules in a sidebar.
- Gives each task a richer card with impact labeling, notes, and run controls.
- Runs the existing maintenance commands through a Swift task executor.
- Uses native confirmation and input alerts for destructive actions such as uninstalling apps or removing launch agents.

## Opening it

1. Open `native-app/Package.swift` in Xcode.
2. Let Xcode index the package and expose the `CleanMacAssistantNative` executable target.
3. Press Run. The SwiftUI shell builds and launches as a native macOS window.

## Developer vs release

- Debug builds now compile with a dedicated `DEVELOPER_BUILD` flag.
- Release builds do not include the preview tools, placebo mode, live language switch, or other developer-only UI.
- In the package-run flow, the Debug app presents itself as `CleanMac Assistant Dev` so it is easy to tell apart from the clean release-facing build.
- If you want two separate `.app` bundles side by side, use the Xcode app-target route described in `native-app/XcodeSupport/README.md`.

## Local packaging

- Run `tools/package-macos.sh` to generate both `.app` bundles and both `.dmg` files locally.
- The script outputs to `native-app/dist/apps/` and `native-app/dist/dmg/`.
- By default the script uses ad-hoc signing for local testing.
- For website-ready distribution, rerun it with `SIGN_IDENTITY` and `NOTARY_PROFILE` so the exported DMGs can be signed and notarized.

## Build status

- Verified with Xcode's toolchain on March 26, 2026 using `swift build`.
- The package currently compiles cleanly.
- A brand asset is bundled through SwiftPM resources so the UI does not rely only on SF Symbols.

## Xcode path

- If you want the fastest route, keep using the package directly in Xcode.
- If you want a fully branded `.app` target with Dock icon and signing settings, use the files in `native-app/XcodeSupport/` when creating a new macOS App project in Xcode.
- Disable App Sandbox for that app target if you want maintenance commands, Terminal launch, and admin prompts to keep working as expected.

## Notes

- The legacy AppleScript files are still kept in the repository.
- This native shell is meant to replace the old dialog-driven feel with a proper Mac app workflow.
- Commands that touch protected locations may still require Full Disk Access or admin approval on the Mac where the app runs.
