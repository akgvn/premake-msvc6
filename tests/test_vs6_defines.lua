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
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Release"))
	end


	function suite.definesOnPackage()
		defines { "TRACE", "EXPORT=__declspec(dllexport)" }
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /D \"TRACE\" /D \"EXPORT=__declspec(dllexport)\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /D \"TRACE\" /D \"EXPORT=__declspec(dllexport)\" /YX /FD /c", cppflags("Release"))
	end


	function suite.definesInPackageConfig()
		filter "configurations:Debug"
		defines { "DEBUG" }
		filter "configurations:Release"
		defines { "NDEBUG" }
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /D \"DEBUG\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /D \"NDEBUG\" /YX /FD /c", cppflags("Release"))
	end


	function suite.definesOnPackageAndConfig()
		defines { "TRACE" }
		filter "configurations:Debug"
		defines { "DEBUG" }
		filter "configurations:Release"
		defines { "NDEBUG" }
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /D \"TRACE\" /D \"DEBUG\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /D \"TRACE\" /D \"NDEBUG\" /YX /FD /c", cppflags("Release"))
	end


--
-- undefines: /U flags after the defines (msc.getundefines)
--

	function suite.undefinesOnPackage()
		undefines { "TRACE", "OLD_API" }
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /U \"TRACE\" /U \"OLD_API\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /U \"TRACE\" /U \"OLD_API\" /YX /FD /c", cppflags("Release"))
	end


--
-- characterset (msc.defines.characterset): premake5's global default is
-- "Default", which msc maps to the Unicode defines
--

	function suite.charactersetDefault()
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Debug"))
	end


	function suite.charactersetUnicode()
		characterset "Unicode"
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Debug"))
	end


	function suite.charactersetMbcs()
		characterset "MBCS"
		test.isequal(" /MD /W3 /GR /GX /D \"_MBCS\" /YX /FD /c", cppflags("Debug"))
	end


	function suite.charactersetAscii()
		characterset "ASCII"
		test.isequal(" /MD /W3 /GR /GX /YX /FD /c", cppflags("Debug"))
	end
