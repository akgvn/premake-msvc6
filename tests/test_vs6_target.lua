--
-- test_vs6_target.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Target.cs
--
-- vs6.target()/vs6.outdir()/vs6.implib() return pre-translation paths
-- (forward slashes); path translation to backslashes happens at emission.
--

	local p = premake
	local suite = test.declare("vs6_target")
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


--
-- Default target tests
--

	function suite.defaultTarget()
		test.isequal("MyPackage.exe", vs6.target(getcfg("Debug")))
		test.isequal("MyPackage.exe", vs6.target(getcfg("Release")))
	end


	function suite.setOnPackage()
		targetname "MyApp"
		test.isequal("MyApp.exe", vs6.target(getcfg("Debug")))
		test.isequal("MyApp.exe", vs6.target(getcfg("Release")))
	end


	function suite.setOnPackageConfig()
		filter "configurations:Debug"
		targetname "MyPackage-d"
		test.isequal("MyPackage-d.exe", vs6.target(getcfg("Debug")))
		test.isequal("MyPackage.exe", vs6.target(getcfg("Release")))
	end


	function suite.targetIncludesPath()
		targetname "MyApp/MyPackage"
		test.isequal("./MyApp", vs6.outdir(getcfg("Debug")))
		test.isequal("./MyApp/MyPackage.exe", vs6.target(getcfg("Debug")))
		test.isequal("./MyApp", vs6.outdir(getcfg("Release")))
		test.isequal("./MyApp/MyPackage.exe", vs6.target(getcfg("Release")))
	end


	function suite.targetAppliedToImportLib()
		kind "SharedLib"
		targetdir "bin"
		implibdir "lib"
		targetname "MyApp/MyPackage"
		test.isequal("bin/MyApp", vs6.outdir(getcfg("Debug")))
		test.isequal("lib/MyApp/MyPackage.lib", vs6.implib(getcfg("Debug")))
		test.isequal("bin/MyApp/MyPackage.dll", vs6.target(getcfg("Debug")))
		test.isequal("bin/MyApp", vs6.outdir(getcfg("Release")))
		test.isequal("lib/MyApp/MyPackage.lib", vs6.implib(getcfg("Release")))
		test.isequal("bin/MyApp/MyPackage.dll", vs6.target(getcfg("Release")))
	end


	function suite.targetAppliedToStaticLib()
		kind "StaticLib"
		targetname "MyLib"
		test.isequal("MyLib.lib", vs6.target(getcfg("Debug")))
		test.isequal("MyLib.lib", vs6.target(getcfg("Release")))
	end


--
-- Custom target tests
--

	function suite.customTarget()
		targetextension ".zmf"
		test.isequal("MyPackage.zmf", vs6.target(getcfg("Debug")))
		test.isequal("MyPackage.zmf", vs6.target(getcfg("Release")))
	end


	function suite.customTargetSetOnConfig()
		filter "configurations:Debug"
		targetextension ".zmf"
		test.isequal("MyPackage.zmf", vs6.target(getcfg("Debug")))
		test.isequal("MyPackage.exe", vs6.target(getcfg("Release")))
	end
