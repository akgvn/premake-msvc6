# PLAN: Visual C++ 6.0 (vs6) exporter for Premake5

## Goal

Create a standalone Premake5 module that adds a `premake5 vs6`
action generating Visual C++ 6.0 workspace (`.dsw`) and project (`.dsp`) files
for C/C++ projects, Win32 only.

This repository IS the module (no subdirectory). `../premake-sources/` (a
sibling of this repo) is a temporary reference checkout area and will be
deleted when the module is done.

## Sources available to you

- **`$P3` = `../premake-sources/premake-3.x/`** — premake 3.7 checkout:
  - `$P3/Src/vs6.c` — the .dsw workspace generator (content spec)
  - `$P3/Src/vs6_cpp.c` — the .dsp project generator (content spec)
  - `$P3/Tests/Vs6/Vs6Parser.cs` — line-by-line parser for .dsw/.dsp, i.e. an
    executable grammar spec of both formats
  - `$P3/Tests/Vs6/**` — 75 NUnit tests; each builds a Lua script, runs premake
    3.7, and validates the generated files. All 75 pass against 3.7.
- **`$P5` = `../premake-sources/premake-core/`** — premake5 source checkout
  (post-beta7 dev snapshot; has vs2026/slnx support).

Paths below are written relative to `$P3` / `$P5`.

### The premake 3.7 oracle

A prebuilt 3.7 binary already exists: `$P3/bin/premake.exe` (reports itself as
"premake 3.7", Windows only). Use it to cross-check module output (normalized
diff, see Step 5). On Linux, build a native binary from the same checkout —
`$P3/Src/Makefile` already has posix branches and compiles `platform_posix.c`:

```sh
cd $P3/Src && make CONFIG=Release   # GNU make + gcc (MinGW or Linux)
# produces ../bin/premake.exe (Windows) or ../bin/premake (Linux)
```

Note: the `$P3`-root Makefile tries to regenerate itself using an existing
premake binary; run make directly inside `Src/` instead.

Host-OS output difference: `io.c:164` opens output files with text-mode
`fopen(path, "w")` and the writers emit `\n`, so the Windows oracle writes
CRLF while a Linux-built oracle writes LF. The Step 5 normalized diff
canonicalizes line endings to absorb this (module output is always CRLF via
explicit `p.eol("\r\n")`, regardless of host). Golden fixtures captured on
Windows are in `tests/golden/` — see Step 5.

## Step 0 — Build premake5 (prerequisite)

`$P5` contains no prebuilt binary; build one before anything else.

Windows — Visual Studio 2026 Community is installed (vswhere:
productLineVersion `18`, at `C:\Program Files\Microsoft Visual Studio\18\Community`)
and is supported by the bootstrap script:

```bat
cd $P5
Bootstrap.bat vs18        REM or bare "Bootstrap.bat" (auto-detects latest VS)
REM produces bin\release\premake5.exe
```

Linux:

```sh
cd $P5 && ./Bootstrap.sh    # = make -f Bootstrap.mak linux
# produces bin/release/premake5
```

Notes:

- On Windows, the winget-installed `premake5 5.0.0-beta7` is also on PATH.
  Prefer the freshly built binary for development and for running `$P5`'s
  test suite — the checkout's scripts may use APIs newer than beta7. Use the
  beta7 binary only for the compatibility spot-check (see OQ-9); that check
  is Windows-only.

## Deliverable layout

Standalone external module at the repo root, NOT a premake-core fork. The
user's script calls `require "vs6"`, resolved via `--scripts=<repo-root>` or
any module search path:

```
/ (repo root)
  _preload.lua     -- newaction registration (NOT auto-run for external
                     modules; vs6.lua includes it explicitly — see Step 1)
  _manifest.lua    -- file manifest (so it can be embedded later if wanted)
  vs6.lua          -- module entry: p.modules.vs6, shared helpers;
                     first line: include("_preload.lua")
  vs6_dsw.lua      -- workspace writer  (ports $P3/Src/vs6.c)
  vs6_dsp.lua      -- project writer    (ports $P3/Src/vs6_cpp.c)
  tests/
    _tests.lua     -- test suite registration
    test_vs6_*.lua -- premake5-native tests
    golden/        -- oracle outputs from samples/, committed as E2E fixtures
                     (CRLF bytes preserved via .gitattributes "-text")
  samples/
    premake.lua    -- E2E sample, premake 3.x syntax (oracle input)
    premake5.lua   -- same workspace, premake5 syntax (module input)
```

