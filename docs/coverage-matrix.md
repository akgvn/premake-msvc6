# VC6 build-option coverage matrix

Every build switch the `vs6` module can emit, and the premake5 API that
reaches it. This is the reference for Step 4's coverage claim: "every
VC6 build switch the module can emit is reachable from a premake5
script."

The matrix is tested two ways:

- the per-feature suites (`tests/test_vs6_*.lua`) pin each individual
  mapping with exact strings;
- `tests/test_vs6_coverage.lua` walks the reachable option space
  pairwise and checks the exact CPP / RSC / LINK32 / LIB32 line for each
  combination, including the legality rules at the end of this document.

The column **Where** is the writer line that carries the flag:
`CPP` = `# ADD CPP`, `RSC` = `# ADD RSC`, `LINK32` = `# ADD LINK32`,
`LIB32` = `# ADD LIB32`, `fixed` = structural boilerplate; `file` = a
per-source `# ADD CPP` / `# Begin Custom Build` block.

## Compiler (`cl.exe`)

| VC6 flag | premake5 API | Where | Notes |
|---|---|---|---|
| `/nologo` | *(fixed)* | CPP | every config |
| `/MD`, `/MDd` | `runtime "Release"/"Debug"` + `staticruntime "Off"` | CPP | debug suffix from `runtime` (or the debug-build rule when unset) |
| `/MT`, `/MTd` | `staticruntime "On"` + `runtime` | CPP | `staticruntime "Default"` behaves as `Off` |
| `/W0` | `warnings "Off"` | CPP | |
| `/W3` | `warnings "Default"` | CPP | premake5 default |
| `/W4` | `warnings "High"` / `"Extra"` / `"Everything"` | CPP | VC6 has no `/Wall`; all map to `/W4` |
| `/WX` | `fatalwarnings { "All" }` | CPP | |
| `/Gm` | `minimalrebuild "On"` | CPP | omitted otherwise (no `/Gm-` on VC6) |
| `/GR` | `rtti` (`Default`/`On`) | CPP | `rtti "Off"` omits it (VC6 has no `/GR-`) |
| `/GX` | `exceptionhandling` (`Default`/`On`) | CPP | `"Off"` omits it; `"SEH"` has no VC6 form |
| `/ZI` | `symbols "On"` | CPP | only when edit-and-continue is legal (see rules) |
| `/Zi` | `symbols "On"` + (`editandcontinue "Off"` or optimized) | CPP | |
| `/Z7` | `symbols "On"` + `debugformat "c7"` | CPP | also suppresses `/pdb:` on the link line |
| `/Od` | `optimize "Off"` / `"Debug"` | CPP | |
| `/Ot` | `optimize "On"` | CPP | |
| `/O2` | `optimize "Speed"` | CPP | |
| `/O1` | `optimize "Size"` | CPP | |
| `/Ox` | `optimize "Full"` | CPP | |
| `/Oy` | `omitframepointer "On"` | CPP | |
| `/I "dir"` | `includedirs`, `externalincludedirs`, `includedirsafter` | CPP | that order; pre-msc-v142 all map to `/I` |
| `/D "_UNICODE" /D "UNICODE"` | `characterset "Default"` / `"Unicode"` | CPP | premake5 global default; msc mapping |
| `/D "_MBCS"` | `characterset "MBCS"` | CPP | |
| *(none)* | `characterset "ASCII"` | CPP | no define |
| `/D "DEF"` | `defines { "DEF" }` | CPP | |
| `/U "DEF"` | `undefines { "DEF" }` | CPP | |
| `/FI "hdr"` | `forceincludes { "hdr" }` | CPP | |
| `/YX` | *(default)* | CPP | premake5 default (`enablepch` not `Off`, no `pchheader`) |
| `/Yu"hdr"` | `pchheader "hdr"` | CPP | |
| `/Yc"hdr"` | `pchsource "src"` | file | per-file build-the-PCH block |
| `/FD` | *(fixed)* | CPP | |
| `/GZ` | debug runtime | CPP | after `/FD`; only for `/MDd`/`/MTd` |
| `/c` | *(fixed)* | CPP | |
| *(verbatim)* | `buildoptions { "..." }` | CPP | escape hatch, emitted after `/c` |

Per-file additions (`# ADD CPP` under a `files:` filter): `defines`,
`undefines`, `includedirs`, `buildoptions` (escape hatch), and the
`pchsource` `/Yc`.

## Resource compiler (`rc.exe`)

