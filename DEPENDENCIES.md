# Dependencies

Build and runtime dependencies for Proxmark Studio v1.0.0.

## Build Requirements

- **Flutter SDK**: 3.38.9 or newer on the stable channel
- **Dart SDK**: 3.10.8 or newer
- **Xcode command line tools** (macOS)
- **CocoaPods** (macOS)

## Runtime Requirements

- **macOS** (validated on arm64), **Linux**, or **Windows**
- **Proxmark3 hardware** (for live device workflows)
- **Working PM3 client binary** (`pm3` or `proxmark3`)

## Direct Flutter And Dart Packages

The following packages are declared in `pubspec.yaml` and resolved by `flutter pub get`:

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Cross-platform UI framework |
| `intl` | 0.20.2 | Internationalization and date formatting |
| `flutter_libserialport` | 0.6.0 | Flutter wrapper for serial port access |
| `libserialport` | 0.3.0+1 | Native cross-platform serial port library |
| `path_provider` | 2.1.5 | Platform-specific storage paths |
| `path` | 1.9.1 | Path manipulation utilities |
| `http` | 1.6.0 | HTTP client for GitHub API and releases |
| `archive` | 4.0.7 | ZIP/TAR extraction for PM3 core bundles |
| `crypto` | 3.0.6 | SHA256 checksum verification |
| `provider` | 6.1.5+1 | InheritedWidget-based state management |
| `file_selector` | 1.0.3 | Native file picker dialogs |

## Development Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Built-in Flutter testing framework |
| `flutter_lints` | 6.0.0 | Static analysis linting rules |

## Common Commands

```bash
# Get all dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run tests
flutter test

# Build for macOS (debug)
flutter build macos --debug

# Build for macOS (release)
flutter build macos --release

# Build for Linux
flutter build linux --release

# Build for Windows
flutter build windows --release
```

## Proxmark3 Client Setup

Proxmark Studio does not include a PM3 client binary. Set up one of:

1. **Import local binary**: Build [RfidResearchGroup/proxmark3](https://github.com/RfidResearchGroup/proxmark3) and import via the app
2. **System installation**: Install via Homebrew (macOS) or system package manager
3. **Download from releases**: Use the in-app download feature (when configured)

### macOS Homebrew Installation

```bash
brew install proxmark3
```

This installs to `/opt/homebrew/opt/proxmark3/bin/pm3`.