(`../premake-sources/` holds the reference checkouts, outside the repo.)

Module-dir naming note: for `require "vs6"` to resolve, the module directory
must be named `vs6` on premake's module search path (e.g. junction/copy to
`%USERPROFILE%\.premake\modules\vs6`). Users of this repo can instead pass
`--scripts=<repo-root>` and call `require "vs6"` from their own script
(verified working with the self-registering `vs6.lua`).

## Step 1 — Action skeleton (`_preload.lua`)

Primary model: `$P5/modules/vstudio/vs2005.lua:83-121` — a format-only IDE
generator like ours (secondary reference: `$P5/modules/gmake/_preload.lua`).

**Critical:** `_preload.lua` is only auto-executed for *embedded* modules
(`$P5/src/_premake_main.lua:124-139` iterates a fixed manifest without vs6);
for an external module, `require "vs6"` loads only `vs6.lua` and the action
never registers (verified: "no such action 'vs6'"). Fix: the first line of
`vs6.lua` is `include("_preload.lua")`. This is idempotent — `include()`
caches by absolute filename ($P5/src/base/globals.lua:48-64) — so it stays
correct if the module is ever embedded. Related: in the external flow
`onInitialize` never fires (action preparation runs before the user script
registers the action); keep it for future embedding but rely on nothing
outside the onWorkspace/onProject callbacks.

- `newaction { trigger = "vs6", shortname = "Visual Studio 6", ... }`
- `targetos = "windows"`, `toolset = "msc"`,
  `valid_tools = { cc = { "msc" } }` — matches vstudio's pattern
  (resolves OQ-10)
