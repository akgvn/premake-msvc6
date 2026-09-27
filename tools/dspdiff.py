#!/usr/bin/env python3
# tools/dspdiff.py - structural diff of Visual C++ 6.0 .dsp files.
#
# Compares only the premake-reachable parts of a .dsp, stripping VC-isms
# that generators never reproduce: system library lists, # SUBTRACT /
# # ADD BASE / # PROP BASE lines, DEP_CPP_/DEP_RSC_/NODEP_ dependency
# lines (assignment plus continuations), Ignore_Export_Lib 0, leading
# ".\\", MTL /o "NUL", the trailing /libpath duplicating a config's own
# Output_Dir, a Target_Dir of "." (the project directory), blank lines,
# and flag order (tokens within each # ADD line are sorted).
#
# Usage: dspdiff.py A.dsp B.dsp [A2.dsp B2.dsp ...]
# Exit status 0 when all pairs are structurally identical, 1 otherwise.

import re
import sys
import difflib

# the AppWizard default library list — premake5 never emits these and
# they carry no project intent (project-chosen libs stay visible)
SYSTEM_LIBS = {
    "kernel32.lib", "user32.lib", "gdi32.lib", "winspool.lib",
    "comdlg32.lib", "advapi32.lib", "shell32.lib", "ole32.lib",
    "oleaut32.lib", "uuid.lib", "odbc32.lib", "odbccp32.lib",
}

# runtime selection tokens: premake5 always selects a runtime, VC6-era
# files routinely use the compiler default (or /ML, which premake5
# cannot express) — compared via NOTES, not this diff
RUNTIME_TOKENS = {"/md", "/mdd", "/mt", "/mtd", "/ml", "/mld"}

# tokens the module emits by deliberate idiom where VC-authored files
# vary (per-project settings): /GZ for every debug-runtime config, /YX
# (automatic PCH) on every CPP line, /pdbtype:sept whenever symbols are
# on (spec E3)
IDIOM_TOKENS = {"/gz", "/yx", "/pdbtype:sept"}

DROP_LINE = re.compile(
    r"^(!MESSAGE|# SUBTRACT|# ADD BASE|# PROP BASE|DEP_CPP_|DEP_RSC_|"
    r"OutDir=|TargetName=|InputPath=|InputName=|IntDir=|PostBuild_Desc=|"
    r"\"\$\(OUTDIR\)|\"\$\(IntDir\)|SOURCE=\"\$\(InputPath\)\"|"
    r"CPP=cl\.exe|MTL=midl\.exe|RSC=rc\.exe|BSC32=bscmake\.exe|"
    r"# TARGTYPE|"
    r"# PROP Ignore_Export_Lib 0\s*$)")

FLAG_WITH_VALUE = {"/d", "/i", "/u", "/fi", "/fo"}


def tokenize(text):
    """Split a flag line into tokens, gluing /D "value" pairs together."""
    raw, cur, inq = [], "", False
    for ch in text:
        if ch == '"':
            inq = not inq
            cur += ch
        elif ch == " " and not inq:
            if cur:
                raw.append(cur)
                cur = ""
        else:
            cur += ch
    if cur:
        raw.append(cur)
    toks = []
    i = 0
    while i < len(raw):
        if raw[i].lower() in FLAG_WITH_VALUE and i + 1 < len(raw):
            toks.append((raw[i], raw[i + 1]))
            i += 2
        else:
            toks.append((raw[i], None))
            i += 1
    return toks


