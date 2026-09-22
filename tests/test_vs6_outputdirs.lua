--
-- test_vs6_outputdirs.lua
-- Output/intermediate directory behavior; expectations follow
-- premake5-native semantics (docs/3x-to-native.md): baked buildtarget
-- directories (bin/<cfg> default), baked objdir (explicit value as-is).
-- vs6.outdir()/vs6.objdir() return pre-translation paths (forward slashes).
--

	local p = premake
	local suite = test.declare("vs6_outputdirs")
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

	local function linkflags(cfgname)
		return dsp.linkFlags(getcfg(cfgname))
	end


--
-- BinDir tests (targetdir)
--

	function suite.binDirDefault()
		test.isequal("bin/Debug", vs6.outdir(getcfg("Debug")))
		test.isequal("bin/Release", vs6.outdir(getcfg("Release")))
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
-- LibDir tests (the trailing /libpath: follows the target's directory;
-- a StaticLib's Output_Dir likewise)
--

	function suite.libDirDefault()
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\"", linkflags("Release"))
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
-- ObjDir tests (baked objdir; premake5 appends the configuration name
-- when configs would collide, and honors the "!" prefix to opt out)
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
