# Quake 2 experiment (Step 3, scale)

Goal: reproduce `real-world-test-cases/quake2` (quake2.dsw + the five .dsp
projects from id Software's Quake 2 v3.19 GPL release) with the vs6
module.

`premake5.lua` sits at the workspace root of the shadow tree, like the
real quake2.dsw; `run.py` generates into `build/` (git-ignored) and diffs
each file against the original with `tools/dspdiff.py`.

## Result

`quake2.dsw` matches exactly. All five `.dsp` files match except the
documented residuals below. This is the largest corpus sample so far
(5 projects, ~150 source files, 4 configurations each including two
ALPHA ones, a resource tree, and per-file custom build rules).

Reproduced:

- **ALPHA configurations.** `Release Alpha` / `Debug Alpha` are modeled
  as ordinary configurations; their Alpha-only switches (`/QA21164`,
  `/Gt0`, `/QAieee1`, `/D C_ONLY`) ride in `buildoptions`, and
  `editandcontinue "Off"` yields the `/Zi` the Alpha debug configs use
  (the x86 debug configs keep `/ZI`).
- **Per-config runtime and output dirs.** `staticruntime "On"` gives
  `/MT(d)`; `targetdir`/`objdir` are script-relative, so shared output
  dirs (`..\release` for game/ref_gl/ref_soft) and per-project objdirs
  both land right.
- **Per-config linker state.** `mapfile "On"` + `incrementallink "Off"`
  on the x86 Debug configs only (ctf's Debug Alpha keeps `/map` but no
  `/incremental:no`, matching the original); `ref_soft` adds
  `ignoredefaultlibraries { "libc" }` to its two Debug configs.
- **Per-file custom builds.** `ref_soft`'s nine `.asm` files get the
  `ml /c /Cp /coff /Fo$(OUTDIR)\$(InputName).obj /Zm /Zi $(InputPath)`
  rule in both x86 configs and `excludefrombuild` in both ALPHA configs.
- **Hand drift, faithfully.** `ref_gl` links `opengl32` in Debug Alpha
  only; `ctf` is the one project with no `/G5` (and Alpha carries only
  `/Gt0`); `r_polysa.asm` is the one `.asm` whose ALPHA branches are
  empty (no `Exclude_From_Build`) — expressed with a `files:not` filter.
- **DLL link lines.** `linkoptions { "/subsystem:windows" }` restores the
  explicit subsystem the VC6 author added to every DLL (the module leaves
  it to the `/dll` default, as premake5's msc toolset does).

## Residual differences (all documented limitations)

1. **`/machine:ALPHA`.** The ALPHA configs carry `/machine:ALPHA`; the
   module has no Alpha architecture value and pins `/machine:I386`. This
   is the expected gap (linkoptions cannot override it without
   duplicating `/machine`). 10 `# ADD LINK32` lines, 2 per project.
2. **`/FD` in ref_soft Release.** The original's x86 Release `# ADD CPP`
   line omits `/FD`; the module always emits it. (`/FD` is fixed idiom in
   the writers.) One line, clearly hand drift.
3. **`/nodefaultlib:"libc"`.** The original writes the bare library base
   name; the module follows premake5's `msc.lua` and appends `.lib`, so
   it emits `/nodefaultlib:"libc.lib"`. Two link lines (ref_soft Debug
   and Debug Alpha); semantically identical.

## Tooling fixes (tools/dspdiff.py)

Quake 2 was the first corpus sample with VC6 per-file dependency blocks,
which exposed gaps in the normalizer:

- `DEP_CPP_`/`DEP_RSC_` *continuation* lines (and the `NODEP_` lists
  `ref_gl` carries for external `gl.h`/`glu.h`) are now dropped, not just
  the assignment line.
- A per-file `!IF/!ELSEIF` chain whose branches are all empty (VC6 writes
  one for every file even when it only holds dependencies) now disappears
  entirely instead of leaving a stray `!ENDIF`.
- `# PROP Target_Dir "."` (the project's own directory) normalizes to the
  module's `""`.

None of these changed the zlib/peter/libpng outcomes (those originals
have no dependency blocks).