def norm_add_line(line, outdir, cpp_defines, cpp_includes):
    """Normalize one '# ADD <tool> ...' line: drop noise tokens, sort."""
    m = re.match(r"(# ADD (?:BASE )?(\w+))\s*(.*)", line)
    head, tool, rest = m.group(1), m.group(2), m.group(3)
    rest = rest.replace('/o "NUL"', " ")
    toks = []
    stripped_merged = set()
    for flag, value in tokenize(rest):
        joined = flag if value is None else flag + " " + value
        if value is None and flag.lower() in SYSTEM_LIBS:
            continue
        if value is None and flag.lower() in RUNTIME_TOKENS:
            continue
        if value is None and flag.lower() in IDIOM_TOKENS:
            continue
        if value is None and flag.lower().startswith("/out:"):
            continue
        if value is None and flag.lower().startswith("/implib:"):
            continue
        if tool == "RSC" and value is not None and flag.lower() in ("/d", "/i"):
            # vs2010-style merge: VC6 wizards kept RSC defines/includes
            # separate, so anything duplicating the config's CPP settings
            # is merge noise (the script's resdefines/resincludedirs are
            # visible when they don't duplicate the CPP line)
            v = value.strip('"')
            merged = cpp_defines if flag == "/d" else cpp_includes
            if v in merged:
                continue
        if value is None and flag.startswith(".\\"):
            flag = flag[2:]
            joined = flag
        if value is not None:
            v = value.strip('"')
            if v.startswith(".\\"):
                v = v[2:]
            if outdir and flag.lower() == "/libpath:" and v == outdir:
                continue
            joined = flag + ' "' + v + '"'
            if flag.lower() in ("/d", "/i"):
                joined = flag + " " + v  # quotes are cosmetic here
        elif flag.lower().startswith("/libpath:"):
            v = flag[len("/libpath:"):].strip('"')
            if outdir and v == outdir:
                continue
            if v.startswith(".\\"):
                v = v[2:]
            joined = '/libpath:"' + v + '"'
        toks.append(joined)
    toks.sort()
    return head + " " + " ".join(toks)


def normalize(path):
    with open(path, newline="") as f:
        text = f.read().replace("\r\n", "\n").replace("\r", "\n")
    out = []
    outdir = None
    cpp_defines = set()
    cpp_includes = set()
    in_dep = False
    for line in text.split("\n"):
        line = line.rstrip()
        if in_dep:
            # a dependency list is the DEP_CPP_/DEP_RSC_ assignment plus
            # its tab-indented quoted continuations (the last is a bare
            # tab); drop the whole run
            if line.startswith("\t"):
                continue
            in_dep = False
        line = re.sub(r" {2,}", " ", line)
        line = re.sub(r'# PROP Default_Filter "[^"]*"', '# PROP Default_Filter ""', line)
        line = line.replace("=.\\", "=")
        if line.startswith("Project:"):
            # VC6's .dsp path quoting and .\ prefix vary by author
            m2 = re.match(r'^(Project: "[^"]*")="?(?:\.\\)?(.*?)"?( - Package Owner=<4>)$', line)
            if m2:
                line = m2.group(1) + "=" + m2.group(2) + m2.group(3)
        # CFG= names the config that was active when the IDE last saved
        # the file — user state, not structure
        line = re.sub(r"^CFG=.*", "CFG=", line)
        line = re.sub(r"^# Begin Custom Build.*", "# Begin Custom Build", line)
        # Target_Dir "." is the project's own directory, the same place
        # the module's implicit "" points
        line = re.sub(r'^# PROP Target_Dir "\."\s*$', '# PROP Target_Dir ""', line)
        if line.startswith(("DEP_CPP_", "DEP_RSC_", "NODEP_")):
            # enter the dependency run; the continuations are skipped by
            # the in_dep guard above
            in_dep = True
            continue
        if not line or DROP_LINE.match(line):
            continue
        m = re.match(r'# PROP (?:BASE )?Output_Dir "([^"]*)"', line)
        if m and not line.startswith("# PROP BASE"):
            outdir = m.group(1)
            if outdir.startswith(".\\"):
                outdir = outdir[2:]
        if re.match(r"# ADD (?:BASE )?\w+ ", line):
            if re.match(r"# ADD CPP ", line):
                cpp_defines = set(
                    v.strip('"') for f, v in tokenize(line) if f == "/D" and v)
                cpp_includes = set(
                    v.strip('"') for f, v in tokenize(line) if f == "/I" and v)
            line = norm_add_line(line, outdir, cpp_defines, cpp_includes)
        elif line.startswith("SOURCE="):
            src = line[len("SOURCE="):]
            quoted = src.startswith('"')
            if quoted:
                src = src[1:-1]
            if src.startswith(".\\"):
                src = src[2:]
            line = "SOURCE=" + ('"' + src + '"' if quoted else src)
        elif line.startswith("# PROP") and ".\\" in line:
            line = line.replace('".\\', '"')
        elif line.startswith("\t") or line.startswith("ml ") or line.startswith("nmake "):
            line = line.replace(".\\", "")
        out.append(line)
    return sort_file_runs(drop_empty_branches(out))


