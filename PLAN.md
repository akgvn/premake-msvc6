# PLAN: Visual C++ 6.0 (vs6) exporter for Premake5

## Status: premake5-native, complete and validated

- `premake5 vs6` generates `.dsw`/`.dsp` for C/C++ projects, Win32 only.
  Layout: `_preload.lua` (action), `vs6.lua` (entry + shared helpers),
  `vs6_dsw.lua`, `vs6_dsp.lua`.
- Follows premake5-native conventions: baked build/link targets,
  premake5 defaults, msc toolset flag mappings (details in README.md).
  Began as a byte-exact premake 3.7 port — preserved at tag
  `v1.0-3x-parity`, migration spec `docs/3x-to-native.md`.
- 86 tests green via `bin/release/premake5 test --test-only=vs6*` from a
  premake-core checkout with this repo linked into
  `premake-core/modules/vs6`; full premake-core suite passes.
  `tests/golden/` is the module's own sample output (regression
  baseline); `tests/e2e.sh` diffs against it with separator/EOL
  normalization.
- Validated on Windows (2026-09-22): Sample.dsw opens clean in a real
  VC6 IDE and builds end-to-end (dependencies and build events working);
  beta7 spot-check byte-identical. The `/ZI /O2` illegality found in the
  old 3.x-parity output was a premake 3.7 oracle bug; native mode emits
  `/Zi` with optimization.
- `real-world-test-cases/` holds 310 .dsw/.dsp files from 13 public
  projects (provenance in each SOURCE.md) for Steps 2–3.

## Next steps (in order)

### Step 1 — investigate for remaining divergences from premake5-native conventions

The known divergences are all landed; this step hunts for more. Fix any
found, with tests. Suggested procedure:

- For a battery of small scripts (each kind, with/without each common
  setting), generate with vs6 and with a premake5-native generator
  (vstudio vcxproj and/or gmake) and diff the *semantics*: output
  locations, defaults, naming. Every place the module's behavior differs
  from premake5's own conventions is a candidate fix.
- Read the defaults in premake-core's `src/_premake_init.lua` (system
  filters, `symbols "Default"`, `rtti "Default"`,
  `exceptionhandling "Default"`, `characterset "Default"`, …) and check
  each against the module's mapping.
- Check premake5 APIs the module maps loosely or ignores: `runtime`
  (Debug/Release) vs `staticruntime`, `characterset`, `cdialect`/
  `cppdialect`, `toolset` variations, per-config `kind` interactions
  with the baked `cfg.buildtarget`, `incrementallink`,
  `editandcontinue`, `debugformat`, `minimalrebuild`.

### Step 2 — gap-driven module features (from real-world analysis)

From the real-world-test-cases survey (details in each SOURCE.md):

- **RSC locale** (Peter: `/l 0x405`): the module hardcodes `0x409`. No
  premake5 API fits; add a module option (e.g. `vs6.rsclocale`) —
  decide spelling when implementing.
