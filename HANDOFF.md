# HANDOFF — where we are and what's next

State as of 2026-09-27, uncommitted work on top of commit 700c25c.
122 vs6 tests green; full premake-core suite (3025) green;
tests/e2e.sh green; zlib experiment 100% green; peter and libpng
show only their documented residuals. The quake2 experiment is written
and its result recorded; the dspdiff fixes below are uncommitted.

## Done since the last HANDOFF

- **Step 3d — experiments/quake2 (scale):** the five-project Quake 2
  v3.19 workspace is reproduced. `quake2.dsw` matches exactly; all five
  `.dsp` match except three documented residuals (`/machine:ALPHA`
  unpinnable, ref_soft Release missing `/FD`, `/nodefaultlib:"libc"`
  vs the premake5-native `"libc.lib"`). New shapes exercised: ALPHA
  configs via `buildoptions` + `editandcontinue "Off"` (for `/Zi`),
  script-relative file/dir paths for subdirectory projects,
  `/subsystem:windows` restored through `linkoptions`, per-config
  mapfile/incrementallink/ignoredefaultlibraries, ref_gl's
  opengl32-only-in-Debug-Alpha hand drift, and per-file
  `files:not` filters for r_polysa.asm's one-off empty ALPHA branches.
  See `experiments/quake2/NOTES.md`.
- **tools/dspdiff.py fixes** (first forced by quake2's VC6 dependency
  blocks): now drops `DEP_CPP_`/`DEP_RSC_`/`NODEP_` *continuations*,
  removes an all-empty per-file `!IF` chain instead of leaving a stray
  `!ENDIF`, and normalizes `# PROP Target_Dir "."` to `""`. zlib, peter
  and libpng outcomes are unchanged (their originals have no dependency
  blocks).
- No module sources changed this round; PLAN.md Status/Steps updated
  with the quake2 line and the already-reachable Step 4 flags.

## Remaining

- **FLTK** is the other "scale" candidate in PLAN Step 3, now optional:
  the quake2 experiment covers everything FLTK would (it has no feature
  the corpus doesn't already cover).
- **Step 4 — VC6 build-option coverage** (the big one): coverage matrix
  + `vs6_coverage` combinatoric suite + Windows acceptance run. PLAN.md
  Step 4 has the flag inventory; the Steps 2–3 flags are already listed
  as reachable there (locale/RSC, per-file CPP + custom build, PCH
  `/Yu`/`/Yc`, `symbolspath` `/pdb:`, `mapfile` `/map`, `profile`,
  `/nodefaultlib:`, `/FI`, `/U`, characterset defines). Deferred
  single-flag enums to evaluate there: callingconvention `/Gd`..,
  structmemberalign `/Zp`, stringpooling `/GF`, intrinsics `/Oi`,
  functionlevellinking `/Gy`, unsignedchar `/J`, compileas `/TC`/`/TP`,
  inlining `/Ob`, plus the no-VC6-equivalent list (cdialect/cppdialect
  `/std`, vectorextensions, floatingpoint, …). The Windows run uses the
  loose VC6 tree at `C:\MSVC6` with
  VCVARS32.BAT.

## Working with the quota

Batch independent tool calls; avoid re-reading files already read;
trust prior findings (this file + PLAN.md + NOTES.md files carry them).
Commit only when explicitly asked.

**Placeholder lesson:** explicit per-project file lists (zlib, libpng,
quake2) avoid the placeholder machinery entirely; if globs are ever used
(peter), placeholder paths must be joined onto the script's own
directory (the real .dsp's depth), never naively — see commit b3e7474
for the escaped-stubs incident.
