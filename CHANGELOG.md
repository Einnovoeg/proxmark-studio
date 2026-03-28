# Changelog

All notable changes to this project are documented in this file.

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
