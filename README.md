# Proxmark Studio

Proxmark Studio is a Flutter desktop GUI for Proxmark3 workflows. It gives you a local card library, slot assignment workspace, read tools, write-plan management, and a live PM3 console in one desktop app.

## Release Status

- Validated on macOS arm64 with Flutter 3.38.9 / Dart 3.10.8.
- The source repository does not ship a bundled Proxmark3 client in this release.
- Invalid embedded or imported PM3 binaries are rejected at launch instead of being treated as healthy.
- Online update/download actions are enabled only in builds configured with official release-feed metadata.

## Features

- Core management:
  - Import a local `pm3` or `proxmark3` client build
  - Download stable or experimental cores from an official release feed when configured
  - Reject broken or untrusted binaries before launch
- Device workflow:
  - Serial-port discovery with Iceman-style port preference
  - Connect/disconnect controls
  - HF, LF, continuous, and EMV scan actions
- Card workflow:
  - Save reads into a local card library
  - Import saved-card metadata from files
  - Assign cards to eight slots
  - Build and persist PM3 write plans per saved card
- Advanced workflow:
  - Live console output
  - Manual PM3 command entry
  - Advanced command chaining
- UI polish:
  - Responsive desktop layout
  - Hover tooltips for interactive controls

## Install And Run

### Prerequisites

- Flutter 3.38.9 or newer on the stable channel
- Dart 3.10.8 or newer
- macOS build validation was performed with Xcode command line tools installed
- A working Proxmark3 client build when you want live hardware access

### Development Build

```bash
/opt/homebrew/share/flutter/bin/flutter pub get
/opt/homebrew/share/flutter/bin/flutter run -d macos
```

### macOS Debug Build

```bash
/opt/homebrew/share/flutter/bin/flutter build macos --debug
```

## Core Setup

1. Build or install a working Proxmark3 client.
2. In Proxmark Studio, use `Core Options -> Install Local Core` or `Settings -> Import core binary`.
3. If you import the `pm3` wrapper, keep the matching `proxmark3` binary and `share/proxmark3` data beside it.
4. The app validates imported clients with `pm3 --helpclient` or `proxmark3 -h` before trusting them.

If you want to prepare a redistributable embedded core for a private build, use `tools/bundle_core.sh` and then record the exact upstream source tag or commit in `assets/bundled/README.txt` before distributing binaries.

## Documentation

- User workflow and troubleshooting: `USER_GUIDE.md`
- Third-party notices and compliance notes: `THIRD_PARTY_NOTICES.md`
- Build and runtime dependencies: `DEPENDENCIES.md`
- Release history: `CHANGELOG.md`
- Upstream credits: `CONTRIBUTORS.md`
- Embedded-core bundling notes: `tools/README.md`

## Support

- Buy me a coffee: [buymeacoffee.com/einnovoeg](https://buymeacoffee.com/einnovoeg)

## License

Proxmark Studio is licensed under the GNU General Public License v3.0 only.

See `LICENSE` for the full license text and `THIRD_PARTY_NOTICES.md` for dependency and upstream attribution details.
