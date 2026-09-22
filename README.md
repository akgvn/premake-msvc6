# premake5-vs6

A standalone [Premake5](https://premake.github.io) module adding a `vs6`
action that generates Visual C++ 6.0 workspace (`.dsw`) and project (`.dsp`)
files for C/C++ projects (Win32 only).

It is a faithful port of the premake 3.7 `vs6` exporter: the generated
files match premake 3.x output byte-for-byte (modulo path separators and
line endings, see below), including its default directory semantics and
quirks — *not* premake5-native conventions.

Licensed under GPLv2, since the code is based on premake 3.x
(`Src/vs6.c`, `Src/vs6_cpp.c`).

## Usage

Point Premake at the module and require it from your script:

```lua
require "vs6"

workspace "Sample"
	configurations { "Debug", "Release" }
	project "app"
		kind "ConsoleApp"
		language "C++"
		files { "app/main.cpp" }
```

```sh
premake5 --scripts=/path/to/premake5-vs6 vs6
```

(`--scripts` adds this repository to Premake's module search path; any
other module search path works too, e.g. copying or linking this repo to
`%USERPROFILE%\.premake\modules\vs6` / `~/.premake/modules/vs6`.)

This produces `Sample.dsw` and one `.dsp` per project. Generated files
always use CRLF line endings and backslash path separators, regardless of
host OS.

## Testing

Unit tests use premake5's built-in test harness. Link this repository
into a [premake-core](https://github.com/premake/premake-core) checkout
(one-time), then run from that checkout:

```sh
ln -s /path/to/premake5-vs6 modules/vs6
bin/release/premake5 test --test-only=vs6*
```

End-to-end validation regenerates `samples/` and diffs against the
committed premake 3.7 oracle fixtures in `tests/golden/` (normalizing
path separators and line endings):

```sh
tests/e2e.sh [path-to-premake5]
```

## Deliberate 3.x-parity behaviors

These diverge from premake5-native defaults on purpose, to stay
byte-compatible with the premake 3.7 oracle (see PLAN.md):

- **Directories**: unset `targetdir` means `.` (not `bin/<cfg>`); the
  configuration name is always appended to `objdir` (default `obj`, so
  `obj/Debug`). The 3.x `libdir` maps to `targetdir` for
  executables/static libraries and to `implibdir` for DLL import
  libraries.
- **Symbols**: debug symbols are *on* unless `symbols "Off"` (3.x
  default), emitting `/ZI`, `/incremental:yes /debug` and `/pdbtype:sept`.
- **Entry point**: executables get `/entry:"mainCRTStartup"` unless
  `entrypoint` is set (`entrypoint ""` suppresses it).
- **Sibling links**: `links` naming a sibling project become `.dsw`
  project dependencies only (VC6 links them implicitly); other links are
  emitted as `name.lib`.
- **Configurations** are stored in reverse order in the `.dsp`, and the
  `Use_Debug_Libraries` state of each block is taken from the *next*
  configuration — an off-by-one quirk of premake 3.7, reproduced for
  oracle parity.
- **Ignored with a warning**: `prebuildcommands` (VC6 has no pre-build
  step), `dependson`, and premake5-only `optimize`/`warnings` values
  (fall back to the 3.x defaults).
- **Platforms**: anything other than Win32/x86 is rejected outright.

## Layout

```
_preload.lua    action registration
_manifest.lua   file manifest
vs6.lua         module entry: p.modules.vs6, shared helpers
vs6_dsw.lua     workspace (.dsw) writer
vs6_dsp.lua     project (.dsp) writer
samples/        E2E sample (premake 3.x + premake5 syntax)
tests/          test suites (_tests.lua), e2e.sh, golden/ fixtures
```

## Notes

- Developed and tested against a current premake-core snapshot. The
  premake5 beta7 binary can also load the module (it dual-reads
  `flags {"NoImportLib"}` where `useimportlib` is unavailable), but that
  binary is a mid-transition dev build, so beta7 support is best-effort.
