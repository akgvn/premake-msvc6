# PLAN: Visual C++ 6.0 (vs6) exporter for Premake5

## Status: premake5-native, complete and validated

- `premake5 vs6` generates `.dsw`/`.dsp` for C/C++ projects, Win32 only.
  Layout: `_preload.lua` (action), `vs6.lua` (entry + shared helpers),
  `vs6_dsw.lua`, `vs6_dsp.lua`.
- Follows premake5-native conventions: baked build/link targets,
  premake5 defaults, msc toolset flag mappings (details in README.md).
  Began as a byte-exact premake 3.7 port — preserved at tag
  `v1.0-3x-parity`, migration spec `docs/3x-to-native.md`.
- 233 tests green via `uv run tools/test.py` — the pinned premake5 beta8
  release binary in `.deps/` (prepared by `uv run tools/premake5.py`) ships
  the self-test harness, which `tools/run-vs6-tests.lua` points at
  `tests/`; no premake-core checkout is needed. The full premake-core
  suite was also green during Step 4 against a then-current checkout.
  `tests/golden/` is the module's own sample output (regression
  baseline); `tests/e2e.py` diffs against it with separator/EOL
  normalization.
- Validated on Windows (2026-09-22): Sample.dsw opens clean in a real
  VC6 IDE and builds end-to-end (dependencies and build events working);
  beta7 spot-check byte-identical. The `/ZI /O2` illegality found in the
  old 3.x-parity output was a premake 3.7 oracle bug; native mode emits
  `/Zi` with optimization.
- `real-world-test-cases/` holds 310 .dsw/.dsp files from 13 public
  projects (provenance in each SOURCE.md); `experiments/` reproduces
  four of them from premake5 scripts (per-experiment NOTES.md).

## Completed roadmap (Steps 1–4, all done 2026-09-24 → 2026-09-27)

History lives in the git log and the per-experiment NOTES.md files:

1. **Divergence sweep:** one bug (`links "foo.lib"` double-extension)
   and nine silently dropped premake5 APIs mapped (undefines,
   characterset, syslibdirs, ignoredefaultlibraries,
   externalincludedirs, includedirsafter, forceincludes, symbolspath,
   mapfile/mapfilepath, profile).
2. **Gap features:** `locale` → RSC `/l` LCID, quoted `SOURCE=` for
   paths with spaces, `vpaths` logical groups, `excludefrombuild`
   per-config blocks.
3. **Real-world experiments** (`tools/dspdiff.py` structural differ):
   peter (7/9 identical), zlib (100%), libpng (dsw + pngtest match),
   quake2 (dsw + all 5 dsp match) — each with documented residuals.
   Drove per-file custom build rules, per-file CPP flags, PCH
   (`/Yu`/`/Yc`), plus fixes for path-like links, `MTL=` condition,
   RSC marker dedupe, and `LIB32=link.exe -lib`.
4. **Build-option coverage:** `docs/coverage-matrix.md`, the
   `vs6_coverage` pairwise suite (111 cases), and the Windows acceptance
   run — 98/98 accepted (`tests/acceptance/RESULTS.md`).

## Optional follow-ups (nothing required)

- **Dedicated mappings for the escape-hatch-only single-flag enums**
  (currently reachable only via `buildoptions`, documented in
  `docs/coverage-matrix.md`): `callingconvention` (`/Gd`..),
  `structmemberalign` (`/Zp`), `stringpooling` (`/GF`), `intrinsics`
  (`/Oi`), `functionlevellinking` (`/Gy`), `unsignedchar` (`/J`),
  `compileas` (`/TC`/`/TP`), `inlining` (`/Ob`). Decide each as
  map-vs-document; tests in the same commit.
- **Revisit if needed:** `characterset "Default"` (premake5's global
  default) maps to `/D "_UNICODE" /D "UNICODE"`, following
  `msc.lua`/`vs2010` exactly — legacy ANSI code opts out with
  `characterset "MBCS"` (documented in README.md). The rejected
  alternative was Default → nothing (VC6-era ANSI norm, diverging from
  every premake5 generator).
- **FLTK experiment** (Step 3's other scale candidate): it has no
  feature the corpus above doesn't already cover.

## Reference material

- `tests/golden/` — the module's own output for the sample (CRLF,
  `-text` in .gitattributes); regenerate deliberately from module
  output and review the diff. The premake 3.7 oracle fixtures live at
  tag `v1.0-3x-parity`.
- `real-world-test-cases/` — 310 files from 13 projects (see its
  README.md); not byte-parity targets.
- `experiments/` — premake5 scripts reproducing four real-world
  workspaces; each has a run.py (generate into git-ignored build/ and
  diff with `tools/dspdiff.py`) and a NOTES.md (results + gap list).

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
