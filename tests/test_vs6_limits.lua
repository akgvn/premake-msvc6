--
-- test_vs6_limits.lua
-- Module behaviors without 3.x-test counterparts: entrypoint, platform
-- validation, prebuildcommands folding, dependson blocks, and the
-- premake5-native optimize/warnings value mappings (docs/3x-to-native.md).
--

	local p = premake
	local suite = test.declare("vs6_limits")
	local vs6 = p.modules.vs6
	local dsp = vs6.dsp


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

	local function getcfg(cfgname)
		return test.getconfig(test.getproject(wks, 1), cfgname)
	end

	local function linkflags(cfgname)
		return dsp.linkFlags(getcfg(cfgname))
	end


--
-- entrypoint "X" emits /entry:"X" (the only case that emits /entry:).
--

	function suite.customEntrypoint()
		entrypoint "myMain"
		test.isequal(" /nologo /entry:\"myMain\" /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
	end


--
-- Platforms other than Win32/x86 are rejected; x86 is accepted.
--

	function suite.unsupportedPlatformErrors()
		platforms { "x64" }
		local bprj = test.getproject(wks, 1)
		local ok, err = pcall(vs6.generateProject, bprj)
		test.isfalse(ok)
		test.isnotnil(string.find(err, "not supported", 1, true))
	end

	function suite.x86PlatformAccepted()
		platforms { "x86" }
		local bprj = test.getproject(wks, 1)
		local ok, err = pcall(vs6.generateProject, bprj)
		test.istrue(ok)
	end


--
-- prebuildcommands are folded into PreLink_Cmds ahead of
-- prelinkcommands (VC6 has no pre-build step).
--

	function suite.prebuildcommandsFolded()
		prebuildcommands { "echo pre" }
		prelinkcommands { "echo link" }
		local bprj = test.getproject(wks, 1)
		local configs = vs6.configs(bprj)
		dsp.configBlock(bprj, configs, 2)
		test.capture [[
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
# Begin Special Build Tool
PreLink_Cmds=echo pre	echo link
# End Special Build Tool

		]]
	end


--
-- dependson emits a .dsw dependency block.
--

	function suite.dependsonBlock()
		dependson { "PackageB" }
		local prj2 = project("PackageB")
		language "C++"
		kind "StaticLib"
		files { "somefile.cpp" }
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
    Begin Project Dependency
    Project_Dep_Name PackageB
    End Project Dependency
}}}

###############################################################################

Project: "PackageB"=.\PackageB.dsp - Package Owner=<4>

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
-- premake5-native value mappings (msc.lua): optimize Off/Debug -> /Od,
-- Full -> /Ox; warnings Off -> /W0, High/Everything -> /W4.
--

	function suite.optimizeOffMapped()
		optimize "Off"
		test.isequal(" /MD /W3 /GR /GX /Od /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", dsp.cppFlags(getcfg("Debug")))
	end

	function suite.optimizeFullMapped()
		optimize "Full"
		test.isequal(" /MD /W3 /GR /GX /Ox /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", dsp.cppFlags(getcfg("Debug")))
	end

	function suite.warningsOffMapped()
		warnings "Off"
		test.isequal(" /MD /W0 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", dsp.cppFlags(getcfg("Debug")))
	end

	function suite.warningsHighMapped()
		warnings "High"
		test.isequal(" /MD /W4 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", dsp.cppFlags(getcfg("Debug")))
	end
