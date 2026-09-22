--
-- test_vs6_packages.lua
-- Port of premake 3.x Tests/Vs6/Test_Packages.cs; expectations follow
-- premake5-native semantics (docs/3x-to-native.md).
--

	local p = premake
	local suite = test.declare("vs6_packages")
	local vs6 = p.modules.vs6


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


--
-- The package name is used throughout the generated files; check the
-- workspace file.
--

	function suite.packageName()
		vs6.generateWorkspace(test.getWorkspace(wks))
		test.capture [[
Microsoft Developer Studio Workspace File, Format Version 6.00
# WARNING: DO NOT EDIT OR DELETE THIS WORKSPACE FILE!

###############################################################################

Project: "MyPackage"=.\MyPackage.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

###############################################################################

Global:

Package=<5>
{{{
}}}

Package=<3>
{{{
}}}

###############################################################################


]]
	end


--
-- The .dsp file name follows the premake5 filename API when it differs
-- from the project name (e.g. Peter's Loader -> Loader\Peter.dsp); the
-- project name inside the files stays the project name.
--

	function suite.customFileName()
		filename "Peter"
		vs6.generateWorkspace(test.getWorkspace(wks))
		test.capture [[
Microsoft Developer Studio Workspace File, Format Version 6.00
# WARNING: DO NOT EDIT OR DELETE THIS WORKSPACE FILE!

###############################################################################

Project: "MyPackage"=.\Peter.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

###############################################################################

Global:

Package=<5>
{{{
}}}

Package=<3>
{{{
}}}

###############################################################################


]]
	end


--
-- C projects generate the same file structure as C++ projects.
--

	function suite.cLanguage()
		language "C"
		vs6.generateProject(test.getproject(wks, 1))
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
# ADD BASE CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Release\MyPackage.exe" /libpath:"bin\Release"
# ADD LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Release\MyPackage.exe" /libpath:"bin\Release"

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
# ADD BASE CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Debug\MyPackage.exe" /libpath:"bin\Debug"
# ADD LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Debug\MyPackage.exe" /libpath:"bin\Debug"

!ENDIF

# Begin Target

# Name "MyPackage - Win32 Release"
# Name "MyPackage - Win32 Debug"
# Begin Source File

SOURCE=somefile.txt
# End Source File
# End Target
# End Project

]]
	end


--
-- The default C++ project file, in full.
--

	function suite.cppLanguage()
		vs6.generateProject(test.getproject(wks, 1))
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
# ADD BASE CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Release\MyPackage.exe" /libpath:"bin\Release"
# ADD LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Release\MyPackage.exe" /libpath:"bin\Release"

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
# ADD BASE CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Debug\MyPackage.exe" /libpath:"bin\Debug"
# ADD LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Debug\MyPackage.exe" /libpath:"bin\Debug"

!ENDIF

# Begin Target

# Name "MyPackage - Win32 Release"
# Name "MyPackage - Win32 Debug"
# Begin Source File

SOURCE=somefile.txt
# End Source File
# End Target
# End Project

]]
	end
