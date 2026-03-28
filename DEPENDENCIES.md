# Dependencies

## Build Requirements

- Flutter 3.38.9
- Dart 3.10.8
- macOS arm64 build validation was performed with Xcode command line tools installed

## Runtime Requirement For Hardware Workflows

- A working Proxmark3 client build (`pm3` or `proxmark3`)
- Matching `share/proxmark3` runtime data when the imported client expects it

## Direct Flutter And Dart Packages

- `intl 0.20.2` — formatting timestamps and human-readable labels
- `flutter_libserialport 0.6.0` — serial-port access bridge
- `libserialport 0.3.0+1` — native serial runtime
- `path_provider 2.1.5` — application-support and temp-directory access
- `path 1.9.1` — safe path handling
- `http 1.6.0` — release feed and asset download requests
- `archive 4.0.7` — release archive extraction
- `crypto 3.0.7` — SHA-256 verification
- `provider 6.1.5+1` — app state wiring
- `file_selector 1.1.0` — native open-file dialogs

## Common Commands

```bash
/opt/homebrew/share/flutter/bin/flutter pub get
/opt/homebrew/share/flutter/bin/flutter analyze
/opt/homebrew/share/flutter/bin/flutter test
/opt/homebrew/share/flutter/bin/flutter build macos --debug
```
