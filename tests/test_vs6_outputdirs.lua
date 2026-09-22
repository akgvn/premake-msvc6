--
-- test_vs6_outputdirs.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_OutputDirs.cs
--
-- 3.x has separate bindir/libdir project settings; premake5 has only
-- targetdir. Per OQ-14 the 3.x libdir maps to the target's own directory,
-- so the LibDir tests are ported using StaticLib projects (whose 3.x
-- Output_Dir comes from libdir) with targetdir in place of libdir.
--
-- vs6.outdir()/vs6.objdir() return pre-translation paths (forward slashes).
--

	local p = premake
	local suite = test.declare("vs6_outputdirs")
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

	local function linkflags(cfgname)
		return dsp.linkFlags(getcfg(cfgname))
	end


--
-- BinDir tests (3.x bindir -> premake5 targetdir)
--

	function suite.binDirDefault()
		test.isequal(".", vs6.outdir(getcfg("Debug")))
		test.isequal(".", vs6.outdir(getcfg("Release")))
	end


	function suite.binDirSetAtProject()
		targetdir "bin"
		test.isequal("bin", vs6.outdir(getcfg("Debug")))
		test.isequal("bin", vs6.outdir(getcfg("Release")))
	end


	function suite.binDirSetAtProjectConfig()
		filter "configurations:Debug"
		targetdir "bin/Debug"
		filter "configurations:Release"
		targetdir "bin/Release"
		test.isequal("bin/Debug", vs6.outdir(getcfg("Debug")))
		test.isequal("bin/Release", vs6.outdir(getcfg("Release")))
	end


--
-- LibDir tests (see header note for the 3.x -> premake5 mapping)
--

	function suite.libDirDefault()
		-- the trailing /libpath: of the linker line is the 3.x libdir
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Debug"))
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Release"))
	end


	function suite.libDirSetAtProject()
		kind "StaticLib"
		targetdir "lib"
		test.isequal("lib", vs6.outdir(getcfg("Debug")))
		test.isequal("lib", vs6.outdir(getcfg("Release")))
	end


	function suite.libDirSetAtProjectConfig()
		kind "StaticLib"
		filter "configurations:Debug"
		targetdir "lib/Debug"
		filter "configurations:Release"
		targetdir "lib/Release"
		test.isequal("lib/Debug", vs6.outdir(getcfg("Debug")))
		test.isequal("lib/Release", vs6.outdir(getcfg("Release")))
	end


--
-- ObjDir tests
--

	function suite.objDirDefault()
		test.isequal("obj/Debug", vs6.objdir(getcfg("Debug")))
		test.isequal("obj/Release", vs6.objdir(getcfg("Release")))
	end


	function suite.objDirSetAtPackage()
		objdir "temp"
		test.isequal("temp/Debug", vs6.objdir(getcfg("Debug")))
		test.isequal("temp/Release", vs6.objdir(getcfg("Release")))
	end
