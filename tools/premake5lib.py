"""Shared helpers for the repository's uv-run Python tooling.

Locates or downloads the pinned premake5 release binary (release
binaries ship the Lua core and the self-test harness, so no premake-core
checkout is needed), runs the vs6 action, the unit suites, and
tools/dspdiff.py.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional, Sequence, Tuple

REPO = Path(__file__).resolve().parent.parent
DEPS = REPO / ".deps"
BINDIR = DEPS / "premake5"
DEFAULT_TAG = "v5.0.0-beta8"
RELEASE_URL = (
    "https://github.com/premake/premake-core/releases/download/{tag}/{asset}"
)
TEST_RUNNER = REPO / "tools" / "run-vs6-tests.lua"
DSPDIFF = REPO / "tools" / "dspdiff.py"


def tag_version(tag: str) -> str:
    """The version string (no leading "v") for a release tag."""
    return tag[1:] if tag.startswith("v") else tag


def exe_name() -> str:
    """The binary name on this host."""
    return "premake5.exe" if os.name == "nt" else "premake5"


def host_asset(tag: str) -> Tuple[str, str]:
    """The release asset name and binary name for this host."""
    version = tag_version(tag)
    if os.name == "nt":
        return f"premake-{version}-windows.zip", "premake5.exe"
    if sys.platform == "darwin":
        return f"premake-{version}-macosx.tar.gz", "premake5"
    return f"premake-{version}-linux.tar.gz", "premake5"


def version_of(binary: Path) -> Optional[str]:
    """The version reported by a premake5 binary, or None."""
    try:
        proc = subprocess.run(
            [str(binary), "--version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except OSError:
        return None
    if proc.returncode != 0:
        return None
    match = re.search(r"Generator\)\s*(\S+)", proc.stdout)
    return match.group(1) if match else None


def downloaded_binary() -> Path:
    """Where tools/premake5.py keeps the pinned download."""
    return BINDIR / exe_name()


def find_premake5(explicit: Optional[str] = None) -> Optional[Path]:
    """Resolve the premake5 binary: explicit, $PREMAKE5, .deps, PATH."""
    if explicit:
        return Path(explicit)
    env = os.environ.get("PREMAKE5")
    if env:
        return Path(env)
    for name in (exe_name(), "premake5", "premake5.exe"):
        candidate = BINDIR / name
        if candidate.is_file():
            return candidate
    which = shutil.which("premake5")
    return Path(which) if which else None


def require_premake5(explicit: Optional[str] = None) -> Path:
    """Like find_premake5, but exits with a hint when nothing is found."""
    binary = find_premake5(explicit)
    if binary is None:
        sys.exit("premake5 not found; run 'uv run tools/premake5.py' first")
    return binary


def ensure_binary(tag: str = DEFAULT_TAG) -> Path:
    """Return a premake5 binary matching tag, downloading if needed."""
    wanted = tag_version(tag)
    downloaded = downloaded_binary()
    if downloaded.is_file() and version_of(downloaded) == wanted:
        print(f"premake5: using downloaded premake5 {wanted} ({downloaded})")
        return downloaded
    if downloaded.is_file():
        # Drop a download from a previous --tag so tools/test.py cannot
        # resolve to the stale binary.
        downloaded.unlink()
    for candidate in (os.environ.get("PREMAKE5"), shutil.which("premake5")):
        if candidate and version_of(Path(candidate)) == wanted:
            print(f"premake5: using installed premake5 {wanted} ({candidate})")
            return Path(candidate)
    return download_binary(tag)


def download_binary(tag: str = DEFAULT_TAG) -> Path:
    """Download and unpack the official release archive into .deps/."""
    import urllib.request

    wanted = tag_version(tag)
    asset, exe = host_asset(tag)
    url = RELEASE_URL.format(tag=tag, asset=asset)
    BINDIR.mkdir(parents=True, exist_ok=True)
    archive = BINDIR / asset
    print(f"premake5: downloading {url}")
    request = urllib.request.Request(url, headers={"User-Agent": "premake-msvc6"})
    with urllib.request.urlopen(request) as response, open(archive, "wb") as handle:
        shutil.copyfileobj(response, handle)
    try:
        _extract_binary(archive, exe)
    finally:
        archive.unlink(missing_ok=True)
    binary = BINDIR / exe
    if os.name != "nt":
        binary.chmod(0o755)
    got = version_of(binary)
    if got != wanted:
        sys.exit(f"premake5: unexpected binary version {got!r} (want {wanted!r})")
    print(f"premake5: using downloaded premake5 {wanted} ({binary})")
    return binary


def _extract_binary(archive: Path, exe: str) -> None:
    import tarfile
    import zipfile

    target = BINDIR / exe
    if zipfile.is_zipfile(archive):
        with zipfile.ZipFile(archive) as zf:
            name = next(n for n in zf.namelist() if Path(n).name == exe)
            with zf.open(name) as src, open(target, "wb") as dst:
                shutil.copyfileobj(src, dst)
    else:
        with tarfile.open(archive, "r:gz") as tf:
            member = next(m for m in tf.getmembers() if Path(m.name).name == exe)
            src = tf.extractfile(member)
            if src is None:
                sys.exit(f"premake5: {member.name} is not a regular file")
            with src, open(target, "wb") as dst:
                shutil.copyfileobj(src, dst)


def run_premake(binary: Path, cwd: Path, args: Sequence[str]) -> None:
    """Run premake5 with args in cwd; raises CalledProcessError on failure."""
    subprocess.run([str(binary), *args], cwd=str(cwd), check=True)


def generate(binary: Path, cwd: Path, script: str = "premake5.lua") -> None:
    """Run the vs6 action on script in cwd with this repo on the module path."""
    run_premake(binary, cwd, [f"--scripts={REPO}", f"--file={script}", "vs6"])


def run_suites(binary: Path, pattern: str = "vs6*") -> int:
    """Run premake5's self-test harness for the given --test-only pattern."""
    proc = subprocess.run(
        [
            str(binary),
            f"--scripts={REPO}",
            f"--file={TEST_RUNNER}",
            "test",
            f"--test-only={pattern}",
        ],
        cwd=str(REPO),
    )
    return proc.returncode


def run_dspdiff(pairs: Sequence[Tuple[Path, Path]]) -> int:
    """Structurally diff real/generated .dsp pairs; returns the exit status."""
    args = [sys.executable, str(DSPDIFF)]
    for real, generated in pairs:
        args.extend([str(real), str(generated)])
    return subprocess.run(args).returncode