- `valid_kinds = { "ConsoleApp", "WindowedApp", "SharedLib", "StaticLib" }`
- `valid_languages = { "C", "C++" }` — premake5 rejects unsupported
  kinds/languages for free (replaces the manual C# error in vs6.c:46)
- `onInitialize = function() require("vs6") end`
- `onWorkspace = function(wks) ... p.generate(wks, ".dsw", p.modules.vs6.generateWorkspace) end`
- `onProject = function(prj) ... p.generate(prj, ".dsp", p.modules.vs6.generateProject) end`
- Inside onWorkspace/onProject, before generating: `p.indent("")` and
  `p.eol("\r\n")` — the latter is the CRLF mechanism (resolves OQ-1; pattern
  at vs2005.lua:19-21). Indent strategy is pinned (OQ-18): `p.indent("")` +
  literal line text via `p.out`/`p.outln` everywhere — 3.x embeds its leading whitespace
  literally (e.g. vs6.c:124), so indent must stay empty for byte parity.
  `p.generate(obj, ext, fn)` composes the output path as
  `obj.location or obj.basedir` + `obj.filename` + `ext`
  ($P5/src/base/premake.lua:155,226) and only writes when content changed, so
  .dsw lands at workspace location and .dsp at project location, like 3.x
  (resolves OQ-2).
- Do NOT register `onCleanWorkspace`/`onCleanProject`: `p.clean.file` does
  not exist in this snapshot and the `clean` action is an unported stub
  ($P5/src/actions/clean/_clean.lua just prints "not yet been ported";
  nothing calls the onClean* callbacks). gmake/vstudio's clean handlers are
  dead code referencing undefined functions — don't copy that pattern.
- No `p.escaper` call: it is an output-escaping hook
  ($P5/src/base/premake.lua:130) applied by `p.esc(value)`; vstudio installs
  an XML escaper because .vcxproj/.sln are XML, gmake installs a make escaper.
  Default is the identity no-op, and .dsp/.dsw are plain text — leave it
  alone and don't use `p.esc()`.
- End of file: `return function(cfg) return (_ACTION == "vs6") end`

## Step 2 — `.dsw` writer (port `$P3/Src/vs6.c`)

- Static header: `Microsoft Developer Studio Workspace File, Format Version 6.00`
  + warning comment + `###...` separator (exact text in vs6.c:67-71)
- Per project:
  `Project: "name"=<dsp path relative to workspace location> - Package Owner=<4>`
  followed by `Package=<5>` / `Package=<4>` blocks (vs6.c:77-93)
- Dependencies: inside `Package=<4>`, one
  `Begin Project Dependency` / `Project_Dep_Name X` / `End Project Dependency`
  block per linked sibling project. In premake5 use
  `config.getlinks(cfg, "dependencies", "object")` or equivalent rather than
  string-matching `links`; use the first config only, like 3.x
  (`prj_select_config(0)`, vs6.c:87) — see OQ-6.
- Static `Global:` footer (vs6.c:96-107).

## Step 3 — `.dsp` writer (port `$P3/Src/vs6_cpp.c`)

Exact output text matters; `$P3/Tests/Vs6/Vs6Parser.cs` is the authoritative
grammar. Sections, in order:

1. Header: `# Microsoft Developer Studio Project File - Name="..."`, format
   comment, `# TARGTYPE` mapped by kind (vs6_cpp.c:40-64):
   ConsoleApp→`"Win32 (x86) Console Application" 0x0103`,
   WindowedApp→`"Win32 (x86) Application" 0x0101`,
   SharedLib→`"Win32 (x86) Dynamic-Link Library" 0x0102`,
   StaticLib→`"Win32 (x86) Static Library" 0x0104`.
2. `CFG=<name> - Win32 <first config>` and the `!MESSAGE` block listing all
   configs **in reverse order** (vs6_cpp.c:89-93).
3. `# Begin Project` + the three fixed header props
   (`# PROP AllowPerConfigDependencies 0`, `# PROP Scc_ProjName ""`,
   `# PROP Scc_LocalPath ""` — vs6_cpp.c:98-100; the parser pins all three,
   Vs6Parser.cs:181-183); `CPP=cl.exe`, `MTL=midl.exe` (except StaticLib),
   `RSC=rc.exe`.
4. Per-config `!IF`/`!ELSEIF` chain, again **configs in reverse order**
   (vs6_cpp.c:107-198): PROP BASE/PROP output+intermediate dirs,
   `Use_Debug_Libraries` when not optimizing, `Ignore_Export_Lib` for
   no-import-lib DLLs, then:
   - `# ADD BASE CPP /nologo ...` and identical `# ADD CPP /nologo ...`
     (port `writeCppFlags`, vs6_cpp.c:225-276; flag order is significant)
   - MTL block for WindowedApp/SharedLib with `_DEBUG`/`NDEBUG`
   - RSC block: `/l 0x409 /d "<DEBUGSYMBOL>"` + resdefines (`/d`) +
     resincludedirs (`/i`) + resoptions
   - `BSC32=bscmake.exe` block
   - StaticLib: `LINK32=link.exe -lib` + `# ADD LIB32 /nologo /out:"..."`;
     otherwise `# ADD BASE LINK32` + `# ADD LINK32`
     (port `writeLinkFlags`, vs6_cpp.c:283-334)
   - Special Build Tool: `PreLink_Cmds=` / `PostBuild_Cmds=` (tab-separated)
     when prelink/postbuild commands exist (vs6_cpp.c:178-195)
5. `!ENDIF`, `# Begin Target`, `# Name "..."` per config (reverse order).
6. Source tree via premake5's `p.tree.traverse` (file-tree pattern: see the
   vstudio file-section writers, e.g. `$P5/modules/vstudio/vs2005_dotnetbase.lua:219`):
   `# Begin Group "name"` + `# PROP Default_Filter ""` / `# End Group`,
   files as `# Begin Source File` / `SOURCE=<relpath>` / `# End Source File`.
   3.x skips group roots that are `..` (vs6_cpp.c:370).
