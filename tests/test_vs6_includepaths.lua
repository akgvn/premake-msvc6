--
-- test_vs6_includepaths.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_IncludePaths.cs; expectations
-- follow premake5-native semantics (docs/3x-to-native.md). The module
-- emits Windows path separators.
--

	local p = premake
	local suite = test.declare("vs6_includepaths")
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

	local function cppflags(cfgname)
		return dsp.cppFlags(test.getconfig(test.getproject(wks, 1), cfgname))
	end


	function suite.noIncludePaths()
		test.isequal(" /MD /W3 /GR /GX /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /YX /FD /c", cppflags("Release"))
	end


	function suite.pathsOnPackage()
		includedirs { "../src", "../include" }
		test.isequal(" /MD /W3 /GR /GX /I \"..\\src\" /I \"..\\include\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /I \"..\\src\" /I \"..\\include\" /YX /FD /c", cppflags("Release"))
	end


	function suite.pathsInPackageConfig()
		filter "configurations:Debug"
		includedirs { "../debug" }
		filter "configurations:Release"
		includedirs { "../release" }
		test.isequal(" /MD /W3 /GR /GX /I \"..\\debug\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /I \"..\\release\" /YX /FD /c", cppflags("Release"))
	end


	function suite.pathsOnPackageAndConfig()
		includedirs { "../package" }
		filter "configurations:Debug"
		includedirs { "../debug" }
		filter "configurations:Release"
		includedirs { "../release" }
		test.isequal(" /MD /W3 /GR /GX /I \"..\\package\" /I \"..\\debug\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /I \"..\\package\" /I \"..\\release\" /YX /FD /c", cppflags("Release"))
	end
