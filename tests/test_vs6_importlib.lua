--
-- test_vs6_importlib.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_ImportLib.cs
--

	local p = premake
	local suite = test.declare("vs6_importlib")
	local vs6 = p.modules.vs6


--
-- Setup: mirrors the 3.x test (dll, project bindir/libdir set). The 3.x
-- libdir maps to premake5's implibdir for DLL import libraries (OQ-14).
--

	local wks, prj

	function suite.setup()
		p.action.set("vs6")
		wks = workspace("MyProject")
		configurations { "Debug", "Release" }
		targetdir "bin"
		implibdir "lib"
		prj = project("MyPackage")
		language "C++"
		kind "SharedLib"
		files { "somefile.txt" }
	end

	local function getcfg(cfgname)
		return test.getconfig(test.getproject(wks, 1), cfgname)
	end


	function suite.withImportLib()
		test.isequal("lib/MyPackage.lib", vs6.implib(getcfg("Debug")))
		test.isequal("lib/MyPackage.lib", vs6.implib(getcfg("Release")))
	end


	function suite.noImportLib()
		useimportlib "Off"
		test.isequal("obj/Debug/MyPackage.lib", vs6.implib(getcfg("Debug")))
		test.isequal("obj/Release/MyPackage.lib", vs6.implib(getcfg("Release")))
	end
