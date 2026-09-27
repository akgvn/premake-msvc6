# PLAN: Visual C++ 6.0 (vs6) exporter for Premake5

## Status: premake5-native, complete and validated

- `premake5 vs6` generates `.dsw`/`.dsp` for C/C++ projects, Win32 only.
  Layout: `_preload.lua` (action), `vs6.lua` (entry + shared helpers),
  `vs6_dsw.lua`, `vs6_dsp.lua`.
- Follows premake5-native conventions: baked build/link targets,
  premake5 defaults, msc toolset flag mappings (details in README.md).
  Began as a byte-exact premake 3.7 port — preserved at tag
  `v1.0-3x-parity`, migration spec `docs/3x-to-native.md`.
- 122 tests green via `bin/release/premake5 test --test-only=vs6*` from a
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

**Done (2026-09-24).** The battery against vs2005 + code review of
`_premake_init.lua`/`msc.lua`/vstudio found one bug and nine silently
dropped premake5 APIs, all fixed with tests (86 → 104 tests):

- **Bug:** `links "foo.lib"` emitted `foo.lib.lib`; now kept as-is, like
  `msc.getlinks()` (`.lib`/`.obj` extensions recognized).
- **Now mapped** (msc/vstudio equivalents): `undefines`→`/U`,
  `characterset`→defines, `syslibdirs`→`/libpath:` (after `libdirs`),
  `ignoredefaultlibraries`→`/nodefaultlib:`, `externalincludedirs` +
  `includedirsafter`→`/I` (after `includedirs`),
  `forceincludes`→`/FI`, `symbolspath`→`/pdb:` (symbols on, not c7),
  `mapfile`/`mapfilepath`→`/map[:file]`, `profile`→`/profile`.
- **Checked, no change needed:** `runtime`/`staticruntime` (matches
  `msc.lua getRuntimeFlag`), `symbols`/`debugformat`/`editandcontinue`
  (matches `vs200x_vcproj.symbols()`), `minimalrebuild`,
  `incrementallink`, `optimize`/`warnings`, `rtti`/`exceptionhandling`
  Default, per-config `kind` (oven), `toolset` (premake-core warns),
  `targetname`-with-path (oven). `cdialect`/`cppdialect` have no VC6
  equivalent (`/std:*` didn't exist) — documented in Step 4's matrix.

**Decision logged (would otherwise have asked; revisit if needed):**
`characterset "Default"` (premake5's global default) maps to
`/D "_UNICODE" /D "UNICODE"`, following `msc.lua`/`vs2010` exactly — the
module's stated convention is premake5-native mappings, and the D3
symbols re-baseline set the precedent that premake5 defaults win over
VC6-era idiom. Consequence: legacy ANSI code must opt out with
`characterset "MBCS"` (documented in README.md). The alternative
(rejected): Default → nothing, keeping VC6's ANSI norm but diverging
from every premake5 generator. Golden baseline regenerated for this.

Still-deferred premake5 data APIs without a defensible VC6 mapping:
PCH (`/Yu`/`/Yc` — `/YX` is the fixed idiom), single-flag enums
(`callingconvention`, `structmemberalign`, `stringpooling`,
`intrinsics`, `functionlevellinking`, `unsignedchar`, `compileas`,
`inlining`) — these are Step 4 coverage-matrix items, not divergences.


### Step 2 — gap-driven module features (from real-world analysis)

**Done (2026-09-24), 104 → 111 tests.** Findings from the survey, with
the resolution for each:

- **RSC locale** (Peter: `/l 0x405`, contiki: `/l 0x407`): turned out to
  need no module option — premake5's `locale` API (vstudio-registered,
  maps ISO locale ids to MS culture codes for vs2010's Culture element)
  fits exactly: `locale "cs-CZ"` → `/l 0x405`. The module now honors
  `cfg.locale`, default `0x409`; unknown locales warn (premake5's
  warnOnce) and fall back to the default.
- **Quoted `SOURCE=` for paths with spaces** (Peter's `Lucka 2.ico`):
  done — paths containing spaces are quoted, others stay bare (matches
  Peter's mixed usage; contiki quotes everything, both forms are
  accepted by VC6).
- **Logical file groups** (Peter's `Buffery`/`Editory`): done via
  premake5's `vpaths` — files are grouped by `fcfg.vpath`, which falls
  back to the physical relative path when no rule matches (so default
  output is unchanged). `Default_Filter` keeps emitting `""` (decided:
  no premake5 API, cosmetic only).
- **Per-file settings**: premake5's `excludefrombuild` (files: filter)
  now emits VC6's per-config `# PROP Exclude_From_Build 1` blocks for
  the excluded configurations only, in reversed config order, with
  VC6's trailing-space `!ENDIF ` (Peter's `ProgInit.inc`, quake2's
  ref_soft asm files). Per-file **custom build rules** (quake2's ml.exe
  blocks; premake5's fileconfig buildcommands/buildoutputs) are the
  remaining gap — deferred to Step 3 if the experiments justify it.
- **zlib's per-config kinds**: supported already (vs6_kinds.mixedKinds);
  validation against zlib's exact shape is part of Step 3.

### Step 3 — real-world generation experiments

- **Structural-diff tool:** `tools/dspdiff.py` strips VC-isms
  (system-lib lists, `# SUBTRACT`, `# ADD BASE`/`# PROP BASE`, `DEP_*`,
  `Ignore_Export_Lib 0`, `.\` prefixes, MTL `/o "NUL"`, `CFG=` (last-
  active IDE state), `Default_Filter` values, runtime tokens, `/GZ`,
  `/out:`, RSC merged defines, blank lines, flag order, file order) and
  diffs the premake-reachable remainder.
- **Peter (done 2026-09-24):** `experiments/peter/` reproduces all 9
  files; 7 are structurally identical, DataInst/Gener differ only in
  the documented gaps (custom BSC32 output name, empty groups). Three
  module bugs found and fixed (path-like links emitted absolute, `MTL=`
  on console apps, RSC debug-marker duplication). Details in
  `experiments/peter/NOTES.md`.
- **zlib (done 2026-09-24):** `experiments/zlib/` — 100% structural
  match (per-config kinds/target names, deps, per-config excludes,
  ml.exe custom builds, per-file `/I`). Drove the per-file custom-build
  + per-file CPP flags features; PCH (`/Yu`/`/Yc`) landed here too.
  See NOTES.md.
- **libpng (done 2026-09-24):** `experiments/libpng/` — dsw + pngtest
  match; libpng.dsp matches except the VB-config position artifact
  (premake5 has no removeconfigurations), embedded-quote RSC defines,
  and the original's own hand drift. See NOTES.md.
- **Quake 2 (surveyed, script not written):** findings in HANDOFF.md
  (per-project settings, the `/machine:ALPHA` gap, ref_soft asm custom
  builds). FLTK optional after that.

### Step 4 — VC6 build-option coverage (generation + Windows validation)

Goal: every VC6 build switch the module can emit is reachable from a
premake5 script, and every emitted combination is accepted by a real
VC6 toolchain. Where full coverage is impossible, document why.

1. **Coverage matrix.** Enumerate the VC6 flags the module emits and
   the premake5 API that reaches each. Anything without a dedicated
   mapping is either reachable through the
   `buildoptions`/`linkoptions`/`resoptions` escape hatches (say so) or
   gets a documented reason. PCH is implemented now (pchheader →
   `/Yu"hdr"`, pchsource → per-file `/Yc"hdr"`, enablepch "Off" →
   neither); the flag inventory below predates that. Starting point:

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
