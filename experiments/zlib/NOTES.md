# zlib experiment (Step 3)

Goal: reproduce `real-world-test-cases/zlib` (zlib.dsw + zlib.dsp +
example.dsp + minigzip.dsp, from zlib 1.2.3's hand-maintained
projects/visualc6) with the vs6 module.

`premake5.lua` sits at the projects/visualc6 position of the shadow
tree, like the originals; `run.py` generates into `build/` (git-ignored)
and diffs against the originals with `tools/dspdiff.py`.

## Result

**All four files structurally match the originals** (after the module
features added in this round: per-file custom build rules, per-file CPP
flags, per-config excludefrombuild, per-config kind/targetname).

Notable shapes reproduced: per-config kind (`kind` via
`configurations:DLL*` filters — DLL and LIB configs in one .dsp),
per-config target names (`zlib1`/`zlib1d`/`zlib`/`zlibd`), project
dependencies (`links { "zlib" }` from example/minigzip become .dsw
dependencies and no .lib on the link line), zlib.def excluded from LIB
configs, .asm files excluded from non-ASM configs with ml.exe custom
build steps in ASM configs, gvmat32c.c's per-file `/I "..\.."`.

premake5 mechanics worth knowing: project-level `configurations` APPEND
to the inherited workspace set, so the workspace declares the shared 8
configurations and no project adds its own; the three projects share
output dirs, so `objdir` uses the `!` prefix to opt out of premake5's
cross-project uniqueness suffix.
