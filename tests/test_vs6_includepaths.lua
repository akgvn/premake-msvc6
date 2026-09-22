--
-- test_vs6_includepaths.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_IncludePaths.cs
--
-- Note: the module emits Windows path separators (OQ-7), so the 3.x
-- "../src" expectations appear here as "..\src".
--

	local p = premake
	local suite = test.declare("vs6_includepaths")
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


	function suite.noIncludePaths()
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Release"))
	end


	function suite.pathsOnPackage()
		includedirs { "../src", "../include" }
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /I \"..\\src\" /I \"..\\include\" /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /I \"..\\src\" /I \"..\\include\" /YX /FD /GZ /c", cppflags("Release"))
	end


	function suite.pathsInPackageConfig()
		filter "configurations:Debug"
		includedirs { "../debug" }
		filter "configurations:Release"
		includedirs { "../release" }
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /I \"..\\debug\" /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /I \"..\\release\" /YX /FD /GZ /c", cppflags("Release"))
	end


	function suite.pathsOnPackageAndConfig()
		includedirs { "../package" }
		filter "configurations:Debug"
		includedirs { "../debug" }
		filter "configurations:Release"
		includedirs { "../release" }
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /I \"..\\package\" /I \"..\\debug\" /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /I \"..\\package\" /I \"..\\release\" /YX /FD /GZ /c", cppflags("Release"))
	end
