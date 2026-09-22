--
-- test_vs6_libpaths.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_LibPaths.cs
--
-- Note: the module emits Windows path separators (OQ-7), so the 3.x
-- "../src" expectations appear here as "..\src".
--

	local p = premake
	local suite = test.declare("vs6_libpaths")
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

	local function linkflags(cfgname)
		return dsp.linkFlags(test.getconfig(test.getproject(wks, 1), cfgname))
	end


	function suite.noLibPaths()
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Debug"))
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Release"))
	end


	function suite.pathsOnPackage()
		libdirs { "../src", "../include" }
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\" /libpath:\"..\\src\" /libpath:\"..\\include\"", linkflags("Debug"))
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\" /libpath:\"..\\src\" /libpath:\"..\\include\"", linkflags("Release"))
	end


	function suite.pathsInPackageConfig()
		filter "configurations:Debug"
		libdirs { "../debug" }
		filter "configurations:Release"
		libdirs { "../release" }
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\" /libpath:\"..\\debug\"", linkflags("Debug"))
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\" /libpath:\"..\\release\"", linkflags("Release"))
	end


	function suite.pathsOnPackageAndConfig()
		libdirs { "../package" }
		filter "configurations:Debug"
		libdirs { "../debug" }
		filter "configurations:Release"
		libdirs { "../release" }
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\" /libpath:\"..\\package\" /libpath:\"..\\debug\"", linkflags("Debug"))
		test.isequal(" /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\" /libpath:\"..\\package\" /libpath:\"..\\release\"", linkflags("Release"))
	end
