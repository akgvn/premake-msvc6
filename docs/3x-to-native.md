# 3.x → premake5-native migration spec

Decision (2026-09-22): **no 3.x mode, no parity switch.** The module goes
premake5-native outright; the 3.x-parity state is preserved at tag
`v1.0-3x-parity`. This document is the inventory of every
non-premake5-native default behavior v1 pins (test by test), and the
native replacement for each. It is the spec for the conversion that
follows: module rewrite, test re-baseline, new golden target.

"Native" below means: what premake5 itself does or provides — baked
`cfg.buildtarget`/`cfg.linktarget` (oven.lua, config.lua), the msc
toolset flag tables (`src/tools/msc.lua`), vstudio's precedents
(`vs200x_vcproj.symbols()`), and premake5's documented defaults
(`src/_premake_init.lua`).

## A. Fixed text that is NOT a divergence (kept as-is)

VC6-idiomatic output with no premake5 concept either way; the oracle and
VC-authored files agree on it. No test changes needed for these:

- File/header skeletons, `!MESSAGE` block, `CFG=` line, reversed config
  order, `!IF`/`!ELSEIF` chain, `# Name` lines.
- `CPP=cl.exe`, `MTL=midl.exe` (non-StaticLib), `RSC=rc.exe`,
  `BSC32=bscmake.exe` + `# ADD (BASE) BSC32 /nologo`.
- `/nologo`, `/machine:I386`, `/YX /FD` + `/c` on CPP lines (automatic
  PCH + file dependencies; VC6-idiomatic, harmless).
- `/GR` unless `rtti "Off"`, `/GX` unless `exceptionhandling "Off"`,
  `/WX` for `fatalwarnings { "All" }`, `/W4` for `warnings "Extra"`.
- `/subsystem:windows|console`, `/dll`, `LINK32=link.exe -lib` + LIB32
  for StaticLib, MTL block for WindowedApp/SharedLib.
- RSC `/l 0x409` (until the later locale option — PLAN.md Step 2), resdefines/
  resincludedirs/resoptions merging with defines/includedirs.
- `.dsw` skeleton; sibling `links` → dependency blocks (extended by D7
  below); `prj.filename` for the .dsp path.
- Source-tree grouping by path, `..` group roots skipped.

## B. The divergences (3.x-parity behavior → native replacement)

### D1. Output directories

- **3.x (pinned by vs6_outputdirs, vs6_target, vs6_packages/kinds full
  blocks):** `targetdir` unset → Output_Dir `.`; target = `./name.exe`.
  `objdir` always gets buildcfg appended (`obj/Debug`; explicit
  `objdir "temp"` → `temp/Debug`).
- **Native:** trust the oven. Output_Dir = `cfg.buildtarget.directory`
  made relative to the project (`bin\Debug` default; explicit
  `targetdir` as-is). Intermediate_Dir = baked `cfg.objdir` made
  relative (premake5 uniqueness rules: `obj\Debug` default here too,
  buildcfg appended on collision — including for explicit objdirs,
  `temp/Debug` for `objdir "temp"` — project name appended on
  cross-project collision, `!`-prefix opts out). Target = `cfg.buildtarget.relpath` adjusted for prefix/ext
  (the module still composes prefix+name+ext itself, from
  `cfg.targetprefix`/`cfg.targetextension`, since those carry the
  Windows system-filter defaults).
- **Tests to re-baseline:** vs6_outputdirs (all 8), vs6_target (all 8 —
  `defaultTarget`, `setOnPackage*`, `targetIncludesPath`,
  `targetAppliedTo*`, `customTarget*`), and every full-block capture in
  vs6_packages, vs6_kinds, vs6_buildflags.noImportLib.

### D2. libdir / import libraries

- **3.x (pinned by vs6_importlib, vs6_target.targetAppliedToImportLib,
  vs6_outputdirs.libDir*):** 3.x `libdir` mapped to `targetdir`
  (exe/StaticLib) and `implibdir` (DLL implib); trailing
  `/libpath:"<libdir>"`; implib = `<implibdir|libdir>[/<targetname-dir>]/<name>.lib`.
- **Native:** trust `cfg.linktarget` (which honors `implibdir`/
  `implibname` and the Windows `.lib` default). Trailing `/libpath:` =
  the target's own directory (`cfg.buildtarget.directory` relative).
  `useimportlib "Off"`: `Ignore_Export_Lib 1` + **omit `/implib:`**
  (3.x redirected it into objdir; premake5's `getlinkinfo` returns the
  DLL itself in that case).
