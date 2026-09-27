@echo off
rem tests/acceptance/run.bat - build the generated acceptance projects
rem with the real VC6 toolchain and log accepted/rejected per combo.
rem
rem Run tests/acceptance/generate.sh first (Linux/WSL/Git Bash) and copy
rem the build\ directory next to this script, then run this on Windows.
rem
rem Usage: run.bat [VC6_ROOT]
rem VC6_ROOT defaults to the loose VC6 tree; it must contain
rem VC98\Bin\VCVARS32.BAT and Common\MSDev98\Bin\MSDEV.EXE.

setlocal enabledelayedexpansion
set "HERE=%~dp0"
set "VC6_ROOT=%~1"
if "%VC6_ROOT%"=="" set "VC6_ROOT=C:\MSVC6"

set "VCVARS=%VC6_ROOT%\VC98\Bin\VCVARS32.BAT"
set "MSDEV=%VC6_ROOT%\Common\MSDev98\Bin\MSDEV.EXE"

if not exist "%VCVARS%" (
	echo VC6 environment not found: "%VCVARS%"
	echo Pass the VC6 tree root as the first argument.
	exit /b 2
)
if not exist "%MSDEV%" (
	echo MSDEV.EXE not found: "%MSDEV%"
	exit /b 2
)

set "BUILD=%HERE%build"
set "DSW=%BUILD%\vc6_acceptance.dsw"
set "MANIFEST=%BUILD%\manifest.txt"
set "LOG=%HERE%acceptance.log"

if not exist "%DSW%" (
	echo Generated workspace not found: "%DSW%"
	echo Run tests/acceptance/generate.sh, then copy build\ here.
	exit /b 2
)
if not exist "%MANIFEST%" (
	echo Manifest not found: "%MANIFEST%"
	exit /b 2
)

call "%VCVARS%"

if exist "%LOG%" del "%LOG%"
echo VC6 acceptance run >> "%LOG%"
echo toolchain: %MSDEV% >> "%LOG%"
echo. >> "%LOG%"

set /a PASS=0
set /a FAIL=0

for /f "usebackq tokens=1,2,3 delims=|" %%A in ("%MANIFEST%") do (
	echo === %%A [%%B] === >> "%LOG%"
	"%MSDEV%" "%DSW%" /MAKE "%%A - Win32 %%B" /BUILD >> "%LOG%" 2>&1
	if errorlevel 1 (
		echo REJECTED %%A - Win32 %%B >> "%LOG%"
		set /a FAIL+=1
	) else if exist "%BUILD%\%%C" (
		echo ACCEPTED %%A - Win32 %%B >> "%LOG%"
		set /a PASS+=1
	) else (
		echo REJECTED %%A - Win32 %%B ^(no target %%C^) >> "%LOG%"
		set /a FAIL+=1
	)
)

echo. >> "%LOG%"
echo ACCEPTED=!PASS! REJECTED=!FAIL! >> "%LOG%"
echo.
echo VC6 acceptance: ACCEPTED=!PASS! REJECTED=!FAIL!
echo Full log: %LOG%
type "%LOG%"
exit /b !FAIL!