7. `# End Target`, `# End Project`.

### Field mapping (3.x flag -> premake5 API -> VC6 output)

| 3.x flag        | premake5 API                    | VC6 output                                        |
|-----------------|---------------------------------|---------------------------------------------------|
| optimize-size   | `optimize "Size"`               | `/O1`                                             |
| optimize(-speed)| `optimize "On"` / `"Speed"`     | `/O2`                                             |
| (no optimize)   | default                         | `/Od`, `Use_Debug_Libraries 1`, `/Gm /GZ /ZI`, `_DEBUG` |
| static-runtime  | `staticruntime "On"`            | `/MT(d)` instead of `/MD(d)`                      |
| extra-warnings  | `warnings "Extra"`              | `/W4` (else `/W3`)                                |
| fatal-warnings  | `fatalwarnings { "All" }`       | `/WX`                                             |
| no-rtti         | `rtti "Off"`                    | omit `/GR`                                        |
| no-exceptions   | `exceptionhandling "Off"`       | omit `/GX`                                        |
| no-symbols      | `symbols "Off"`                 | omit `/ZI`, `/incremental:yes /debug`, `/pdbtype:sept`; use `NDEBUG` |
| no-frame-pointer| `omitframepointer "On"`         | `/Oy`                                             |
| no-import-lib   | `useimportlib "Off"` (+ dual-read `cfg.flags.NoImportLib` in module code for older binaries) | `# PROP Ignore_Export_Lib 1`, `/implib` -> objdir |
| no-main         | see OQ-3                        | omit `/entry:"mainCRTStartup"`                    |
| defines         | `defines`                       | `/D "X"`                                          |
| includepaths    | `includedirs`                   | `/I "X"`                                          |
| libpaths        | `libdirs`                       | `/libpath:"X"`                                    |
| links           | `links`                         | sibling projects -> .dsw deps ONLY (VC6 links implicitly); other libs -> `name.lib` in LINK32 |
| buildoptions    | `buildoptions`                  | appended raw to CPP lines                         |
| linkoptions     | `linkoptions`                   | appended raw to LINK32 lines                      |
| resdefines/respaths/resoptions | `resdefines`/`resincludedirs`/`resoptions` | RSC line |
| target/out dirs | raw `cfg.targetdir`/`cfg.objdir` (NOT baked `cfg.buildtarget` — see OQ-14) | `/out:`, `Output_Dir`, `Intermediate_Dir` |
| importlibname   | `implibname`/`implibdir`        | `/implib:` — see algorithm below                  |
| prelink/postbuild commands | `prelinkcommands`/`postbuildcommands` | Special Build Tool (`PreLink_Cmds=`/`PostBuild_Cmds=`, tab-separated) |
| prebuild commands | `prebuildcommands`            | ignored + `p.warn` for v1 (OQ-13); fold into PreLink post-v1 |

