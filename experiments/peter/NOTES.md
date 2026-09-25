# Peter experiment (Step 3)

Goal: reproduce `real-world-test-cases/peter` (Peter.dsw + 8 .dsp) from a
premake5 script with the vs6 module, and harvest the gap list.

`premake5.lua` reproduces the workspace; `run.sh` generates into a
shadow tree (`build/`, git-ignored) and diffs each file against the
original with `tools/dspdiff.py`.

## Result

7 of 9 files are **structurally identical** to the VC-authored
originals (Peter.dsw, Peter.dsp, DelExe, Loader, Loader0, Pov2Spr,
Setup). The remaining two differ only in the known gaps below.

Era-accurate script choices: `characterset "ASCII"` (VC6-era projects
carry no charset define; premake5's Default would add _UNICODE defines),
`locale "cs-CZ"` (RSC `/l 0x405`), explicit `_DEBUG`/`NDEBUG` defines
(VC6 wizards put them on the CPP line), `/G4` `/Zp4` via `buildoptions`
(no dedicated mapping yet — Step 4), `/ML` via `buildoptions` (Setup's
Debug Demo; premake5 cannot express the single-threaded runtime, and the
module still emits its own `/MDd` alongside — cl takes the last one).

## Gaps found (all confirmed by the structural diff)

1. **PCH** (Gener): premake5's `pchheader`/`pchsource` have no module
   mapping — VC6's `/Yu"stdafx.h"` per config and per-file
   `/Yc"stdafx.h"` on the PCH source. The module emits its fixed `/YX`
   idiom instead. (Known from Step 4's starting list.)
2. **Per-file compiler flags** (Gener's StdAfx.cpp `/Yc`): the module
   has no per-file flag support at all. premake5's fileconfig mechanism
   (filter `files:`) would allow it; real-world usage so far is PCH
   creation only.
3. **Custom BSC32 output** (DataInst `/o"Release/Setup.bsc"`): no
   premake5 API for bscmake options. Cosmetic (browser database name).
4. **Empty groups** (Gener's empty "Resource Files"): the module only
   emits groups that contain files. Cosmetic.
5. **Per-file custom build rules** (not present in Peter; quake2's
   ml.exe steps): fileconfig `buildcommands`/`buildoutputs` — deferred
   from Step 2, still open.

## Module bugs fixed as a result of this experiment

- Path-like `links` entries (`"lib/tran.lib"`) were emitted as absolute
  paths (the oven absolutizes them); the module now re-relativizes and
  backslash-translates them (test vs6_links.linksWithPath).
- `MTL=midl.exe` was emitted for every non-StaticLib project; VC-authored
  console apps don't carry it. Now emitted only for WindowedApp/SharedLib,
  matching the MTL `# ADD` block condition.
- The RSC line's automatic `_DEBUG`/`NDEBUG` marker is now skipped when
  the script already defines it (VC6-parity scripts define their own).

## Notes on normalized-away differences (tools/dspdiff.py)

- `CFG=` names the config that was active when the IDE last saved — user
  state, not structure (Gener: `CFG=Debug` with `!IF Release`; zlib:
  `CFG=LIB Debug` with `!IF DLL Release`). The module deterministically
  uses the first declared configuration.
- `Default_Filter` values, `/M*` runtime selection (VC6-era files often
  use the compiler default; premake5 always selects one), `/GZ` (module
  emits it for every debug-runtime config; corpus varies), `/out:`
  (module always emits; VC6 omits when default), the AppWizard default
  library list, `# SUBTRACT`/`# ADD BASE`/`# PROP BASE`/`DEP_*` lines,
  `Ignore_Export_Lib 0`, `.\` prefixes, MTL `/o "NUL"`, blank lines, and
  flag order within `# ADD` lines are all normalized away.
- RSC `# ADD` lines drop defines that duplicate the config's CPP defines
  (vs2010-style define merge vs VC6 wizard separation — the module
  follows premake5's merge, by design; scripts express RSC-only defines
  via `resdefines`).
- File declaration order within groups is sorted before comparison
  (cosmetic; premake5 globbing and VC6 ordering differ).
