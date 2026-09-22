# Peter (Panda381/Peter)

- **Upstream:** `https://github.com/Panda381/Peter` @ `main`, `Peter250src/`
- **Retrieved from:** `https://raw.githubusercontent.com/Panda381/Peter/main/Peter250src/`
- **License:** freeware (per `!info.txt` upstream: "2.50: freeware"); no formal license file. Author: Miroslav Němeček (Panda381).
- **Files:** Peter.dsw + 8 .dsp (Peter, DataInst, DelExe, Gener, Loader, Loader0, Pov2Spr, Setup)
- **Notes:** late-90s Czech game-development tool. 8 projects in subdirectories, WindowedApp + ConsoleApp kinds, custom configuration names with spaces ("Debug Optim", "Debug Demo", "Install"), resources (.rc, .cur, .ico, .bmp), Czech resource locale (`/l 0x405`), per-config resource defines. Quirk: `Loader` and `Loader0` are project names whose .dsp file is `Peter.dsp` (project name ≠ file name). Logical (non-path) file groups with `Default_Filter` values, per-file `Exclude_From_Build`, and quoted `SOURCE=` paths for names with spaces — none of which premake 3.x-style generators emit.
