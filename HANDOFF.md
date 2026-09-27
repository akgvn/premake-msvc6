# HANDOFF — where we are and what's next

State as of 2026-09-27, commits f978105 plus the acceptance-harness
commit (all committed, nothing in flight). 233 vs6 tests green (111 of
them `vs6_coverage`); full premake-core suite (3136) green;
`tests/e2e.sh` green. Steps 1–3 of PLAN.md are DONE. Step 4 items 1–2
are DONE (coverage matrix + `vs6_coverage` suite); item 3's harness is
prepared and **only the Windows acceptance run remains** — it needs the
user's machine.

## Next: run the Step 4 Windows acceptance

`tests/acceptance/` holds the harness (see its README.md):

1. `tests/acceptance/generate.sh` (Linux) materializes `build/` with 49
   projects × Debug/Release + `manifest.txt`.
2. Copy `build/` to the Windows checkout and run
   `tests\acceptance\run.bat` (VC6 tree default
   `C:\MSVC6`); it loads VCVARS32, builds every
   manifest entry with `msdev /MAKE`, and logs ACCEPTED/REJECTED plus
   the raw build output to `acceptance.log`.
3. Fold the log back in: commit a redacted `acceptance-windows.log`, and
   fix or document every rejection (matrix legality table + notes).

## Step 4 deliverables (for reference)

1. `docs/coverage-matrix.md` — every emitted VC6 switch → premake5 API,
   with escape-hatch-only single-flag enums and the no-VC6-equivalent
   API list; legality rules table.
2. `tests/test_vs6_coverage.lua` — greedy pairwise walk of the reachable
   compiler/linker/resource option space (50/26/26 cases) with an
   independent expected-line oracle, plus explicit legality and escape
   hatch tests.
3. `tests/acceptance/` — generation script + Windows run harness.

## Working with the quota

Batch independent tool calls; avoid re-reading files already read;
trust prior findings (this file + PLAN.md + experiments/*/NOTES.md
carry them). Commit only when explicitly asked.
