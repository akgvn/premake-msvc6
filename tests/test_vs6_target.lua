--
-- test_vs6_target.lua
-- Target name/dir/extension behavior; expectations follow premake5-native
-- semantics (docs/3x-to-native.md). vs6.target()/vs6.outdir()/
-- vs6.implib() return pre-translation paths (forward slashes).
--

	local p = premake
	local suite = test.declare("vs6_target")
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


--
-- Default target tests
--

	function suite.defaultTarget()
		test.isequal("bin/Debug/MyPackage.exe", vs6.target(getcfg("Debug")))
		test.isequal("bin/Release/MyPackage.exe", vs6.target(getcfg("Release")))
	end


	function suite.setOnPackage()
		targetname "MyApp"
		test.isequal("bin/Debug/MyApp.exe", vs6.target(getcfg("Debug")))
		test.isequal("bin/Release/MyApp.exe", vs6.target(getcfg("Release")))
	end


	function suite.setOnPackageConfig()
		filter "configurations:Debug"
		targetname "MyPackage-d"
		test.isequal("bin/Debug/MyPackage-d.exe", vs6.target(getcfg("Debug")))
		test.isequal("bin/Release/MyPackage.exe", vs6.target(getcfg("Release")))
	end


--
-- A targetname containing a directory nests under the target directory
-- (premake5 buildtarget semantics).
--

	function suite.targetIncludesPath()
		targetname "MyApp/MyPackage"
		test.isequal("bin/Debug", vs6.outdir(getcfg("Debug")))
		test.isequal("bin/Debug/MyApp/MyPackage.exe", vs6.target(getcfg("Debug")))
		test.isequal("bin/Release", vs6.outdir(getcfg("Release")))
		test.isequal("bin/Release/MyApp/MyPackage.exe", vs6.target(getcfg("Release")))
	end


	function suite.targetAppliedToImportLib()
		kind "SharedLib"
		targetdir "bin"
		implibdir "lib"
		targetname "MyApp/MyPackage"
		test.isequal("bin", vs6.outdir(getcfg("Debug")))
		test.isequal("lib/MyApp/MyPackage.lib", vs6.implib(getcfg("Debug")))
		test.isequal("bin/MyApp/MyPackage.dll", vs6.target(getcfg("Debug")))
		test.isequal("bin", vs6.outdir(getcfg("Release")))
		test.isequal("lib/MyApp/MyPackage.lib", vs6.implib(getcfg("Release")))
		test.isequal("bin/MyApp/MyPackage.dll", vs6.target(getcfg("Release")))
	end


	function suite.targetAppliedToStaticLib()
		kind "StaticLib"
		targetname "MyLib"
		test.isequal("bin/Debug/MyLib.lib", vs6.target(getcfg("Debug")))
		test.isequal("bin/Release/MyLib.lib", vs6.target(getcfg("Release")))
	end


--
-- Custom target tests
--

	function suite.customTarget()
		targetextension ".zmf"
		test.isequal("bin/Debug/MyPackage.zmf", vs6.target(getcfg("Debug")))
		test.isequal("bin/Release/MyPackage.zmf", vs6.target(getcfg("Release")))
	end


	function suite.customTargetSetOnConfig()
		filter "configurations:Debug"
		targetextension ".zmf"
		test.isequal("bin/Debug/MyPackage.zmf", vs6.target(getcfg("Debug")))
		test.isequal("bin/Release/MyPackage.exe", vs6.target(getcfg("Release")))
	end
