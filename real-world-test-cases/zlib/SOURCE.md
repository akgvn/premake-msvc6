# zlib — projects/visualc6

- **Upstream:** zlib 1.2.3, `projects/visualc6/`
- **Retrieved from:** `http://svn.code.sf.net/p/pure-data/svn/vendor/zlib/current/projects/visualc6/` (Pure Data's vendored copy of the canonical zlib 1.2.3 sources; also mirrored at `https://oss.verimatrix.com/VCAS-3.4/zlib-1.2.3/projects/visualc6/`)
- **License:** zlib license (see README.txt / zlib.h)
- **Files:** zlib.dsw, zlib.dsp, example.dsp, minigzip.dsp, README.txt
- **Notes:** hand-maintained VC6 project. 3 projects (zlib DLL/LIB + 2 sample apps depending on it), 8 configurations (DLL/LIB × Release/Debug × ASM). Exercises LIB32 *and* LINK32 in one file, project dependencies, per-config defines. Contains VC-isms our generator does not emit (`# SUBTRACT CPP /YX /Yc /Yu`, system-lib lists, `# PROP Ignore_Export_Lib 0`).