def drop_empty_branches(lines):
    """Drop empty !IF/!ELSEIF branches (VC6 lists every config for a
    per-file block even when it carries no settings; the module mentions
    only the configs that differ). The first surviving branch keeps the
    !IF keyword."""
    out = []
    i = 0
    while i < len(lines):
        if not lines[i].startswith("!IF "):
            out.append(lines[i])
            i += 1
            continue
        # gather the whole !IF..!ENDIF chain
        chain = []
        while i < len(lines):
            chain.append(lines[i])
            done = lines[i].startswith("!ENDIF")
            i += 1
            if done:
                break
        # split into (header, body) branches; drop empty bodies
        kept = []
        k = 0
        while k < len(chain):
            l = chain[k]
            if l.startswith(("!IF ", "!ELSEIF ")):
                m = k + 1
                body = []
                while m < len(chain) and not chain[m].startswith(("!ELSEIF ", "!ENDIF")):
                    body.append(chain[m])
                    m += 1
                if body:
                    kept.append((l, body))
                k = m
            else:
                k += 1
        for n, (hdr, body) in enumerate(kept):
            if n == 0 and hdr.startswith("!ELSEIF "):
                hdr = "!IF " + hdr[len("!ELSEIF "):]
            out.append(hdr)
            out.extend(body)
        # a chain whose branches are all empty (e.g. VC6's per-file blocks
        # holding only dependency lists) disappears entirely
        if kept:
            out.append("!ENDIF")
    return out


def sort_file_runs(lines):
    """Sort each maximal run of consecutive source-file blocks by their
    SOURCE= line (declaration order is cosmetic; premake5 globbing and
    VC6's own ordering differ). Exclude_From_Build blocks travel with
    their file."""
    blocks = {}
    runs = []
    i = 0
    while i < len(lines):
        if lines[i] == "# Begin Source File":
            j = i
            while j < len(lines) and lines[j] != "# End Source File":
                j += 1
            block = lines[i:j + 1]
            src = next((l for l in block if l.startswith("SOURCE=")), "")
            runs.append((len(runs), i, j + 1, src, block))
            i = j + 1
        else:
            i += 1
    # identify runs of consecutive blocks (adjacent in the line list)
    result = list(lines)
    groups = []
    cur = []
    prev_end = None
    for _, start, end, src, block in runs:
        if prev_end is not None and start != prev_end:
            groups.append(cur)
            cur = []
        cur.append((start, end, src, block))
        prev_end = end
    if cur:
        groups.append(cur)
    for g in reversed(groups):
        sorted_blocks = sorted(g, key=lambda b: b[2])
        # hand-maintained files sometimes list the same file twice
        deduped = []
        for b in sorted_blocks:
            if not deduped or deduped[-1][2] != b[2]:
                deduped.append(b)
        span_start, span_end = g[0][0], g[-1][1]
        result[span_start:span_end] = [l for (_, _, _, block) in deduped for l in block]
    return result


def main(argv):
    if len(argv) < 2 or len(argv) % 2 != 0:
        sys.exit(__doc__)
    status = 0
    for i in range(0, len(argv), 2):
        a, b = argv[i], argv[i + 1]
        na, nb = normalize(a), normalize(b)
        if na != nb:
            status = 1
            print("### %s vs %s" % (a, b))
            for l in difflib.unified_diff(na, nb, a, b, lineterm="", n=2):
                print(l)
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
