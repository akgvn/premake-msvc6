# HANDOFF — where we are and what's next

State as of 2026-09-24, commit b3e7474 (all committed, nothing in
flight). 122 vs6 tests green; full premake-core suite (3025) green;
tests/e2e.sh green.

## Done since the last PLAN.md rewrite

- **Step 1 (divergence sweep):** one bug (`links "foo.lib"` →
  `foo.lib.lib`) + nine silently dropped premake5 APIs mapped
  (undefines, characterset, syslibdirs, ignoredefaultlibraries,
  externalincludedirs, includedirsafter, forceincludes, symbolspath,
  mapfile/mapfilepath, profile). `characterset "Default"` follows
  msc.lua → Unicode defines by default; legacy ANSI opt-out is
  `characterset "MBCS"` (documented in README + PLAN; the user was fine
  with me making this call unilaterally and logging it).
- **Step 2 (gap features):** `locale` → RSC `/l` LCID (no module option
  needed after all); quoted `SOURCE=` for paths with spaces; `vpaths`
  drive logical groups; `excludefrombuild` per-config blocks.
- **Step 3 (experiments so far):** `tools/dspdiff.py` (structural .dsp
  differ, see its header comment for the normalization list).
  `experiments/peter` (7/9 files structurally identical; residuals are
  the documented gaps: custom BSC32 output name, empty groups),
  `experiments/zlib` (100% structural match), `experiments/libpng`
  (matches except VB-config block position artifact, embedded-quote RSC
  define monsters, and the original's own hand drift). Module features
  added as a result: path-like links relativized, `MTL=` only for
  WindowedApp/SharedLib, RSC debug-marker dedupe, `LIB32=link.exe -lib`
  (was 3.7's `LINK32=link.exe -lib`; all 226 corpus occurrences use
  LIB32), per-file custom build rules (`buildcommands`/`buildoutputs`
  on files: filters → per-config `# Begin Custom Build` blocks),
  per-file CPP flags (`/D` `/U` `/I` + buildoptions; bare without !IF
  when uniform across all configs), PCH (`pchheader` → `/Yu`,
  `pchsource` file → bare per-file `/Yc`, `enablepch "Off"` → neither).

## In flight: experiments/quake2 (Step 3d, scale)

Surveyed, no script written yet. Findings to apply when writing it:

- 5 projects: `quake2` (WindowedApp), `game`/`ctf`/`ref_gl`/`ref_soft`
  (SharedLib, targetname gamex86 / ref_gl / ref_soft). 4 configs each;
  block order Release, Debug, Debug Alpha, Release Alpha → declare
  `{ "Release Alpha", "Debug Alpha", "Debug", "Release" }`.
- Per-project file lists (declaration order, project-relative) are
  extracted at `/tmp/opencode/q2-files.lua` — copy into the script.
  NOTE: /tmp/opencode may not survive; regenerate with the Python
  one-liner pattern used before (grep `^SOURCE=` per real .dsp,
  backslashes → slashes, strip leading `./`).
- Settings per project (from the raw .dsps):
  - all: `characterset "ASCII"`, `staticruntime "On"` (/MT(d)), `/GX`
    default on, `/G5` via buildoptions (except ctf), W4 release / W3
    debug, `optimize "Speed"`/`"Off"`, defines WIN32/_WINDOWS +
    NDEBUG/_DEBUG, `/ZI` debug (symbols On, no editandcontinue Off),
    `/Zd` release and `/FR` debug have no premake5 API → buildoptions
    (or accept as gap; quake2 Debug has NO /Gm, the DLLs do).
  - quake2: links winmm wsock32 kernel32 user32 gdi32; Debug adds
    mapfile "On", incrementallink "Off".
  - game: targetname "gamex86", targetdir "../release" / "../debug",
    linkoptions { '/base:"0x20000000"' }, minimalrebuild On in Debug,
    Debug define BUILDING_REF_GL (sic), links kernel32 user32 winmm.
  - ctf: targetname "gamex86", targetdir "release"/"debug", links
    kernel32 user32 winmm, minimalrebuild On in Debug.
  - ref_gl: links kernel32 user32 gdi32 winmm, minimalrebuild On Debug.
  - ref_soft: .asm files get custom build
    `ml /c /Cp /coff /Fo$(OUTDIR)\$(InputName).obj /Zm /Zi $(InputPath)`
    with buildoutputs `$(OUTDIR)\$(InputName).obj` in x86 configs,
    excludefrombuild in Alpha configs; Debug adds
    ignoredefaultlibraries { "libc" } + mapfile "On".
- **Known gap to document:** the Alpha configs use `/machine:ALPHA`;
  the module hardcodes `/machine:I386` and premake5 has no Alpha
  architecture value. linkoptions can't override (would duplicate).
  Write the Alpha configs as x86-flag copies and let the diff show the
  /machine mismatch.
- The custom-build command is identical in Release and Debug (both
  carry /Zi) — one form per x86 config.
- run.sh: copy experiments/zlib/run.sh pattern (explicit file lists →
  NO placeholder step needed; placeholders are only for glob-heavy
  scripts like peter). QUOTA LESSON: explicit file lists avoid the
  placeholder machinery entirely; if globs are ever used, placeholder
  paths must be joined onto the script's own directory (the real .dsp's
  depth), never naively — see commit b3e7474 for the escaped-stubs
  incident.

## Remaining after quake2

- FLTK is the other "scale" candidate in PLAN Step 3; optional if
  quake2 goes cleanly (it has no features the others don't).
- **Step 4 — VC6 build-option coverage** (the big one): coverage matrix
  + `vs6_coverage` combinatoric suite + Windows acceptance run. PLAN.md
  Step 4 has the flag inventory; add the newly reachable flags from
  this round (locale/RSC, per-file CPP, custom build, PCH /Yu//Yc,
  symbolspath /pdb:, mapfile /map, profile /profile, /nodefaultlib:,
  /FI, /U, characterset defines). PCH /Yu //Yc are now DONE (remove
  them from the "not implemented" example). Deferred single-flag enums
  to evaluate there: callingconvention /Gd.., structmemberalign /Zp,
  stringpooling /GF, intrinsics /Oi, functionlevellinking /Gy,
  unsignedchar /J, compileas /TC /TP, inlining /Ob, plus the
  no-VC6-equivalent list (cdialect/cppdialect /std, vectorextensions,
  floatingpoint, …). The Windows run uses the loose VC6 tree at
  C:\MSVC6 with VCVARS32.BAT.
- Keep PLAN.md Status/Steps current as each lands (Steps 1–2 marked
  done already; Step 3 needs the quake2 line appended when done).

## Working with the quota

Batch independent tool calls; avoid re-reading files already read;
trust prior findings (this file + PLAN.md + NOTES.md files carry them).
