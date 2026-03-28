This source release intentionally ships no compiled Proxmark3 client.

If you create a private bundled build, place the generated payload under this
directory with a platform and architecture layout such as:

- bundled/macos/arm64/bin/pm3
- bundled/macos/arm64/bin/proxmark3
- bundled/macos/arm64/share/proxmark3/...

Before distributing any bundled runtime, record all of the following here:

- upstream project name
- exact source tag or commit
- build date
- platform and architecture
- applicable upstream license
- where recipients can obtain the corresponding source

The application validates bundled clients before trusting them at runtime.