| VC6 flag | premake5 API | Where | Notes |
|---|---|---|---|
| `/l 0x409` | *(default)* | RSC | en-US; `locale` unset |
| `/l 0xNNN` | `locale "cs-CZ"` etc. | RSC | MS LCID, via `vstudio.cultureForLocale` |
| `/d "NDEBUG"`\|`/d "_DEBUG"` | `symbols` (`Off`/`On`) | RSC | automatic marker |
| `/d "DEF"` | `defines` / `resdefines` | RSC | defines first, then resdefines; a script-declared marker replaces the automatic one |
| `/i "dir"` | `includedirs` / `resincludedirs` | RSC | includedirs first |
| *(verbatim)* | `resoptions { "..." }` | RSC | escape hatch |

## Linker (`link.exe`, non-static kinds)

| VC6 flag | premake5 API | Where | Notes |
|---|---|---|---|
| *(bare names)* | `links` (external libs only) | LINK32 | sibling projects become `.dsw` dependencies; `.lib`/`.obj` kept, else `.lib` appended |
| `/nologo` | *(fixed)* | LINK32 | |
| `/nodefaultlib:"x.lib"` | `ignoredefaultlibraries` | LINK32 | |
| `/entry:"name"` | `entrypoint` | LINK32 | exe kinds only; empty/unset emits nothing |
| `/subsystem:console` | `kind "ConsoleApp"` | LINK32 | |
| `/subsystem:windows` | `kind "WindowedApp"` | LINK32 | |
| `/dll` | `kind "SharedLib"` | LINK32 | |
| `/debug` | `symbols "On"` | LINK32 | |
| `/incremental:yes` | `incrementallink "On"` | LINK32 | |
| `/incremental:no` | `incrementallink "Off"` | LINK32 | unset emits nothing |
| `/machine:I386` | *(fixed)* | LINK32 | VC6 is x86-only |
| `/implib:"..."` | `cfg.linktarget` | LINK32 | dll only; absent with `useimportlib "Off"` |
| `/out:"..."` | `cfg.buildtarget` | LINK32 | baked premake5 target |
| `/pdb:"..."` | `symbolspath` | LINK32 | symbols on and `debugformat` not `c7` |
| `/pdbtype:sept` | `symbols "On"` | LINK32 | |
| `/map` | `mapfile "On"` | LINK32 | |
| `/map:"file"` | `mapfilepath "file"` | LINK32 | only with `mapfile "On"` |
| `/profile` | `profile "On"` | LINK32 | |
| `/libpath:"dir"` | *(fixed)* + `libdirs` + `syslibdirs` | LINK32 | target's own dir first, then libdirs, then syslibdirs |
| *(verbatim)* | `linkoptions { "..." }` | LINK32 | escape hatch, emitted last |

## Librarian (`link.exe -lib`, `StaticLib`)

| VC6 flag | premake5 API | Where | Notes |
|---|---|---|---|
| `/nologo` | *(fixed)* | LIB32 | |
| `/out:"..."` | `cfg.buildtarget` | LIB32 | |

## Structural / fixed tokens

| Token | Source |
|---|---|
| `CPP=cl.exe`, `RSC=rc.exe` | fixed |
| `MTL=midl.exe` + `/nologo /D "SYM" /mktyplib203 /win32` | fixed, only for `WindowedApp`/`SharedLib` |
| `BSC32=bscmake.exe` + `/nologo` | fixed |
| `# TARGTYPE`, `CFG=`, `!MESSAGE`, `# PROC`/`# PROP` lines | fixed; `Use_Debug_Libraries` and `Ignore_Export_Lib` follow `runtime`/`useimportlib` |
| `PreLink_Cmds` / `PostBuild_Cmds` | `prebuildcommands`+`prelinkcommands` / `postbuildcommands` |
| `SOURCE=`, groups, `# Begin Custom Build` | `files`, `vpaths`, `excludefrombuild`, `buildcommands`/`buildoutputs` |
| `Project:` / `Project_Dep_Name` | workspace/project layout, `links`/`dependson` |

## Escape-hatch-only flags

These VC6 switches have a direct premake5 API in the wider ecosystem,
but the module does not map them: they are reached verbatim through
`buildoptions` (the escape hatch). `tests/test_vs6_coverage.lua` proves
the hatch carries them.

