--
-- test_vs6_defines.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Defines.cs
--

	local p = premake
	local suite = test.declare("vs6_defines")
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


	function suite.noDefines()
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", cppflags("Release"))
	end


	function suite.definesOnPackage()
		defines { "TRACE", "EXPORT=__declspec(dllexport)" }
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /D \"TRACE\" /D \"EXPORT=__declspec(dllexport)\" /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /D \"TRACE\" /D \"EXPORT=__declspec(dllexport)\" /YX /FD /GZ /c", cppflags("Release"))
	end


	function suite.definesInPackageConfig()
		filter "configurations:Debug"
		defines { "DEBUG" }
		filter "configurations:Release"
		defines { "NDEBUG" }
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /D \"DEBUG\" /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /D \"NDEBUG\" /YX /FD /GZ /c", cppflags("Release"))
	end


	function suite.definesOnPackageAndConfig()
		defines { "TRACE" }
		filter "configurations:Debug"
		defines { "DEBUG" }
		filter "configurations:Release"
		defines { "NDEBUG" }
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /D \"TRACE\" /D \"DEBUG\" /YX /FD /GZ /c", cppflags("Debug"))
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /D \"TRACE\" /D \"NDEBUG\" /YX /FD /GZ /c", cppflags("Release"))
	end
