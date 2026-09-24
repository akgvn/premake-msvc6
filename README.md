# premake5-vs6

A standalone [Premake5](https://premake.github.io) module adding a `vs6`
action that generates Visual C++ 6.0 workspace (`.dsw`) and project (`.dsp`)
files for C/C++ projects (Win32 only).

The module follows premake5-native conventions: baked build/link targets,
premake5 defaults, and the msc toolset's flag mappings. (It began as a
byte-exact port of premake 3.7's vs6 exporter — that state is preserved
at tag `v1.0-3x-parity`; see `docs/3x-to-native.md` for the migration
spec.) Validated to open and build correctly in a real Visual C++ 6.0 IDE.

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

End-to-end regression check: regenerates `samples/` output and diffs
against the committed baseline in `tests/golden/` (the module's own
output, regenerated deliberately — the old premake 3.7 oracle fixtures
live at tag `v1.0-3x-parity`):

```sh
tests/e2e.sh [path-to-premake5]
```

## Behavior notes

- **Targets and directories** are premake5's: `bin/<cfg>` default target
  dir, baked `objdir` (buildcfg appended on collision, `!`-prefix opts
  out), `implibdir`/`implibname` honored via `cfg.linktarget`.
- **Symbols** follow premake5: off by default; `symbols "On"` emits
  `/Zi` (or `/ZI` when edit-and-continue is legal, `/Z7` for
  `debugformat "c7"`), `/debug` and `/pdbtype:sept` on the linker.
- **Runtime library** follows `runtime`/`staticruntime` and premake5's
  debug-build rule (`/MDd`+`Use_Debug_Libraries 1`+`/GZ` for debug
  builds, `/MT(d)` for `staticruntime "On"`).
- **Entry point**: `/entry:` only when `entrypoint` is explicitly set.
- **Sibling links** become `.dsw` project dependencies (unioned across
  all configurations, plus `dependson`); other links are emitted as
  `name.lib`.
- **prebuildcommands** are folded into `PreLink_Cmds` ahead of
  `prelinkcommands` (VC6 has no pre-build step).
- **optimize/warnings** use the msc toolset's mappings (`On`→`/Ot`,
  `Speed`→`/O2`, `Size`→`/O1`, `Off`/`Debug`→`/Od`, `Full`→`/Ox`;
  `Off`→`/W0`, `Extra`/`High`/`Everything`→`/W4`).
- **characterset** follows the msc toolset's defines mapping — including
  premake5's `characterset "Default"` global default, which msc maps to
  `/D "_UNICODE" /D "UNICODE"`. Set `characterset "MBCS"` (`/D "_MBCS"`)
  or `characterset "ASCII"` (no define) for classic ANSI builds.
- **Other premake5 APIs** mapped to their VC6 equivalents: `undefines`
  (`/U`), `forceincludes` (`/FI`), `externalincludedirs`/
  `includedirsafter` (`/I`, after `includedirs`), `syslibdirs`
  (`/libpath:`, after `libdirs`), `ignoredefaultlibraries`
  (`/nodefaultlib:`), `symbolspath` (`/pdb:`), `mapfile`/`mapfilepath`
  (`/map[:file]`), `profile` (`/profile`), and `locale` (the resource
  compiler's `/l` LCID, e.g. `locale "cs-CZ"` → `/l 0x405`; default
  `0x409`). A `links` entry that already carries a library extension
  (`foo.lib`) is kept as-is.
- **Files**: `vpaths` rules drive the logical group tree (physical
  layout otherwise); `SOURCE=` paths containing spaces are quoted;
  `excludefrombuild` under a `files:` filter emits per-configuration
  `# PROP Exclude_From_Build 1` blocks for the excluded configurations.
- **Platforms**: anything other than Win32/x86 is rejected outright.
- Configurations are stored in reverse order in the `.dsp`, matching
  VC6's own layout.

## Layout

```
_preload.lua    action registration
_manifest.lua   file manifest
vs6.lua         module entry: p.modules.vs6, shared helpers
vs6_dsw.lua     workspace (.dsw) writer
vs6_dsp.lua     project (.dsp) writer
samples/        E2E sample (premake5 syntax)
tests/          test suites (_tests.lua), e2e.sh, golden/ baseline
docs/           design and migration notes
real-world-test-cases/  .dsw/.dsp files from public projects + provenance
```

## Notes

- Developed and tested against a current premake-core snapshot. The
  premake5 beta7 binary can also load the module (it dual-reads
  `flags {"NoImportLib"}` where `useimportlib` is unavailable), but that
  binary is a mid-transition dev build, so beta7 support is best-effort.
