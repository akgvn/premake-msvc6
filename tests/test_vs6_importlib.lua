--
-- test_vs6_importlib.lua
-- Import library path behavior; expectations follow premake5-native
-- semantics (docs/3x-to-native.md): linktarget drives /implib:, and
-- useimportlib "Off" suppresses it entirely.
--

	local p = premake
	local suite = test.declare("vs6_importlib")
	local vs6 = p.modules.vs6


--
-- Setup: a shared library with bin/lib output dirs.
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
		test.isnil(vs6.implib(getcfg("Debug")))
		test.isnil(vs6.implib(getcfg("Release")))
	end
