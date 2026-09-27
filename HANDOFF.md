# HANDOFF — where we are and what's next

State as of 2026-09-27, commit 2167f78 (all committed, nothing in
flight). 122 vs6 tests green; full premake-core suite (3025) green;
tests/e2e.sh green. Steps 1–3 of PLAN.md are DONE: the module is
premake5-native, the four real-world experiments (peter, zlib, libpng,
quake2) reproduce their targets except each one's documented residuals
(experiments/*/NOTES.md), and Step 3's feature harvest (custom build
rules, per-file CPP flags, PCH, locale, vpaths, excludefrombuild,
quoted SOURCE=) is in.

## Next: Step 4 — VC6 build-option coverage

Everything else is done; this is the only remaining step in PLAN.md.
Its three deliverables, in order:

1. **Coverage matrix** (`docs/`): every VC6 flag the module can emit →
   the premake5 API that reaches it. The full starting inventory is in
   PLAN.md Step 4 item 1 (compiler/linker/RSC lists + the Steps 2–3
   additions). For flags with no dedicated mapping: say "escape hatch"
   (buildoptions/linkoptions/resoptions) or give a documented reason
   (no-VC6-equivalent list: `/std:*`, `/arch:*`, `/fp:*`, …; the
   unpinnable `/machine:ALPHA` from the quake2 experiment belongs here
   too).
2. **`vs6_coverage` suite** (tests/): pairwise (or documented
   structured subset) walk of the reachable option space asserting the
   exact CPP/RSC/LINK32/LIB32 lines per combination, incl. the legality
   rules (`/ZI`→`/Zi` under optimization, `/GZ` only with the debug
   runtime, `/implib` absent with `useimportlib "Off"`). Record which
   subset and why. Existing suites (test_vs6_buildflags.lua etc.) pin
   the individual mappings already — the coverage suite is about
   combinations.
3. **Windows acceptance run**: generate the same combinations as .dsp,
   compile a trivial source under each with the real VC6 toolchain
   (loose tree at C:\MSVC6, env via
   VC98\Bin\VCVARS32.BAT, `cl.exe`/`link.exe` directly or
   `msdev /MAKE`). Log accepted/rejected per combo; fix or document
   every rejection.

Single-flag enums to evaluate for dedicated mappings while doing item 1
(currently escape-hatch-only): callingconvention `/Gd..`, structmemberalign
`/Zp`, stringpooling `/GF`, intrinsics `/Oi`, functionlevellinking `/Gy`,
unsignedchar `/J`, compileas `/TC`/`/TP`, inlining `/Ob`.

## Working with the quota

Batch independent tool calls; avoid re-reading files already read;
trust prior findings (this file + PLAN.md + experiments/*/NOTES.md carry
them). Commit only when explicitly asked.
