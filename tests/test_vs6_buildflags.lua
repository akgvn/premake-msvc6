--
-- test_vs6_buildflags.lua
-- Compiler/linker flag behavior per configuration.
-- (Ported from premake 3.x Tests/Vs6/Cpp/Test_BuildFlags.cs; expectations
-- follow premake5-native semantics — see docs/3x-to-native.md.)
--

	local p = premake
	local suite = test.declare("vs6_buildflags")
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

	local function getcfg(cfgname)
		return test.getconfig(test.getproject(wks, 1), cfgname)
	end

	local function cppflags(cfgname)
		return dsp.cppFlags(getcfg(cfgname))
	end

	local function linkflags(cfgname)
		return dsp.linkFlags(getcfg(cfgname))
	end


--
-- Flag set at project level applies to all configurations.
--

	function suite.setFlagOnPackage()
		rtti "Off"
		test.isequal(" /MD /W3 /GX /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GX /YX /FD /c", cppflags("Release"))
	end


--
-- Flag set on a single configuration applies only to that configuration.
--

	function suite.setFlagOnConfig()
		filter "configurations:Debug"
		rtti "Off"
		test.isequal(" /MD /W3 /GX /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /YX /FD /c", cppflags("Release"))
	end


--
-- warnings "Extra"
--

	function suite.extraWarnings()
		warnings "Extra"
		test.isequal(" /MD /W4 /GR /GX /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W4 /GR /GX /YX /FD /c", cppflags("Release"))
	end


--
-- fatalwarnings { "All" }
--

	function suite.fatalWarnings()
		fatalwarnings { "All" }
		test.isequal(" /MD /W3 /WX /GR /GX /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /WX /GR /GX /YX /FD /c", cppflags("Release"))
	end


--
-- exceptionhandling "Off"
--

	function suite.noExceptions()
		exceptionhandling "Off"
		test.isequal(" /MD /W3 /GR /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /YX /FD /c", cppflags("Release"))
	end


--
-- omitframepointer "On"
--

	function suite.noFramePointer()
		omitframepointer "On"
		test.isequal(" /MD /W3 /GR /GX /Oy /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /Oy /YX /FD /c", cppflags("Release"))
	end


--
-- useimportlib "Off" (dll only): PROP Ignore_Export_Lib and no /implib:.
-- Uses a full block capture to pin the PROP.
--

	function suite.noImportLib()
		kind "SharedLib"
		useimportlib "Off"

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
# PROP Ignore_Export_Lib 1
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /dll /machine:I386 /out:"bin\Release\MyPackage.dll" /libpath:"bin\Release"
# ADD LINK32 /nologo /dll /machine:I386 /out:"bin\Release\MyPackage.dll" /libpath:"bin\Release"

		]]
	end


--
-- entrypoint "": no /entry: (same as the default).
--

	function suite.noMain()
		entrypoint ""
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\"", linkflags("Release"))
	end


--
-- rtti "Off"
--

	function suite.noRtti()
		rtti "Off"
		test.isequal(" /MD /W3 /GX /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GX /YX /FD /c", cppflags("Release"))
	end


--
-- symbols "Off": no debug info (also the premake5 default).
--

	function suite.noSymbols()
		symbols "Off"
		test.isequal(" /MD /W3 /GR /GX /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /YX /FD /c", cppflags("Release"))
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\"", linkflags("Release"))
		test.isequal(" /l 0x409 /d \"NDEBUG\"", dsp.rscFlags(getcfg("Debug")))
		test.isequal(" /l 0x409 /d \"NDEBUG\"", dsp.rscFlags(getcfg("Release")))
	end


--
-- optimize "On" (msc: /Ot)
--

	function suite.optimize()
		optimize "On"
		test.isequal(" /MD /W3 /GR /GX /Ot /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /Ot /YX /FD /c", cppflags("Release"))
	end


--
-- optimize "Size"
--

	function suite.optimizeSize()
		optimize "Size"
		test.isequal(" /MD /W3 /GR /GX /O1 /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /O1 /YX /FD /c", cppflags("Release"))
	end


--
-- optimize "Speed"
--

	function suite.optimizeSpeed()
		optimize "Speed"
		test.isequal(" /MD /W3 /GR /GX /O2 /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /O2 /YX /FD /c", cppflags("Release"))
	end


--
-- staticruntime "On"
--

	function suite.staticRuntime()
		staticruntime "On"
		test.isequal(" /MT /W3 /GR /GX /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MT /W3 /GR /GX /YX /FD /c", cppflags("Release"))
	end