| premake5 API | VC6 flag it corresponds to | Status |
|---|---|---|
| `callingconvention` | `/Gd` (Cdecl), `/Gr` (FastCall), `/Gz` (StdCall) | escape hatch; `VectorCall`/`/Gv` is post-VC6 |
| `structmemberalign` | `/Zp1` `/Zp2` `/Zp4` `/Zp8` `/Zp16` | escape hatch |
| `stringpooling` | `/GF` (On), `/GF-` (Off) | escape hatch |
| `intrinsics` | `/Oi` | escape hatch |
| `functionlevellinking` | `/Gy` (On); `/Gy-` is post-VC6 | escape hatch |
| `unsignedchar` | `/J` | escape hatch |
| `compileas` | `/TC` (C), `/TP` (C++) | escape hatch |
| `inlining` | `/Ob0` `/Ob1` `/Ob2` | escape hatch |

The single-flag enums above are registered by premake-core's `vstudio`
module (not core), so a standalone module cannot own them without
shadowing; the VC6 forms are nevertheless reachable and covered.

## premake5 APIs with no VC6 equivalent

These are documented as unmappable, not silently dropped. Where noted,
the corresponding text is emitted by the escape hatch instead.

| premake5 API | Reason |
|---|---|
| `cdialect`, `cppdialect` | `/std:*` did not exist in VC6 (C++98 only) |
| `vectorextensions` | `/arch:SSE*` predates VC6; no x86 SIMD arch flag |
| `floatingpoint` | `/fp:fast|strict|precise` arrived with VS2005; VC6 has no `/fp:` |
| `exceptionhandling "SEH"` | `/EHa` arrived with VS2005 (VC6 has only `/GX`) |
| `rtti "Off"` disable switch | `/GR-` arrived with VS2005; the module only omits `/GR` |
| `warnings "Everything"` | `/Wall` arrived later; mapped to `/W4` (highest VC6 level) |
| `symbols "FastLink"` / `"Full"` | beyond VC6's `/Zi`/`/ZI`/`/Z7` |
| `debugformat "Dwarf"` / `"SplitDwarf"` | non-Windows formats |
| `multiprocessorcompile` | `/MP` arrived with VS2008 |
| `linktimeoptimization` | `/GL` / `/LTCG` arrived with VS2005 |
| `justmycode` | `/JMC` arrived later |
| `openmp` | `/openmp` arrived later |
| `usestandardpreprocessor` | `/Zc:preprocessor` arrived later |
| `sanitize` | `/fsanitize=*` arrived much later |
| `clr` | managed extensions had no VC6 compiler switch |
| `externalwarnings`, `externalanglebrackets` | `/external:*` arrived later |
| `manifest` | no manifest tooling in VC6 |
| `wholearchive` | `/WHOLEARCHIVE` arrived later |
| `usefullpaths`, `enableunitybuild`, `enablemodules` | premake5 features with no VC6 analogue |
| `/machine:ALPHA` | quake2 residual: VC6 can target ALPHA, but premake5 bakes I386 and exposes no API to select it (documented in `experiments/quake2/NOTES.md`) |

## Legality rules honored by the writer

| Rule | Behavior |
|---|---|
| `/ZI` is illegal with optimization | `symbols "On"` + any optimized `optimize` emits `/Zi`, never `/ZI` (`vs6.debugFlag`) |
| `/ZI` needs edit-and-continue | `editandcontinue "Off"` emits `/Zi` |
| `debugformat "c7"` | emits `/Z7` and suppresses the link `/pdb:` file |
| `/GZ` only with the debug runtime | emitted after `/FD` only for `/MDd`/`/MTd`; `runtime "Release"` omits it |
| `/implib` absent with `useimportlib "Off"` | no `/implib:` and adds `# PROP Ignore_Export_Lib 1` |
| `rtti "Off"` / `exceptionhandling "Off"` | simply omit `/GR` / `/GX` (no negative form on VC6) |
| static library | uses `LIB32=link.exe -lib` + `/out:`; no `LINK32` flags, no `MTL` |

## Coverage-suite subset

The full cross-product of the reachable options is in the thousands. The
`vs6_coverage` suite uses a greedy **pairwise** construction over the
input dimensions (every pair of `option=value` assignments from distinct
dimensions appears in at least one case): 50 compiler cases, 26 linker
cases and 26 resource cases, plus explicit tests for the legality rules
and the escape hatch. This keeps the suite small while still catching
interaction and ordering bugs. Dimensions whose flags land in
independent, fixed positions are already pinned individually by the
per-feature suites; the pairwise oracle re-derives the exact
CPP/RSC/LINK32 strings from this matrix so interaction regressions still
fail.
