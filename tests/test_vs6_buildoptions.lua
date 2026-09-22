--
-- test_vs6_buildoptions.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_BuildOptions.cs
--

	local p = premake
	local suite = test.declare("vs6_buildoptions")
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

	local function cppflags(cfgname)
		return dsp.cppFlags(test.getconfig(test.getproject(wks, 1), cfgname))
	end


	function suite.setOptionsOnPackage()
		buildoptions { "pkgopt" }
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c pkgopt", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c pkgopt", cppflags("Release"))
	end


	function suite.setOptionsOnConfig()
		filter "configurations:Debug"
		buildoptions { "dbgopt" }
		filter "configurations:Release"
		buildoptions { "relopt" }
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c dbgopt", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c relopt", cppflags("Release"))
	end


	function suite.setOptionsOnPackageAndConfig()
		buildoptions { "pkgopt" }
		filter "configurations:Release"
		buildoptions { "relopt" }
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c pkgopt", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c pkgopt relopt", cppflags("Release"))
	end
