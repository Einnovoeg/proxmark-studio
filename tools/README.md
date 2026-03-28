# Proxmark Studio Tooling

## Bundle A Core For A Private Release

Run this after building or installing a working Proxmark3 client:

```bash
./tools/bundle_core.sh /path/to/pm3
```

You can also point it at an install prefix:

```bash
./tools/bundle_core.sh /path/to/proxmark/install/prefix
```

The script copies:

- `bin/pm3`
- `bin/proxmark3` when present
- `share/proxmark3` when present

It now validates the copied client by running `pm3 --helpclient` or `proxmark3 -h`. If validation fails, the bundling step stops instead of shipping a broken runtime.

## Compliance Note

This repository does not track bundled PM3 binaries in the source release.

If you add bundled binaries for a private or published release:

1. record the exact upstream source tag or commit in `assets/bundled/README.txt`
2. keep `THIRD_PARTY_NOTICES.md` in sync
3. make the corresponding source available in a license-compliant way
