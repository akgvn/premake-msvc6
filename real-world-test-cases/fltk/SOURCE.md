# FLTK 1.1 — visualc/

- **Upstream:** `https://github.com/fltk/fltk` @ `branch-1.1`, `visualc/`
- **Retrieved from:** `https://raw.githubusercontent.com/fltk/fltk/branch-1.1/visualc/`
- **License:** LGPL-2.0 with static-linking exception
- **Files:** fltk.dsw + 71 .dsp (fltk.lib, fltkdll, fltkgl, fltkimages, fltkforms, fluid, jpeg, libpng, zlib + ~60 demo apps)
- **Notes:** the dependency-graph stress test: ~70 projects in one workspace, `demo` alone depends on ~60 of them. Also notable: FLTK quotes the project paths in its .dsw (`Project: "x"=".\x.dsp"`), unlike premake/VC6's usual unquoted form.
