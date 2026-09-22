# Quake (GPL source release)

- **Upstream:** `https://github.com/id-Software/Quake` @ `master`
- **Retrieved from:** `https://raw.githubusercontent.com/id-Software/Quake/master/`
- **License:** GPL-2.0
- **Files:** QW/qw.dsw, QW/client/qwcl.dsp+.dsw, QW/gas2masm/gas2masm.dsp, QW/qwfwd/qwfwd.dsp+.dsw, QW/server/qwsv.dsp+.dsw, WinQuake/WinQuake.dsp+.dsw, WinQuake/gas2masm/gas2masm.dsp+.dsw
- **Notes:** heavily hand-customized VC6: per-file custom build steps (gas2masm for .s assembly), per-file `# PROP Exclude_From_Build`, `# SUBTRACT` lines, `/G5 /ML` flags, four configurations. Exercises grammar corners our generator will never emit — parser/IDE-compat reference, not a parity target.
