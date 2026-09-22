# Real-world VC6 test cases

Real-world `.dsw`/`.dsp` files collected from public open-source projects,
for use as references and (future) test cases for the vs6 generator.
**These files are not part of the module and retain their own licenses** —
see `SOURCE.md` in each directory for upstream URL, license, and notes.

| Directory    | Project                          | Files | License        | Exercises |
|--------------|----------------------------------|------:|----------------|-----------|
| zlib         | zlib 1.2.3 `projects/visualc6`   |     4 | zlib           | deps, LIB32+LINK32, 8 configs, VC-isms |
| libpng       | libpng 1.2.44 `projects/visualc6`|     3 | libpng         | deps, LIB/DLL configs |
| quake2       | Quake 2 GPL release              |     6 | GPL-2.0        | 5 projects, .rc, "Alpha" configs, DLLs |
| quake        | Quake GPL release                |    12 | GPL-2.0        | custom build steps, Exclude_From_Build, # SUBTRACT |
| fltk         | FLTK 1.1 `visualc/`              |    72 | LGPL-2.0       | ~70-project workspace, deep dependency graph, quoted paths |
| peter        | Peter (Panda381)                 |     9 | freeware       | subdir projects, name≠filename, custom config names, resources, logical groups |
| cnc-renegade | C&C Renegade (EA)                |    75 | GPL-3.0        | large engine+game+tools codebase |
| cnc-generals | C&C Generals + Zero Hour (EA)    |   106 | GPL-3.0        | large codebase, filename with space |
| pywin32      | PyCOMTest                        |     2 | PSF            | COM DLL, midl |
| resiprocate  | cppunit msvc6                    |     4 | Vovida (BSD)   | DLL plugin + runners |
| resizablelib | resizablelib                     |    14 | CPOL           | MFC lib + demos (out of generator scope) |
| rayverse     | rayverse                         |     1 | CC0            | single project, hand-edited LINK32 |
| contiki      | contiki 1.x win32                |     2 | BSD            | tiny workspace, custom configs |

Total: 312 files (310 .dsp/.dsw + README.txt files from zlib/libpng).

## Caveats when comparing against premake-generated output

Real-world (VC-authored or hand-maintained) files systematically differ
from premake 3.x output; they are references, not byte-parity targets:

- system library lists (`kernel32.lib user32.lib ...`) at the start of LINK32
- `# SUBTRACT` lines, `DEP_CPP_` blocks, per-file custom build steps
- `# PROP Ignore_Export_Lib 0` written explicitly
- quoted `Project:` paths and quoted `SOURCE=` paths (spaces)
- logical (non-path) file groups with non-empty `Default_Filter`
- non-0x409 resource locales, MTL `/o "NUL"`

## Not included (and why)

- **SDL 1.2** `VisualC/` — files are Format Version 5.00 (VC5), wrong format.
- **PELock SDK examples** — proprietary freeware SDK, licensing unclear.
- **kbengine** vendored deps — duplicates of libpng/zlib above.
- No premake-generated .dsp/.dsw was found committed in the wild
  (generator outputs are rarely committed).