- **Tests to re-baseline:** vs6_importlib (both), vs6_target.
  targetAppliedToImportLib, vs6_outputdirs.libDir*, linkFlags
  expectations everywhere (`/libpath:"."` → `/libpath:"bin\Debug"` etc.),
  vs6_buildflags.noImportLib.

### D3. Symbols

- **3.x (pinned everywhere — most block captures):** symbols ON by
  default: `/ZI`, `/incremental:yes /debug`, `/pdbtype:sept`, RSC/MTL
  `_DEBUG`. `symbols "Off"` → NDEBUG + none of the above.
- **Native:** premake5 default = no symbols (no `/Z*`, no `/debug`,
  RSC/MTL `NDEBUG`). `symbols "On"` → debug info with the vstudio
  legality rule (`vs200x_vcproj.symbols()`): `/Zi` when
  `editandcontinue "Off"` OR an optimized build (`config.isOptimizedBuild`),
  else `/ZI`; `/Z7` for `debugformat "c7"`. Linker with symbols on:
  `/debug` + `/pdbtype:sept` (VC6-idiomatic); `/incremental:` only from
  the `incrementallink` API (On → yes, Off → no, nil → omit).
  **This also fixes the `/ZI /O2` illegality the Windows VC6 run
  proved** (D2016): in native mode `/ZI` is never emitted with
  optimization. The 3.x line `/ZI /O2` stays only in the tagged history.
- **Tests to re-baseline:** all block captures (default loses `/ZI`,
  `/incremental:yes /debug`, `/pdbtype:sept`, `_DEBUG`→`NDEBUG`);
  vs6_buildflags.noSymbols (now the default — stays valid, expectations
  change); vs6_resources (default ResDefines `_DEBUG`→`NDEBUG`).

### D4. Runtime library selection (`/MD(d)` vs `/MT(d)`) and `Use_Debug_Libraries`

- **3.x (pinned in every block capture):** driven by optimization state
  (`useDebugLibs = not optimizing`): non-optimizing → `/MDd` +
  `Use_Debug_Libraries 1` + `/Gm` + `/GZ`; optimizing → `/MD` + `0`.
  Plus the **rotation**: each block shows the *next* config's state
  (3.7 off-by-one, reproduced for oracle parity).
- **Native:** mirror `msc.lua`'s（`getRuntimeFlag`）: `/MT` or `/MD` by
  `staticruntime "On"`; `d` suffix when `runtime "Debug"` or (runtime
  unset and `config.isDebugBuild(cfg)` — symbols explicitly on and not
  optimized). `Use_Debug_Libraries` follows the same rule, computed
  from the block's **own** config (rotation dropped). `/Gm` only from
  `minimalrebuild "On"`. `/GZ` when the debug runtime is selected
  (VC6-idiomatic debug marker; no premake5 API).
- **Tests to re-baseline:** every block capture (`/MDd`→`/MD` where a
  config is not a "debug build"; `Use_Debug_Libraries` now varies by
  config — Debug 1, Release 0 in the default two-config setup);
  vs6_buildflags.optimize* (runtime no longer follows `/O2`);
  vs6_buildflags.staticRuntime (`/MTd`→`/MT` for Release);
  vs6_kinds, vs6_packages.

### D5. optimize/warnings value mapping

- **3.x (pinned by vs6_buildflags.optimize*, vs6_limits.unmapped*):**
  `optimize "On"/"Speed"` → `/O2`, `"Size"` → `/O1`, nil → `/Od`;
  `Off`/`Debug`/`Full` warned + fell back to `/Od`. `warnings "Extra"` →
  `/W4`, else `/W3`; `Off`/`High`/`Everything` warned + fell back to `/W3`.
