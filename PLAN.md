# PLAN: Visual C++ 6.0 (vs6) exporter for Premake5

## Status: v1 complete (premake 3.x parity)

The module is implemented and verified:

- `premake5 vs6` generates `.dsw`/`.dsp` for C/C++ projects, Win32 only.
  Layout: `_preload.lua` (action), `vs6.lua` (entry + shared helpers),
  `vs6_dsw.lua`, `vs6_dsp.lua`.
- Output is byte-identical to the premake 3.7 oracle on
  `samples/premake5.lua` after normalizing path separators (module always
  emits `\`) and line endings (module always emits CRLF). Reproduce with
  `tests/e2e.sh`.
- All 75 premake 3.x Vs6 NUnit tests are ported to premake5-native suites
  (15 `vs6_*` suites) plus 7 module-specific edge tests: 82 green via
  `bin/release/premake5 test --test-only=vs6*` from a premake-core
  checkout with this repo linked into `premake-core/modules/vs6`. The full
  premake-core suite passes with the module linked in.

Current behavior contract (deliberate 3.x-parity divergences from
premake5-native conventions — details in README.md): raw
`targetdir`/`objdir` semantics with buildcfg always appended to objdir;
3.x `libdir` mapped to `targetdir` (exe/StaticLib) and `implibdir` (DLL
implibs); symbols on by default; `/entry:"mainCRTStartup"` unless
`entrypoint` is set; sibling `links` become .dsw dependencies only;
configs stored in reverse order with the rotated `Use_Debug_Libraries`
quirk; `prebuildcommands`/`dependson`/premake5-only `optimize`/`warnings`
values ignored with warnings; non-Win32 platforms rejected.

## Reference material

- `tests/golden/` — premake 3.7 Windows-oracle output for the sample
  (CRLF, `-text` in .gitattributes). Regenerate on Windows with
  `$P3/bin/premake.exe --file premake.lua --target vs6` in `samples/`.
- `../premake-sources/` (premake-3.x + premake-core checkouts) was the
  reference area and can be deleted; everything relevant has been ported.
  A premake-core checkout is still needed to run the unit tests (see
  README).

## Not yet validated (need a Windows machine)

- Open the generated sample in a real VC6 IDE.
- beta7-binary spot-check (module loads + generates simple projects);
  best-effort only.

## Next steps (post-v1)

- **premake5-native defaults, behind a switch.** Trust baked
  `cfg.buildtarget`/`cfg.linktarget`: `targetdir` unset → `bin/<buildcfg>`,
  no forced buildcfg suffix on explicit `objdir`. This breaks oracle
  parity and the ported tests that pin 3.x defaults (`vs6_outputdirs`,
  `vs6_target`, `vs6_importlib`), so it needs a module option or
  major-version bump and re-baselined tests. Decide the switch mechanism
  first.
- **`entrypoint` premake5 semantics**: only emit `/entry:` when
  `entrypoint` is explicitly set (drop the default `mainCRTStartup`).
- **`prebuildcommands`**: fold into `PreLink_Cmds` ahead of
  `prelinkcommands` (closest VC6 semantics; diverges from the oracle, so
  pair with the parity switch).
- **Dependencies**: union `links`-based sibling deps across all configs
  instead of first-config-only (3.x read `prj_select_config(0)` only).
  Note: `config.getlinks(cfg, "dependencies", "object")` requires the
  sibling to have a matching config, which 3.x name-matching did not —
  v1 uses name matching (`workspace.findproject`) for parity.
- **`dependson`**: emit .dsw dependency blocks via
  `project.getdependencies(prj, "dependOnly")` (unions across configs;
  VS doesn't support per-config deps anyway).
- **Value mapping**: cover premake5-only `optimize`/`warnings` values
  properly instead of warn-and-default (e.g. `warnings "Off"` → `/W0`).
- **Embedding**: `_preload.lua` returns the loader filter and
  `include()` is idempotent, so the module can be embedded into a
  premake-core build later (manifest is in `_manifest.lua`).

## Implementation notes (load-bearing for future edits)

- External-module flow: the action registers during `runUserScript`,
  after `prepareAction`, so `_preload.lua` re-runs `p.action.set("vs6")`
  at load to apply `targetos`/`toolset` before baking (otherwise POSIX
  target naming leaks in: `libengine.so`).
- `oven.bakeObjDirs` rewrites `cfg.objdir` to an absolute baked path;
  `vs6.rawvalue`/`vs6.rawpath` re-fetch raw script values via
  `configset.fetch(cfg._cfgset, ...)` and re-relativize to the project
  location. Same for path lists (`includedirs`/`libdirs`/
  `resincludedirs` come back absolute from the oven).
- `p.generate` captures via `buffered.tostring()`, which trims one
  trailing EOL; both writers emit one extra blank line to compensate.
- `prj._.files` is alpha-sorted by vpath; the source tree restores
  script declaration order via `fcfg.order`. It is also the union across
  configs (3.x used config 0's list only) — per-config `removefiles`
  divergence is accepted for v1.
- The `Use_Debug_Libraries` rotation is a genuine 3.7 off-by-one (flags
  read before `prj_select_config`), confirmed present in both the git
  checkout and the released binary; it is required for oracle parity.
- Line endings are `p.eol("\r\n")` + `p.indent("")` set in
  onWorkspace/onProject; all output goes through `p.out`/`p.outln` with
  literal leading whitespace.
