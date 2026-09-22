--
-- test_vs6_buildflags.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_BuildFlags.cs
--
-- The 3.x tests gave the Release configuration implicit optimize+no-symbols
-- flags; premake5 has no such defaults, so the ported expectations apply
-- the ported flag to unmodified Debug/Release baselines.
--

	local p = premake
	local suite = test.declare("vs6_buildflags")
	local vs6 = p.modules.vs6
	local dsp = vs6.dsp


--
-- Setup: mirrors Script.MakeBasic("exe", "c++") from the 3.x framework.
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
		test.isequal(" /MDd /W3 /Gm /GX /ZI /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GX /ZI /Od /YX /FD /GZ /c", cppflags("Release"))
	end


--
-- Flag set on a single configuration applies only to that configuration.
--

	function suite.setFlagOnConfig()
		filter "configurations:Debug"
		rtti "Off"
		test.isequal(" /MDd /W3 /Gm /GX /ZI /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Release"))
	end


--
-- extra-warnings
--

	function suite.extraWarnings()
		warnings "Extra"
		test.isequal(" /MDd /W4 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W4 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Release"))
	end


--
-- fatal-warnings
--

	function suite.fatalWarnings()
		fatalwarnings { "All" }
		test.isequal(" /MDd /W3 /WX /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /WX /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Release"))
	end


--
-- no-exceptions
--

	function suite.noExceptions()
		exceptionhandling "Off"
		test.isequal(" /MDd /W3 /Gm /GR /ZI /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /ZI /Od /YX /FD /GZ /c", cppflags("Release"))
	end


--
-- no-frame-pointer
--

	function suite.noFramePointer()
		omitframepointer "On"
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /Oy /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /Oy /YX /FD /GZ /c", cppflags("Release"))
	end


--
-- no-import-lib (dll only): PROP Ignore_Export_Lib and /implib: redirected
-- into the objects directory. Uses a full block capture to pin the PROP.
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
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "."
# PROP BASE Intermediate_Dir "obj\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "."
# PROP Intermediate_Dir "obj\Release"
# PROP Ignore_Export_Lib 1
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c
# ADD CPP /nologo /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /dll /incremental:yes /debug /machine:I386 /implib:"obj\Release\MyPackage.lib" /out:"MyPackage.dll" /pdbtype:sept /libpath:"."
# ADD LINK32 /nologo /dll /incremental:yes /debug /machine:I386 /implib:"obj\Release\MyPackage.lib" /out:"MyPackage.dll" /pdbtype:sept /libpath:"."

		]]
	end


--
-- no-main: suppress /entry:"mainCRTStartup"
--

	function suite.noMain()
		entrypoint ""
		test.isequal(" /nologo /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Debug"))
		test.isequal(" /nologo /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Release"))
	end


--
-- no-rtti
--

	function suite.noRtti()
		rtti "Off"
		test.isequal(" /MDd /W3 /Gm /GX /ZI /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GX /ZI /Od /YX /FD /GZ /c", cppflags("Release"))
	end


--
-- no-symbols: drops /ZI from the compiler, /incremental:yes /debug and
-- /pdbtype:sept from the linker, and switches _DEBUG to NDEBUG.
--

	function suite.noSymbols()
		symbols "Off"
		test.isequal(" /MDd /W3 /Gm /GR /GX /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /Od /YX /FD /GZ /c", cppflags("Release"))
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /machine:I386 /out:\"MyPackage.exe\" /libpath:\".\"", linkflags("Debug"))
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /machine:I386 /out:\"MyPackage.exe\" /libpath:\".\"", linkflags("Release"))
		test.isequal(" /l 0x409 /d \"NDEBUG\"", dsp.rscFlags(getcfg("Debug")))
		test.isequal(" /l 0x409 /d \"NDEBUG\"", dsp.rscFlags(getcfg("Release")))
	end


--
-- optimize
--

	function suite.optimize()
		optimize "On"
		test.isequal(" /MD /W3 /GR /GX /ZI /O2 /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /ZI /O2 /YX /FD /c", cppflags("Release"))
	end


--
-- optimize-size
--

	function suite.optimizeSize()
		optimize "Size"
		test.isequal(" /MD /W3 /GR /GX /ZI /O1 /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /ZI /O1 /YX /FD /c", cppflags("Release"))
	end


--
-- optimize-speed (VS6 only has two built-in optimization levels)
--

	function suite.optimizeSpeed()
		optimize "Speed"
		test.isequal(" /MD /W3 /GR /GX /ZI /O2 /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /ZI /O2 /YX /FD /c", cppflags("Release"))
	end


--
-- static-runtime
--

	function suite.staticRuntime()
		staticruntime "On"
		test.isequal(" /MTd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MTd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Release"))
	end
