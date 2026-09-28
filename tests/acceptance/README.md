# Windows VC6 acceptance run

Step 4.3 of `PLAN.md`: generate the reachable build-option combinations
as `.dsp` files and compile each one with the real Visual C++ 6.0
toolchain, recording accepted/rejected per combination.

This directory holds the harness and the recorded run. The run needs a
Windows machine with the loose VC6 tree (`VC98\Bin\VCVARS32.BAT` and
`Common\MSDev98\Bin\MSDEV.EXE`); generation runs anywhere uv does. It has been
executed once: **98/98 accepted, 0 rejected** — see
[`RESULTS.md`](RESULTS.md) and [`acceptance-windows.log`](acceptance-windows.log).

## Files

| File | Host | Purpose |
|---|---|---|
| `premake5.lua` | any | defines one project per acceptance profile; writes `manifest.txt` |
| `generate.py` | any (uv) | runs the module and materializes `build/` |
| `run.bat` | Windows | sources `VCVARS32.BAT`, builds every manifest entry with `msdev /MAKE`, writes `acceptance.log` |
| `sources/`, `include/` | any | trivial C sources and one `.rc` so cl/link/rc all run |

`build/` and `acceptance.log` are gitignored local artifacts.

## Procedure

1. **Generate** (any host with uv, from the repository):
   ```sh
   uv run tests/acceptance/generate.py
   ```
   This produces `tests/acceptance/build/` with `vc6_acceptance.dsw`,
   one `.dsp` per profile, the sources, and `manifest.txt`. Re-running
   is safe.

2. **Transfer**: copy `tests/acceptance/build/` to the Windows checkout
   (same relative location), e.g. `git pull` on Windows and re-run step 1
   there if premake5.exe is available, or copy the directory by hand.

3. **Run** (Windows `cmd`, from the repository root):
   ```bat
   tests\acceptance\run.bat
   ```
   Optional: pass the VC6 tree root as the first argument if it is not
   `C:\MSVC6`:
   ```bat
   tests\acceptance\run.bat D:\MSVC600
   ```
   The harness loads `VCVARS32.BAT`, builds each `name - Win32
   Debug|Release` with `msdev.exe /MAKE ... /BUILD`, checks the expected
   target exists, and appends `ACCEPTED`/`REJECTED` lines plus the full
   build output to `tests/acceptance/acceptance.log`. The exit code is
   the number of rejections.

## Coverage

49 projects × 2 configurations = 98 builds. Every switch the module
emits appears in at least one profile: runtime libraries (`/MD(d)`,
`/MT(d)`), warnings (`/W0`/`/W3`/`/W4`), `/WX`, `/Gm`, `/GR`/`/GX`
inclusion, symbols (`/ZI`/`/Zi`/`/Z7`, edit-and-continue, `debugformat
"c7"`), every `/O` level, `/Oy`, characterset defines, defines and
undefines, include paths, force-includes, the PCH pair (`/Yu` + `/Yc`),
the `buildoptions` escape hatch (the single-flag enums), all four kinds
(console, windowed, dll with/without import lib, static lib), linker
`/debug`, `/pdbtype:sept`, `/incremental`, `/entry`, `/map[:file]`,
`/profile`, `/libpath`, `links`, `/nodefaultlib`, `linkoptions`, and the
resource `/l`/`/d`/`resoptions` lines. `sources/app.rc` is included so
`rc.exe` runs for every project.

## Reporting the run

Attach `acceptance.log` to the Step 4 hand-off (or commit a redacted
`acceptance-windows.log`). Per `PLAN.md`, any `REJECTED` combination
must be either fixed in the module or documented with its reason; the
`docs/coverage-matrix.md` legality table and the appendices are the
place for the latter.

Known caveats to watch for in the log:

- `/profile` and some `/nodefaultlib` cases depend on the installed VC6
  service pack; a reject is a toolchain limitation, not a module bug.
- `msdev /BUILD` can in rare cases exit 0 despite a failed build; the
  target-existence check in `run.bat` guards against that.
