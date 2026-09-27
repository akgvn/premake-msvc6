# libpng experiment (Step 3)

Goal: reproduce `real-world-test-cases/libpng` (libpng.dsw + libpng.dsp
+ pngtest.dsp) with the vs6 module. The workspace references the zlib
project from a sibling tree (`../../../zlib/...`), like the real file.

`premake5.lua` sits at libpng/projects/visualc6 in the shadow tree;
`run.sh` materializes both source trees' files as placeholders,
generates, and diffs with `tools/dspdiff.py`.

## Result

`libpng.dsw` and `pngtest.dsp` structurally match the originals.
`libpng.dsp` matches except the residual set below.

Reproduced: per-config kind + target names (libpng13/libpng13d/
libpng/libpngd/libpng13vb), explicit per-config library paths
(`Win32_DLL_Release\libpng13.lib` etc. via path-like `links`), the
cross-tree `/libpath` to zlib's output dirs, `dependson` build order,
tab-separated multi-command `PostBuild_Cmds`, per-config
excludefrombuild for pngw32.def/pngw32.rc.

Residual differences (all documented limitations):

1. **"DLL VB" block position.** The workspace's 8 shared configurations
   cover pngtest and the referenced zlib project; libpng's 9th config
   "DLL VB" is appended at project level (premake5 has no
   removeconfigurations), which puts it first in block order. The real
   file has it in the middle. Cosmetic.
2. **Embedded-quote defines.** The original's RSC lines carry
   hand-edited doubled-quote values like
   `/d PNG_LIBPNG_SPECIALBUILD=""""Use MMX instructions""""`; the module
   quotes define values plainly (`/d "X"`) and has no
   embedded-quote escaping. No premake5-native form to match.
3. **Hand drift in the original.** Two LIB debug configs lack the
   `/i "..\.."` and `PNG_DEBUG=1` that the other seven configs carry;
   the script applies them uniformly.

Also visible: the real file lists pngwrite.c/pngwtran.c/pngwutil.c in
both "Source Files" and "Header Files" (a hand-edit slip); a premake5
file lives in exactly one group, so the module lists them once
(normalized away by the tool's per-run dedupe).
