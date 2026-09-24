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
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Release"))
	end


	function suite.pathsOnPackage()
		includedirs { "../src", "../include" }
		test.isequal(" /MD /W3 /GR /GX /I \"..\\src\" /I \"..\\include\" /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /I \"..\\src\" /I \"..\\include\" /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Release"))
	end


	function suite.pathsInPackageConfig()
		filter "configurations:Debug"
		includedirs { "../debug" }
		filter "configurations:Release"
		includedirs { "../release" }
		test.isequal(" /MD /W3 /GR /GX /I \"..\\debug\" /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /I \"..\\release\" /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Release"))
	end


	function suite.pathsOnPackageAndConfig()
		includedirs { "../package" }
		filter "configurations:Debug"
		includedirs { "../debug" }
		filter "configurations:Release"
		includedirs { "../release" }
		test.isequal(" /MD /W3 /GR /GX /I \"..\\package\" /I \"..\\debug\" /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Debug"))
		test.isequal(" /MD /W3 /GR /GX /I \"..\\package\" /I \"..\\release\" /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Release"))
	end


--
-- externalincludedirs and includedirsafter follow includedirs, in that
-- order (msc.getincludedirs for pre-v142 toolsets; VC6 has only /I)
--

	function suite.externalIncludeDirsOnPackage()
		includedirs { "inc" }
		externalincludedirs { "ext" }
		test.isequal(" /MD /W3 /GR /GX /I \"inc\" /I \"ext\" /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Debug"))
	end


	function suite.includeDirsAfterOnPackage()
		includedirs { "inc" }
		includedirsafter { "after" }
		test.isequal(" /MD /W3 /GR /GX /I \"inc\" /I \"after\" /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", cppflags("Debug"))
	end


--
-- forceincludes: /FI flags after the defines (msc.getforceincludes)
--

	function suite.forceIncludesOnPackage()
		forceincludes { "pch.h", "../common/base.h" }
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /FI \"pch.h\" /FI \"..\\common\\base.h\" /YX /FD /c", cppflags("Debug"))
	end
