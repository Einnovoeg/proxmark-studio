# Changelog

All notable changes to this project are documented in this file.

## [1.0.0] - 2026-04-12

### Added

- Complete Proxmark Studio application with full feature set:
  - Local card library with save, import, and slot assignment workflows
  - Live PM3 console with command entry and chaining support
  - HF/LF/EMV scan modes (single and continuous)
  - Write plan management per saved card
  - Core management: import, download, and validation of PM3 binaries
  - Responsive desktop UI with hover tooltips throughout
- Security hardening:
  - URL validation for GitHub release downloads
  - Path validation preventing archive traversal attacks
  - Checksum verification for downloaded cores
  - Trusted-path enforcement for executable resolution
  - Safe external link handling
- Full documentation:
  - README.md with installation and usage instructions
  - USER_GUIDE.md with detailed workflows
  - THIRD_PARTY_NOTICES.md with upstream credits and license compliance
  - DEPENDENCIES.md with build/runtime requirements
  - CONTRIBUTORS.md with upstream project references
  - CHANGELOG.md with release history

### Changed

- Updated version to 1.0.0
- Unified app identifiers to neutral `io.proxmarkstudio.app` naming
- Added Buy Me a Coffee support link

### Fixed

- Security validation hardening for all download and extraction paths
- Rejected broken or untrusted PM3 clients before launch
- Fixed controller lifecycle cleanup in console tools
- Removed stale personal and unrelated project references

### Known Issues And Limitations

- The source repository does not ship a bundled Proxmark3 client binary
- Users must import or download a working PM3 client for hardware access
- Online update/download requires a configured official release feed
- Some advanced PM3 commands may require manual console entry
- Continuous scan mode requires stable USB connection

## [0.2.0] - 2026-03-28

### Added

- Real saved-card slot assignment and write-plan workflows
- Hover tooltips across the desktop UI
- `DEPENDENCIES.md` with build and runtime requirements
- Hardened security helpers and regression tests for archive, URL, and path validation

### Changed

- Unified app versioning to `0.2.0`
- Updated app identifiers to neutral `io.proxmarkstudio.app` naming
- Reworked the write planner to persist commands per saved card
- Improved onboarding, settings, and console ergonomics
- Documented third-party credits, licensing, release notes, and installation steps

### Fixed

- Replaced dead placeholder actions in slot and write screens with real state-driven behavior
- Rejected broken embedded or imported PM3 clients before launch
- Fixed controller lifecycle cleanup in the console tools page
- Removed stale personal and unrelated project references from tracked files

### Removed

- Tracked bundled Proxmark3 runtime payloads from the source release
- Stale legacy-source references that no longer matched the repository contents