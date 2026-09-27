--
-- test_vs6_kinds.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Kinds.cs; expectations follow
-- premake5-native semantics (docs/3x-to-native.md).
--

	local p = premake
	local suite = test.declare("vs6_kinds")
	local vs6 = p.modules.vs6
	local dsp = vs6.dsp


--
-- Setup: one console application with Debug/Release configurations.
--

	local wks, prj

	function suite.setup()
		p.action.set("vs6")
		wks = workspace("MyProject")
		configurations { "Debug", "Release" }
		prj = project("MyPackage")
		language "C++"
		kind "ConsoleApp"
		files { "somefile.txt" }
	end

	-- captures the file header (through RSC=rc.exe) followed by the
	-- Release configuration block
	local function prepare()
		local bprj = test.getproject(wks, 1)
		local configs = vs6.configs(bprj)
		dsp.header(bprj, configs)
		dsp.configBlock(bprj, configs, 2)
	end


--
-- Console application
--

	function suite.kindIsExe()
		prepare()
		test.capture [[
# Microsoft Developer Studio Project File - Name="MyPackage" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=MyPackage - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak" CFG="MyPackage - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "MyPackage - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "MyPackage - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "MyPackage - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Release"
# PROP BASE Intermediate_Dir "obj\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Release"
# PROP Intermediate_Dir "obj\Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Release\MyPackage.exe" /libpath:"bin\Release"
# ADD LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Release\MyPackage.exe" /libpath:"bin\Release"

]]
	end


--
-- Windows application
--

	function suite.kindIsWinExe()
		kind "WindowedApp"
		prepare()
		test.capture [[
# Microsoft Developer Studio Project File - Name="MyPackage" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=MyPackage - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak" CFG="MyPackage - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "MyPackage - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "MyPackage - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "MyPackage - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Release"
# PROP BASE Intermediate_Dir "obj\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Release"
# PROP Intermediate_Dir "obj\Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:windows /machine:I386 /out:"bin\Release\MyPackage.exe" /libpath:"bin\Release"
# ADD LINK32 /nologo /subsystem:windows /machine:I386 /out:"bin\Release\MyPackage.exe" /libpath:"bin\Release"

]]
	end


--
-- Dynamic-link library
--

	function suite.kindIsDll()
		kind "SharedLib"
		prepare()
		test.capture [[
# Microsoft Developer Studio Project File - Name="MyPackage" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

CFG=MyPackage - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak" CFG="MyPackage - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "MyPackage - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "MyPackage - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "MyPackage - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Release"
# PROP BASE Intermediate_Dir "obj\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Release"
# PROP Intermediate_Dir "obj\Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /dll /machine:I386 /implib:"bin\Release\MyPackage.lib" /out:"bin\Release\MyPackage.dll" /libpath:"bin\Release"
# ADD LINK32 /nologo /dll /machine:I386 /implib:"bin\Release\MyPackage.lib" /out:"bin\Release\MyPackage.dll" /libpath:"bin\Release"

]]
	end


--
-- Static library: no MTL=midl.exe line, LIB32 instead of LINK32.
--

	function suite.kindIsLib()
		kind "StaticLib"
		prepare()
		test.capture [[
# Microsoft Developer Studio Project File - Name="MyPackage" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=MyPackage - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak" CFG="MyPackage - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "MyPackage - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "MyPackage - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "MyPackage - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Release"
# PROP BASE Intermediate_Dir "obj\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Release"
# PROP Intermediate_Dir "obj\Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"bin\Release\MyPackage.lib"

]]
	end


--
-- Kinds may differ per configuration; the TARGTYPE and the presence of
-- MTL=midl.exe follow the first configuration, while each configuration
-- block follows its own kind.
--

	function suite.mixedKinds()
		filter "configurations:Debug"
		kind "StaticLib"
		filter "configurations:Release"
		kind "SharedLib"

		local bprj = test.getproject(wks, 1)
		local configs = vs6.configs(bprj)
		dsp.header(bprj, configs)
		dsp.configBlock(bprj, configs, 2)
		dsp.configBlock(bprj, configs, 1)
		test.capture [[
# Microsoft Developer Studio Project File - Name="MyPackage" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=MyPackage - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "MyPackage.mak" CFG="MyPackage - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "MyPackage - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "MyPackage - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "MyPackage - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Release"
# PROP BASE Intermediate_Dir "obj\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Release"
# PROP Intermediate_Dir "obj\Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /dll /machine:I386 /implib:"bin\Release\MyPackage.lib" /out:"bin\Release\MyPackage.dll" /libpath:"bin\Release"
# ADD LINK32 /nologo /dll /machine:I386 /implib:"bin\Release\MyPackage.lib" /out:"bin\Release\MyPackage.dll" /libpath:"bin\Release"

!ELSEIF  "$(CFG)" == "MyPackage - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Debug"
# PROP BASE Intermediate_Dir "obj\Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Debug"
# PROP Intermediate_Dir "obj\Debug"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"bin\Debug\MyPackage.lib"

]]
	end
