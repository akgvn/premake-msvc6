--
-- test_vs6_defines.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Defines.cs; expectations follow
-- premake5-native semantics (docs/3x-to-native.md).
--

	local p = premake
	local suite = test.declare("vs6_defines")
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


	function suite.noDefines()
		test.isequal(" /MD /W3 /GR /GX /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /YX /FD /c", cppflags("Release"))
	end


	function suite.definesOnPackage()
		defines { "TRACE", "EXPORT=__declspec(dllexport)" }
		test.isequal(" /MD /W3 /GR /GX /D \"TRACE\" /D \"EXPORT=__declspec(dllexport)\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /D \"TRACE\" /D \"EXPORT=__declspec(dllexport)\" /YX /FD /c", cppflags("Release"))
	end


	function suite.definesInPackageConfig()
		filter "configurations:Debug"
		defines { "DEBUG" }
		filter "configurations:Release"
		defines { "NDEBUG" }
		test.isequal(" /MD /W3 /GR /GX /D \"DEBUG\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /D \"NDEBUG\" /YX /FD /c", cppflags("Release"))
	end


	function suite.definesOnPackageAndConfig()
		defines { "TRACE" }
		filter "configurations:Debug"
		defines { "DEBUG" }
		filter "configurations:Release"
		defines { "NDEBUG" }
		test.isequal(" /MD /W3 /GR /GX /D \"TRACE\" /D \"DEBUG\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /D \"TRACE\" /D \"NDEBUG\" /YX /FD /c", cppflags("Release"))
	end
