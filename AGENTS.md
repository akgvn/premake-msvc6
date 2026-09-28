# AGENTS.md

Guidance for coding agents working in this repository.

## What this is

`premake-msvc6` — a standalone Premake5 module adding a `premake5 vs6`
action that generates Visual C++ 6.0 `.dsw`/`.dsp` files. The module
follows premake5-native conventions (baked targets, premake5 defaults,
msc toolset mappings). It began as a byte-exact port of premake 3.7's
vs6 exporter (preserved at tag `v1.0-3x-parity`; migration spec in
`docs/3x-to-native.md`). GPLv2, since it's derived from premake 3.x
code. Status and the prioritized roadmap live in `PLAN.md`; user-facing
docs in `README.md`. Read `PLAN.md` first when picking up work.

## Layout

```
_preload.lua    action registration (also re-applies p.action.set — see below)
_manifest.lua   file manifest
vs6.lua         module entry: p.modules.vs6, shared helpers
vs6_dsw.lua     workspace (.dsw) writer
vs6_dsp.lua     project (.dsp) writer
samples/        E2E sample (premake5.lua = module input)
tests/          unit test suites (_tests.lua), e2e.py, golden/ fixtures,
                acceptance/ (Windows VC6 harness + RESULTS.md)
docs/           design notes, 3x-to-native migration spec, coverage matrix
experiments/    real-world reproduction scripts (peter, zlib, libpng,
                quake2), each with run.py + NOTES.md
tools/          dspdiff.py (structural .dsp differ for the experiments),
                premake5.py (pinned binary setup + tests), test.py,
                premake5lib.py (shared helpers), run-vs6-tests.lua,
                find_premake5.py
real-world-test-cases/  310 .dsw/.dsp from public projects + SOURCE.md provenance
```

## Environment

- Test environment: run `uv run tools/premake5.py` once. It uses an
  installed premake5 if its version matches the pinned tag, otherwise
  downloads the pinned release binary (beta8) into `.deps/premake5/`,
  then runs the vs6 unit tests. No premake-core checkout, compiler, or
  Bootstrap is needed: release binaries ship the Lua core and the
  self-test harness, which `tools/run-vs6-tests.lua` wires to
  `tests/_tests.lua`. `uv run tools/premake5.py --clean` removes
  `.deps/`; `uv run tools/test.py [pattern]` reruns the suites.
- All tooling is uv-based Python (PEP 723 inline metadata; uv 0.12+):
  run it as `uv run <script>.py` on any host. `--scripts=<repo>` module
  loading requires premake5 beta8 or newer (used by e2e.py and the
  experiments); beta7 cannot load the module that way, and its API set
  is too old for the unit tests.
- A premake 3.7 oracle checkout used to live at `../premake-sources/`;
  it has been deleted. Its output fixtures live at tag `v1.0-3x-parity`.
- A loose VC6 tree exists on the Windows machine at
  `C:\MSVC6`
  (`Common\MSDev98\Bin\MSDEV.EXE` + `VC98\Bin\VCVARS32.BAT`; environment
  must come from VCVARS32) — used for the IDE/acceptance runs.

## Common commands

```sh
# one-time setup + vs6 unit tests (downloads into .deps/ as needed):
uv run tools/premake5.py
# vs6 unit tests (rerun; optional --test-only pattern):
uv run tools/test.py
uv run tools/test.py 'vs6_links*'
# E2E vs the golden baseline (from this repo):
uv run tests/e2e.py
# generate the sample manually:
cd samples && <premake5> --scripts=.. --file=premake5.lua vs6
```

## Conventions

- **Code style:** tabs for indentation; premake5 module idioms
  (`local p = premake`, doc-comment blocks). Every module file carries
  the GPL-2.0 header. Output uses `p.out`/`p.outln` with literal text
  only — never `p.esc`/`p.indent` (indent is pinned to "").
- **Output format:** always CRLF + backslash separators, every host.
- **Tests:** premake5's self-test harness; suites named `vs6_*`
  (`--test-only=vs6*`); `test.capture` compares exact text, so expected
  strings contain backslashes and trailing blank lines matter (see
  existing suites for the trailing-blank-line pattern). Any commit that
  changes observable output must update/add tests in the same commit.
- **Commits:** milestone-sized, imperative messages, tests included.
  Do NOT push unless explicitly asked.

## Frozen / hands-off

- `tests/golden/` is the module's own output for the sample — a
  regression baseline. Regenerate it only deliberately (from module
  output) and review the diff as part of the change. The premake 3.7
  oracle fixtures that used to live there are at tag `v1.0-3x-parity`.
- `real-world-test-cases/` files are vendored references under their
  own licenses — don't edit them; add provenance in SOURCE.md when
  adding new ones.
- The `p.action.set` re-apply in `_preload.lua`, the extra trailing
  blank line at the end of each writer, and the baked-target lookups in
  `vs6.lua` are all deliberate. PLAN.md's "Implementation notes"
  explains each — read before touching the writers.
