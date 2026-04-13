# Third-Party Notices And License Compliance

This file summarizes the upstream projects and direct dependencies used by Proxmark Studio as of release `1.0.0` on April 12, 2026.

## Project License

Proxmark Studio source code is distributed under **GPL-3.0-only**. The full license text is included in `LICENSE`.

## Open-Source License Compliance

This project is released as open-source under the GNU General Public License v3.0 only. All third-party dependencies are appropriately credited below. We thank all upstream authors for their contributions to the free software ecosystem.

### Full Text of GPL-3.0-only

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 only.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Upstream Credits

### RfidResearchGroup / proxmark3

- **Project**: [RfidResearchGroup/proxmark3](https://github.com/RfidResearchGroup/proxmark3)
- **Upstream license**: GPL-3.0
- **License file**: [LICENSE.txt](https://github.com/RfidResearchGroup/proxmark3/blob/master/LICENSE.txt)
- **Use in this project**:
  - Command compatibility target for GUI actions
  - Optional local or embedded client/runtime source for private builds
  - Documentation and workflow references
- **Attribution**: Copyright (c) 2016-2024 RfidResearchGroup and contributors. Licensed under GPL-3.0.

### iceman1001 / proxmark3

- **Project**: [iceman1001/proxmark3](https://github.com/iceman1001/proxmark3)
- **Upstream license**: GPL-2.0
- **License file**: [LICENSE.txt](https://github.com/iceman1001/proxmark3/blob/master/LICENSE.txt)
- **Use in this project**:
  - Historical Iceman lineage reference
  - Device naming and user workflow context
- **Attribution**: Copyright (c) iceman1001 and contributors. Licensed under GPL-2.0.

### GameTec-live / ChameleonUltraGUI

- **Project**: [GameTec-live/ChameleonUltraGUI](https://github.com/GameTec-live/ChameleonUltraGUI)
- **Upstream license**: GPL-3.0
- **License file**: [LICENSE](https://github.com/GameTec-live/ChameleonUltraGUI/blob/main/LICENSE)
- **Use in this project**:
  - UI and layout inspiration only
  - No direct source copy is included in this repository
- **Attribution**: Copyright (c) GameTec-live. Licensed under GPL-3.0.

### Flutter SDK

- **Project**: [Flutter](https://github.com/flutter/flutter)
- **Upstream license**: BSD-style
- **Use in this project**: Cross-platform UI framework

For contributor links for upstream projects, see `CONTRIBUTORS.md`.

## Direct Flutter And Dart Dependencies

The following direct dependencies are declared in `pubspec.yaml` and locked in `pubspec.lock` for this release:

| Package | Version | License |
|---------|---------|---------|
| `intl` | 0.20.2 | BSD-style |
| `flutter_libserialport` | 0.6.0 | MIT |
| `libserialport` | 0.3.0+1 | LGPL-3.0 |
| `path_provider` | 2.1.5 | BSD-style |
| `path` | 1.9.1 | BSD-style |
| `http` | 1.6.0 | BSD-style |
| `archive` | 4.0.7 | MIT |
| `crypto` | 3.0.6 | BSD-style |
| `provider` | 6.1.5+1 | MIT |
| `file_selector` | 1.0.3 | BSD-style |

The Flutter SDK itself is distributed under a BSD-style license. Dependency license texts can be inspected in the local pub cache after running `flutter pub get`.

## Binary Distribution Policy

This source release intentionally does **not** ship compiled Proxmark3 client binaries.

If you distribute a future binary release that includes:

- an embedded Proxmark3 client
- a packaged PM3 runtime
- a release asset containing upstream PM3 object code

then you must also do all of the following:

- preserve upstream copyright and license notices
- provide the corresponding source in a compliant way for the shipped binary payload
- record the exact upstream source tag or commit in `assets/bundled/README.txt` and in the release notes
- update this file if the bundled source, license set, or dependency list changes

## No Warranty

Proxmark Studio and all referenced free-software components are provided **without warranty**, subject to their respective licenses.