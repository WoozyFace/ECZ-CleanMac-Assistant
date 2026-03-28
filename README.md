# CleanMac Assistant

CleanMac Assistant is EasyComp Zeeland's free Mac maintenance project. This repository contains both the original AppleScript edition and the newer native macOS SwiftUI app source.

## Repository Layout

- `native-app/`
  The native SwiftUI app source, resources, packaging script, and Xcode support files.
- `Cleanmacassistent(NL).AppleScript`
  The original Dutch AppleScript version.
- `Cleanmacassistent(EN).AppleScript`
  The original English AppleScript version.

## Native App

The native app is built as a Swift package and includes:

- a sidebar-driven SwiftUI interface
- multilingual UI support based on the system language
- developer-only preview tooling behind `DEVELOPER_BUILD`
- packaging support for `.app` and `.dmg` output through `native-app/tools/package-macos.sh`

Start with `native-app/README.md` for setup and packaging details.

## Build Artifacts

Release artifacts such as `.app` bundles and `.dmg` installers are intentionally not committed to Git. Upload those separately to the download repository or release hosting location.

## Website

- Public site: https://cleanmac-assistant.easycompzeeland.nl
- Support: https://easycompzeeland.nl/en/services/hulp-op-afstand

## License

This project is licensed under the MIT License. See `LICENSE`.
