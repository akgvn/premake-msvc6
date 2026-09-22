# AGENTS.md

Guidance for coding agents working in this repository.

## What this is

`premake5-vs6` — a standalone Premake5 module adding a `premake5 vs6`
action that generates Visual C++ 6.0 `.dsw`/`.dsp` files. v1 is a
byte-exact port of premake 3.7's vs6 exporter (GPLv2, since it's derived
from premake 3.x code). Status and the prioritized roadmap live in
`PLAN.md`; user-facing docs in `README.md`. Read `PLAN.md` first when
picking up work.

## Layout

```
_preload.lua    action registration (also re-applies p.action.set — see below)
_manifest.lua   file manifest
vs6.lua         module entry: p.modules.vs6, shared helpers
vs6_dsw.lua     workspace (.dsw) writer
vs6_dsp.lua     project (.dsp) writer
samples/        E2E sample (premake.lua = 3.x syntax, premake5.lua = module input)
tests/          unit test suites (_tests.lua), e2e.sh, golden/ fixtures
real-world-test-cases/  310 .dsw/.dsp from public projects + SOURCE.md provenance
```

## Environment

- A premake-core checkout with a built binary is expected at
  `../premake-sources/premake-core` (`bin/release/premake5`), with this
  repo symlinked at `../premake-sources/premake-core/modules/vs6`
  (required for test discovery — `--scripts` alone does NOT work).
- A premake 3.7 checkout may exist at `../premake-sources/premake-3.x`
  (oracle; `bin/premake` is a Linux build, `bin/premake.exe` the Windows
  one). `../premake-sources/` is slated for deletion — don't rely on it
  in committed files.

## Common commands

```sh
# unit tests (from the premake-core checkout):
cd ../premake-sources/premake-core && bin/release/premake5 test --test-only=vs6*
# full premake-core suite (regression check):
bin/release/premake5 test
# E2E vs the golden 3.7 oracle fixtures (from this repo):
tests/e2e.sh
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

- `tests/golden/` is the frozen premake 3.7 oracle baseline — never
  regenerate or "fix" it without an explicit instruction (regeneration
  procedure is in PLAN.md §1d).
- `real-world-test-cases/` files are vendored references under their
  own licenses — don't edit them; add provenance in SOURCE.md when
  adding new ones.
- The `Use_Debug_Libraries` rotation, the raw-objdir re-fetch, the
  extra trailing blank line, and the `p.action.set` re-apply in
  `_preload.lua` are all deliberate. PLAN.md's "Implementation notes"
  explains each — read before touching the writers.
