# VC6 acceptance results

- **Date:** 2026-09-27
- **Host:** Windows, loose Visual C++ 6.0 tree
- **Toolchain:** `C:\MSVC6\Common\MSDev98\Bin\MSDEV.EXE`, environment from `VC98\Bin\VCVARS32.BAT`
- **Workspace:** `vc6_acceptance.dsw` — 49 projects, `Debug` + `Release` each
- **Result: 98 accepted / 0 rejected**
- **Raw log:** [`acceptance-windows.log`](acceptance-windows.log)

The 98 builds cover every switch the module can emit at least once
(see `docs/coverage-matrix.md` and `tests/test_vs6_coverage.lua`). Debug
and Release differ in the debug-build-derived flags (`/MDd`/`/MTd`,
`/GZ`, `Use_Debug_Libraries`), so accepting both confirms the runtime
rule end to end.

## Profiles

| Group | Profiles (`- Win32 Debug` and `- Win32 Release` each) |
|---|---|
| compiler | `cpp_default` `cpp_debug` `cpp_static` `cpp_static_debug` `cpp_warn_off` `cpp_warn_extra` `cpp_warn_fatal` `cpp_minrebuild` `cpp_nortti` `cpp_noexcept` `cpp_zi` `cpp_zi_opt` `cpp_z7` `cpp_zi_ecoff` `cpp_od` `cpp_ot` `cpp_o1` `cpp_o2` `cpp_ox` `cpp_omitfp` `cpp_mbcs` `cpp_ascii` `cpp_defines` `cpp_includes` `cpp_forceinclude` `cpp_buildoptions` `cpp_pch` |
| linker | `link_console` `link_windowed` `link_dll` `link_dll_noimplib` `link_symbols` `link_symbols_pdb` `link_incr_yes` `link_incr_no` `link_entry` `link_map` `link_map_path` `link_profile` `link_libdirs` `link_links` `link_nodefaultlib` `link_options` `lib_static` |
| resource | `rsc_locale` `rsc_locale_de` `rsc_defines` `rsc_options` `rsc_symbols` |

## Findings folded back into the module/docs

The first run was 94/98. The four rejects were harness authoring
mistakes, not module bugs, and produced two VC6 rules now recorded under
"VC6 gotchas" in `docs/coverage-matrix.md`:

1. **`/Yc` include match.** `pchheader "sources/accept.h"` emitted
   `/Yc"sources/accept.h"`, but the source's `#include "accept.h"` did
   not match, so VC6 failed with `C2857`. Fixed by using a bare
   `pchheader "accept.h"` next to the sources.
2. **`/FI` search.** `forceincludes "sources/accept.h"` emitted
   `/FI "sources\accept.h"`, which VC6 resolves like a quoted `#include`
   from the including file, so it looked under `sources\sources\`. Fixed
   by using a bare `forceincludes "accept.h"`.

No module change was needed: the emitted flags are the correct premake5
translations; the scripts must name the headers the way VC6 matches
them.

## Reproducing

```sh
tests/acceptance/generate.sh          # Linux: writes build/
# copy tests/acceptance/build/ to the Windows checkout
tests\acceptance\run.bat              # Windows: rebuilds and rewrites acceptance.log
```