- **Native:** msc.lua tables: `optimize Off/Debug` → `/Od`, `On` →
  **`/Ot`** (note: not `/O2`), `Speed` → `/O2`, `Size` → `/O1`,
  `Full` → `/Ox`; nil → omit the flag. `warnings Off` → `/W0`,
  `High`/`Extra` → `/W4`, `Everything` → `/W4` (VC6 has no `/Wall` —
  closest legal; document), nil/`Default` → `/W3` (VC6's norm). No
  warnings emitted for any of these.
- **Tests to re-baseline:** vs6_buildflags.optimize (`/O2`→`/Ot`),
  optimizeSize, optimizeSpeed (stays `/O2`); vs6_limits.unmapped* →
  mapped-value tests; nil-optimize captures lose `/Od`.

### D6. Entry point

- **3.x (pinned by most linkFlags expectations):**
  `/entry:"mainCRTStartup"` for exe kinds unless `entrypoint ""`;
  `entrypoint "X"` → `/entry:"X"`.
- **Native:** emit `/entry:` only when `entrypoint` is set.
- **Tests to re-baseline:** vs6_buildflags.noMain (becomes the default
  shape), vs6_limits.customEntrypoint (unchanged), all linkFlags
  expectations.

### D7. Dependencies

- **3.x (pinned by vs6_dependencies):** .dsw dependency blocks from the
  **first config's** `links` only; `dependson` ignored with a warning.
- **Native:** union sibling links across **all** configs (dedup,
  first-seen order); `dependson` emits dependency blocks via
  `project.getdependencies(prj, "dependOnly")`.
- **Tests to re-baseline/add:** vs6_dependencies (same for uniform
  links; add per-config-links case), vs6_limits.dependsonIgnored →
  dependson-block test.

### D8. prebuildcommands

- **3.x (pinned by vs6_limits.prebuildcommandsIgnored):** ignored with a
  warning (VC6 has no pre-build step).
- **Native:** fold into `PreLink_Cmds` ahead of `prelinkcommands`
  (closest VC6 semantics).
- **Tests to re-baseline:** vs6_limits.prebuildcommandsIgnored →
  folding test; native sample shows
  `PreLink_Cmds=echo prebuild\techo prelink`.

### D9. targetname containing a directory

- **3.x (pinned by vs6_target.targetIncludesPath,
  targetAppliedToImportLib):** a directory component in the target name
  is appended to outdir/implib (`targetname "MyApp/MyPackage"` →
  Output_Dir `./MyApp`).
- **Native:** `targetname` is a bare name in premake5; directory
  placement belongs to `targetdir`. Do not append the name's directory
  (strip it; warn once if a targetname contains a path separator,
  pointing at targetdir).
- **Tests to re-baseline:** the two named tests (re-express with
  `targetdir`).

## C. Suite-by-suite impact summary

| Suite | Re-baseline scope |
|---|---|
| vs6_packages | full-file captures: D1 dirs, D3 symbols, D4 runtime/GZ, D6 entry |
| vs6_paths | none (path computation unchanged) |
| vs6_dependencies | D7 (existing cases unchanged; add per-config case) |
| vs6_kinds | block captures: D1, D3, D4, D6 |
| vs6_buildflags | D3 noSymbols, D4 staticRuntime/optimize*, D5 optimize/warnings, D6 noMain, D2 noImportLib |
| vs6_buildoptions | block tails only (flags before them change per D3/D4) |
| vs6_defines | flag prefixes change per D3/D4 |
| vs6_includepaths | flag prefixes change per D3/D4 |
| vs6_links | D2 trailing /libpath, D6 entry |
| vs6_libpaths | D2 trailing /libpath, D6 entry |
| vs6_target | D1, D2, D9 |
| vs6_importlib | D2 |
| vs6_outputdirs | D1, D2 |
| vs6_resources | D3 (NDEBUG default) |
| vs6_files | none |
| vs6_limits | D5 mapped values, D7 dependson, D8 prebuild folding |

## D. Golden target and samples

- `tests/golden/` (3.7 oracle fixtures) is replaced by the module's own
  native output for `samples/premake5.lua` — the new regression
  baseline. The 3.7 fixtures remain reachable at tag `v1.0-3x-parity`.
- `samples/premake.lua` (3.x syntax, oracle input) is deleted — no
  3.x mode left to compare against.
- `tests/e2e.py` mechanics unchanged (normalized diff; path-separator
  normalization becomes a no-op but harmless).

## E. Open design decisions (recommendations; settle during conversion)

1. **nil optimize → omit `/O*`** (premake5 msc emits nothing; VC6
   defaults to `/Od` behavior anyway). Recommended.
2. **`warnings Everything` → `/W4`** (VC6 has no `/Wall`). Recommended.
3. **`/pdbtype:sept` kept when symbols on** (VC6-idiomatic; zlib's own
   debug lines carry it). Recommended.
4. **`/GZ` when the debug runtime is selected** (VC6-idiomatic debug
   marker; no premake5 API). Recommended.
5. **`/YX /FD` kept unconditionally** (VC6-idiomatic fixed text; PCH
   APIs remain unimplemented, same as 3.x). Recommended.
6. **Use_Debug_Libraries rule** = the `/MDd` rule (runtime "Debug" or
   isDebugBuild), own config. Recommended.