- **Quoted `SOURCE=` for paths with spaces** (Peter's `Lucka 2.ico`,
  Generals' `Autorun English.dsp`): quote SOURCE paths containing
  spaces. Verify VC6 accepts unquoted too (it doesn't reliably) — this
  is arguably a bug fix, not a feature.
- **Logical file groups** (Peter's `Buffery`/`Editory` groups): the
  module groups by path only; premake5 `vpath` could drive logical
  groups. `Default_Filter` values have no premake5 API — decide whether
  to keep emitting `""`.
- **Per-file settings** (`Exclude_From_Build`, Peter's `ProgInit.inc`):
  check premake5 fileconfig capabilities and decide if real-world usage
  justifies it.
- **zlib's per-config kinds** (DLL and LIB configs in one .dsp): we
  support per-config kind already (vs6_kinds.mixedKinds); validate
  against zlib's exact shape during experiments.

### Step 3 — real-world generation experiments

- Write a structural-diff tool that strips VC-isms (system-lib lists,
  `# SUBTRACT`, `DEP_CPP_`, `Ignore_Export_Lib 0`, `.\` prefixes, MTL
  `/o "NUL"`) and compares only the premake-reachable parts of a .dsp —
  full-file diffs are too noisy to be useful.
- Then, in order: Peter (8 projects, the stated target), zlib/libpng
  (small, deps, per-config kinds), FLTK/Quake 2 (scale). Each experiment
  produces a premake5 script + a gap list feeding Step 2.

### Step 4 — VC6 build-option coverage (generation + Windows validation)

Goal: every VC6 build switch the module can emit is reachable from a
premake5 script, and every emitted combination is accepted by a real
VC6 toolchain. Where full coverage is impossible, document why.

1. **Coverage matrix.** Enumerate the VC6 flags the module emits and
   the premake5 API that reaches each. Anything without a dedicated
   mapping is either reachable through the
   `buildoptions`/`linkoptions`/`resoptions` escape hatches (say so) or
   gets a documented reason (e.g. PCH `/Yu`/`/Yc` — premake5's pch APIs
   exist but the module doesn't implement them yet). Starting point:

   - Compiler: `/nologo` (fixed), `/MD(d)`/`/MT(d)` (staticruntime +
     runtime/isDebugBuild), `/W0`/`/W3`/`/W4` (warnings), `/WX`
     (fatalwarnings), `/Gm` (minimalrebuild), `/GR` (rtti), `/GX`
     (exceptionhandling), `/ZI`/`/Zi`/`/Z7` (symbols + editandcontinue +
     debugformat + the optimize legality rule), `/Od`/`/Ot`/`/O2`/`/O1`/
     `/Ox` (optimize), `/Oy` (omitframepointer), `/GZ` (debug runtime),
     `/I` (includedirs), `/D` (defines), `/YX` `/FD` `/c` (fixed),
     + buildoptions.
   - Linker: `/nologo` (fixed), `/entry` (entrypoint),
     `/subsystem:console|windows`, `/dll` (kind), `/debug` (symbols),
     `/incremental:yes|no` (incrementallink), `/machine:I386` (fixed),
     `/implib` (linktarget, absent with useimportlib Off), `/out`
     (buildtarget), `/pdbtype:sept` (symbols), `/libpath` (target dir +
     libdirs), + linkoptions; LIB32 `/nologo` + `/out` (StaticLib).
   - RSC: `/l 0x409` (fixed — locale option is Step 2), `/d` (defines +
     resdefines + debug symbol), `/i` (includedirs + resincludedirs),
     + resoptions.

2. **Combinatoric generation tests.** Add a `vs6_coverage` suite that
   programmatically walks the reachable option space and asserts the
   module emits the expected CPP/RSC/LINK32/LIB32 lines per
   combination — including the legality rules (`/ZI`→`/Zi` under
   optimization, `/GZ` only with the debug runtime, `/implib` absent
   with `useimportlib "Off"`, …). Use pairwise coverage (or a
   documented structured subset), not exhaustive enumeration — the
   full cross-product is in the thousands; record which and why.

3. **Windows acceptance run.** Generate the same combinations as .dsp
   files and compile a trivial source under each with the real VC6
   toolchain (`VC98\Bin\VCVARS32.BAT` + `cl.exe`/`link.exe` directly,
   or `msdev /MAKE` on generated projects). Record accepted/rejected
   per combo. Any combination VC6 rejects must be either avoided by the
   module (fix) or documented with the reason.

Deliverables: the coverage matrix + the `vs6_coverage` suite + the
Windows acceptance log, all committed.

## Reference material

- `tests/golden/` — the module's own output for the sample (CRLF,
  `-text` in .gitattributes); regenerate deliberately from module
  output and review the diff. The premake 3.7 oracle fixtures live at
  tag `v1.0-3x-parity`.
- `real-world-test-cases/` — 310 files from 13 projects (see its
  README.md); not byte-parity targets.
- `../premake-sources/` can be deleted; a premake-core checkout is still
  needed to run the unit tests (see README).

## Implementation notes (load-bearing for future edits)

- External-module flow: the action registers during `runUserScript`,
  after `prepareAction`, so `_preload.lua` re-runs `p.action.set("vs6")`
  at load to apply `targetos`/`toolset` before baking (otherwise POSIX
  target naming leaks in: `libengine.so`).
- Output locations come from the oven: `cfg.buildtarget`/
  `cfg.linktarget` (absolute — re-relativize with
  `p.project.getrelative`) and baked `cfg.objdir`. Path lists
  (`includedirs`/`libdirs`/`resincludedirs`) also come back absolute.
- `p.generate` captures via `buffered.tostring()`, which trims one
  trailing EOL; both writers emit one extra blank line to compensate.
- `prj._.files` is alpha-sorted by vpath; the source tree restores
  script declaration order via `fcfg.order`, and is the union across
  configs (premake5-native).
- Line endings are `p.eol("\r\n")` + `p.indent("")` set in
  onWorkspace/onProject; all output goes through `p.out`/`p.outln` with
  literal leading whitespace.
- `p.generate` writes to `prj.filename` (not `prj.name`); the .dsw
  writer references `prj.filename` (Peter's Loader/Loader0 both produce
  Peter.dsp in different directories).