Note: the old `flags` API is removed in the `$P5` snapshot (no `flags`
registration anywhere in `$P5/src`) — `fatalwarnings`, `omitframepointer`,
`useimportlib` are its replacements. On the on-PATH beta7 binary the state
is mid-transition (`flags {"NoFramePointer"}` already errors, `useimportlib`
doesn't exist yet, `flags {"NoImportLib"}` still works), so no single
user-script syntax exercises no-import-lib on both binaries — module code
dual-reads, test scripts target the `$P5` snapshot. premake5-only values
with no 3.x equivalent (`optimize "Off"/"Debug"/"Full"`,
`warnings "Off"/"High"/"Everything"`) are handled per OQ-15.

### Hardcoded output not driven by any flag (must always be emitted)

The mapping table above is NOT the whole writer. `writeCppFlags` /
`writeLinkFlags` also emit fixed text that must be reproduced verbatim:

- Every CPP line ends: `/YX /FD /c` (plus `/GZ` when not optimizing, `/Gm`
  when using debug libraries — both already keyed off optimization above).
- LINK32 always: `/nologo /machine:I386`, plus `/entry:"mainCRTStartup"` for
  exe kinds unless suppressed (OQ-3).
- Kind-driven LINK32: WindowedApp→`/subsystem:windows`,
  ConsoleApp→`/subsystem:console`, SharedLib→`/dll`; StaticLib uses
  `LINK32=link.exe -lib` and LIB32 lines instead of LINK32.
- When symbols on: `/incremental:yes /debug` and `/pdbtype:sept`.
- LINK32 ends with `/libpath:"<libdir>"` (the target/import-lib dir) followed
  by `libdirs` and `linkoptions`.
- Target paths on `/out:` come from 3.x `prj_get_target()` (outdir + target
  name, relative to project) — compose from the raw `cfg.targetdir`/
  `cfg.buildtarget.basename` per OQ-14; do not trust baked
  `cfg.buildtarget.relpath` defaults (they inject `bin/<buildcfg>`).

### Import library path algorithm (`/implib:`, vs6_cpp.c:303-322)

More than a one-line mapping — 3.x builds the path as follows:

- If `no-import-lib`: `/implib:"<objdir>/<name>.lib"`
- Else: `/implib:"<libdir>[/<targetdir>]/<name>.lib"` where `<targetdir>` is
  the directory component of the raw target path (appended only if non-empty)
- `<name>` = `importlibname` if set, else basename of the target file

premake5 sources: the oven DOES bake `cfg.linktarget` for every config
($P5/src/base/oven.lua:886-887 — for SharedLib it holds the implib info),
but its defaults are premake5-native (directory falls back to `targetdir`,
then `<location>/bin/<buildcfg>`; `$P5/src/base/config.lua:31-70`), which is
NOT 3.x's libdir-based path. So compute the implib path from raw
`cfg.implibdir`/`cfg.implibname` (falling back per OQ-14's libdir rule) and
`cfg.objdir` rather than trusting `cfg.linktarget`. Verify against
`Test_ImportLib` (2 tests) and the oracle.

## Step 4 — Testing (premake5-native)

Use premake5's built-in Lua test harness (`test.declare` to create suites,
`suite.setup` for fixtures — called by the runner, test_runner.lua:238-241 —
and `test.capture(...)` to compare exact generated text; this subsumes the
old line-by-line C# parser approach). The `prepare()`/`run()` seen in
existing test files are per-file local conventions, not harness APIs.

Port all 75 tests from `$P3/Tests/Vs6/` (note: `Test_Packages`/`Test_Paths`
live directly in `Tests/Vs6/`, everything else in `Tests/Vs6/Cpp/`):

- workspace: `Test_Packages` (3), `Test_Paths` (5), `Test_Dependencies` (2)
- dsp header/kinds: `Test_Kinds` (5)
- flags: `Test_BuildFlags` (14), `Test_BuildOptions` (3), `Test_Defines` (4),
  `Test_IncludePaths` (4)
- link: `Test_Links` (3), `Test_LibPaths` (4), `Test_Target` (8),
  `Test_ImportLib` (2)
- output dirs: `Test_OutputDirs` (8)
- resources: `Test_Resources` (7)
- files/groups: `Test_Files` (3)

Total: 3+5+2+5+14+3+4+4+3+4+8+2+8+7+3 = 75.

Running the suite (resolved OQ-4): premake5's self-test discovers tests by
globbing `<main-script-dir>/**/tests/_tests.lua`
($P5/modules/self-test/self-test.lua:75), so `--scripts` alone does NOT make
an external module's tests visible. Junction the repo root into the
premake-core checkout:

```bat
REM one-time (Windows):
mklink /J $P5\modules\vs6 <repo-root>
```

```sh
# one-time (Linux):
ln -s <repo-root> $P5/modules/vs6
```

```bat
REM run:
cd $P5
bin\release\premake5.exe test                        REM full suite
bin\release\premake5.exe test --test-only=vs6*       REM just ours
```

(on Linux: `bin/release/premake5` — same arguments.)

A direct repo-root junction is safe: `os.matchfiles` follows junctions, but
the repo contains no nested checkouts with their own `tests/` directories
(`premake-sources/` lives outside the repo), so no duplicate suite
declarations reach the runner (duplicates hard-error in
test_declare.lua:34-37 before `--test-only` filtering can help). The junction
also means edits are live — no staging copy to re-sync. One-time spike on
Linux: confirm `os.matchfiles` follows the symlink the same way (expected —
junctions were followed on Windows — but verify before relying on it).

Suites are named per category with a `vs6_` prefix (`vs6_workspace`,
`vs6_dsp_flags`, ...) — `--test-only` matches exact suite names or `*`
wildcards ($P5/modules/self-test/test_declare.lua:127-188), hence `vs6*`
(OQ-17). Document the working command in the module README when done.

## Step 5 — End-to-end validation

The sample pair already exists (written on Windows before the Linux switch):
`samples/premake.lua` (3.x syntax) and `samples/premake5.lua` (premake5
syntax) describe the same workspace — 4 projects covering all 4 kinds,
dependencies, Debug/Release, defines/includedirs/libdirs/links, resources,
pre/post-build commands (`prebuildcommands` included — v1 ignores them with a
warning, matching the oracle, so the diff stays clean). No `useimportlib` in
the sample — no single syntax works on both premake5 binaries (see OQ-9);
no-import-lib is covered by the ported unit tests instead.

Golden fixtures: the 3.7 Windows oracle output for `samples/premake.lua` is
committed at `tests/golden/` (`Sample.dsw` + 4 `.dsp`, CRLF bytes preserved
via `.gitattributes` `-text`). To regenerate: run
`$P3/bin/premake.exe --file premake.lua --target vs6` in `samples/` and move
the outputs over.

1. Run the module on `samples/premake5.lua`.
2. Diff module output against the golden fixtures with a **normalized diff**:
   canonicalize path separators (module emits backslashes per OQ-7, oracle
   emits forward slashes) AND line endings (Windows oracle/goldens are CRLF;
   a Linux-built oracle emits LF — see the oracle section). Everything else
   should match byte-for-byte.
3. Cross-check against a live oracle where available (native Linux build of
   3.7, or the Windows binary in a VM/Wine) — the goldens are the primary
   baseline, so E2E doesn't depend on oracle portability.
4. If available, open the result in a real VC6 IDE (Windows only).

## Suggested implementation order

0. Build premake5 (Step 0); set up the test junction/symlink (Step 4)
   — DONE: sample scripts written and golden oracle fixtures captured to
   `tests/golden/` on Windows (Step 5)
1. Skeleton + spike the open questions marked **SPIKE** below
2. `.dsp` CPP flag block + its tests
3. LINK32/LIB32/RSC/MTL + tests
4. Source tree + tests
5. `.dsw` + dependencies + tests
6. E2E oracle diff, polish

## Out of scope for v1 (matching premake 3.x behavior)

- Per-file compiler settings (3.x never emitted them)
- `.mak` export
- C# (VS6 has no C# support)
- Non-x86 platforms (VS6 is Win32-only)

## Open questions / decisions

### Resolved

- **OQ-1: Line endings — RESOLVED.** `p.eol("\r\n")` (+ `p.indent`), set at the
  top of onWorkspace/onProject; vstudio does exactly this (vs2005.lua:19-21).
- **OQ-2: `p.generate` — RESOLVED.** Signature `p.generate(obj, ext, callback)`
  ($P5/src/base/premake.lua:155); filename via `p.filename` = `obj.location or
  obj.basedir` + `obj.filename` + ext (premake.lua:226); captures output and
  writes only if changed.
- **OQ-4: Running module tests — RESOLVED.** Junction the repo root directly
  into `$P5\modules\vs6` (safe now that `premake-sources/` lives outside the
  repo and can't break discovery), run `bin\release\premake5.exe test` from
  `$P5` (see Step 4). `--scripts` alone cannot work: test discovery globs
  under `_MAIN_SCRIPT_DIR`.
- **OQ-7: Path separators — DECIDED.** Emit backslashes
  (`path.translate(p, "\\")`); quoting of paths with spaces in `/I`,
  `/libpath:`, `/out:`, `/implib:` still needs verification during
  implementation. E2E comparison uses a normalized diff (Step 5).
- **OQ-9: Version floor — DECIDED (redefined).** The floor is "the APIs
  present in the `$P5` snapshot" — develop and test against the binary built
  from `$P5` (Step 0). The winget binary reporting `5.0.0-beta7` is in fact a
  post-beta7-tag dev build (premake only bumps `_PREMAKE_VERSION` at
  releases) caught mid-transition between API sets (`flags {"NoFramePointer"}`
  already errors, `useimportlib` absent, `flags {"NoImportLib"}` still
   works), so "beta7 compatibility" is not a fixed, knowable target. Keep a
   best-effort dual-read of `cfg.flags.NoImportLib` in module code; demote the
   beta7-binary check to "module loads and generates simple projects" — an
   opportunistic check, only possible on Windows (winget binary). No
   single user-script syntax exercises no-import-lib on both binaries.
- **OQ-10: `valid_tools` — RESOLVED.** Declare
  `valid_tools = { cc = { "msc" } }` plus `toolset = "msc"` and
  `targetos = "windows"`, following vstudio (vs2005.lua:92-102). Harmless and
  correct for a format-only generator.
- **OQ-3: `entrypoint` semantics — DECIDED (3.x parity for v1).** premake5 has
  an `entrypoint` string API ($P5/src/_premake_init.lua:309) but no `NoMain`
  flag. v1 matches the oracle: nil entrypoint → emit
  `/entry:"mainCRTStartup"` for exe kinds, `entrypoint ""` → suppress,
  `entrypoint "X"` → `/entry:"X"`. Post-v1 TODO: switch to premake5 semantics
  (only emit `/entry:` when `entrypoint` is explicitly set).
- **OQ-5: Platform handling — DECIDED (fail fast).** When the script sets no
  `platforms`, `cfg.platform` is nil and output is naturally Win32-only — no
  code needed for the common case. There is no `valid_platforms` hook in
  `newaction` (checked $P5/src/base/action.lua; only kinds/languages/tools
  exist), so validate in the generate path: if `cfg.platform` is set and not
  `x86`/`Win32`, `error()` with a clear message (a bad platform would
  otherwise silently produce garbage config names like `Debug x64`).
- **OQ-13: `prebuildcommands` — DECIDED (ignore + warn for v1).** VC6 has no
  pre-build step and 3.x ignored prebuild commands entirely. v1: ignore them
  (exact 3.x parity, clean oracle diff) and emit a `p.warn` so users aren't
  silently dropped. Post-v1 TODO: fold them into `PreLink_Cmds` ahead of
  `prelinkcommands` (closest VC6 semantics, but diverges from the oracle).
- **OQ-14: Default-directory semantics — DECIDED (3.x parity for v1).** Baked
  premake5 defaults diverge from the oracle: unset `targetdir` →
  `<location>/bin/<buildcfg>` vs 3.x `.`; unset `objdir` → `obj` vs 3.x
  `obj/<buildcfg>`; an explicit `objdir = "temp"` is used as-is vs 3.x
  `temp/<buildcfg>` (config name always appended). The ported tests
  (`Test_OutputDirs`, `Test_Target`, `Test_ImportLib`) pin the 3.x defaults,
  so v1 reads RAW `cfg.targetdir`/`cfg.objdir` (nil → 3.x defaults) and
  always appends the buildcfg name to objdir — document this as a deliberate
  divergence from premake5-native expectations. 3.x's separate `libdir`
  (lib output dir; drives `/libpath:"<libdir>"`, StaticLib `Output_Dir`, DLL
  implib dir) maps to: `cfg.implibdir` for DLL implibs, the target's own dir
  for StaticLib/exe. Post-v1 TODO: switch to premake5-native defaults.
- **OQ-15: Unmapped API values — DECIDED (warn + default for v1).** premake5
  values with no 3.x equivalent (`optimize "Off"/"Debug"/"Full"`, `warnings
  "Off"/"High"/"Everything"`): `p.warn` and fall back to the 3.x default
  behavior for that setting. Fuller mapping (e.g. `warnings "Off"` → `/W0`)
  is a post-v1 TODO.
- **OQ-16: `dependson` — DECIDED (ignore + warn for v1).** premake5's
  `dependson` (dependency without linking) has no 3.x equivalent; v1 ignores
  it with a `p.warn` (consistent with OQ-13). Post-v1: emit .dsw dependency
  blocks for it via `project.getdependencies(prj, "dependOnly")`
  ($P5/src/base/project.lua:168 — note it unions across configs, and VS
  doesn't support per-config deps anyway).
- **OQ-17: Test suite naming — DECIDED.** Per-category suites prefixed
  `vs6_` (`vs6_workspace`, `vs6_dsp_flags`, ...); documented run command uses
  the wildcard `--test-only=vs6*` (matching is exact-name or `*` glob,
  test_declare.lua:127-188).
- **OQ-18: Indentation strategy — DECIDED.** `p.indent("")` plus literal line
  text via `p.out`/`p.outln` throughout. All 3.x output embeds leading
  whitespace literally (e.g. vs6.c:124 `"    Begin Project Dependency\n"`),
  so any nonzero indent would leak into every line and break byte parity.

### Still open

- **OQ-6: How to find a project's sibling-project dependencies.** The .dsw
  needs, per project, the list of *other projects in the same workspace* it
  depends on. In premake5, `links { "X" }` may name either a sibling project
  or an external/system library — the two must be separated. 3.x did it by
  string-matching each `links` entry against sibling package names
  (vs6.c:119-135). The premake5-idiomatic candidate is
  `config.getlinks(cfg, "dependencies", "object")`, which should return
  resolved project objects instead of raw strings — the call exists
  ($P5/src/base/config.lua:320) and returns sibling *config* objects, but it
  requires the sibling to have a matching config, which 3.x name-matching
  did not — spike the behavior and fall back to 3.x-style name matching if
  needed. Second part (decided): like 3.x, read only the first config's
  links (vs6.c:87 `prj_select_config(0)`; the related
  `# PROP AllowPerConfigDependencies 0` line belongs to the .dsp writer,
  vs6_cpp.c:98 — don't confuse the two); unioning deps across all configs is
  a post-v1 TODO.
- **OQ-8 (SPIKE): Config iteration order.** Confirm `project.eachconfig(prj)`
  order and that reversing it reproduces the 3.x `!IF`-last-config-first
  layout exactly (`CFG=` line and `# Name` lines too).
- **OQ-11 (SPIKE): Tree traversal edge cases.** premake5's `p.tree` groups
  files differently than 3.x's `print_source_tree` for `../` paths; port
  `Test_Files.Test_FilesAboveDir` early to catch divergence.
- **OQ-12 (SPIKE): Tokens in paths.** premake5 scripts commonly use
  `%{cfg.buildcfg}` tokens in `targetdir`/`objdir`. Confirm these are fully
  resolved in `cfg.buildtarget`/`cfg.objdir` at generation time (they should
  be, since the other generators rely on it).

## Post-v1 TODOs

- **Match premake5-native defaults** (don't stay a special snowflake):
  switch default-directory semantics to premake5's (trust baked
  `cfg.buildtarget`/`cfg.linktarget`, `targetdir` unset → `bin/<buildcfg>`,
  no forced buildcfg suffix on explicit `objdir` — see OQ-14). This breaks
  oracle parity and the ported tests that pin 3.x defaults, so it needs a
  versioned switch (module option or major-version bump) and re-baselined
  tests.
- `entrypoint`: switch to premake5 semantics — only emit `/entry:` when
  `entrypoint` is explicitly set (see OQ-3).
- `prebuildcommands`: fold into `PreLink_Cmds` ahead of `prelinkcommands`
  (see OQ-13).
- Dependencies: consider unioning dependency lists across all configs instead
  of first-config-only (see OQ-6).
- `dependson`: emit .dsw dependency blocks (see OQ-16).
- Value mapping: cover premake5-only `optimize`/`warnings` values properly
  instead of warn-and-default (see OQ-15).
