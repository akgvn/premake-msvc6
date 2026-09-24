--
-- test_vs6_libpaths.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_LibPaths.cs; expectations
-- follow premake5-native semantics (docs/3x-to-native.md). The module
-- emits Windows path separators.
--

	local p = premake
	local suite = test.declare("vs6_libpaths")
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

	local function linkflags(cfgname)
		return dsp.linkFlags(test.getconfig(test.getproject(wks, 1), cfgname))
	end


	function suite.noLibPaths()
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\"", linkflags("Release"))
	end


	function suite.pathsOnPackage()
		libdirs { "../src", "../include" }
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\" /libpath:\"..\\src\" /libpath:\"..\\include\"", linkflags("Debug"))
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\" /libpath:\"..\\src\" /libpath:\"..\\include\"", linkflags("Release"))
	end


	function suite.pathsInPackageConfig()
		filter "configurations:Debug"
		libdirs { "../debug" }
		filter "configurations:Release"
		libdirs { "../release" }
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\" /libpath:\"..\\debug\"", linkflags("Debug"))
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\" /libpath:\"..\\release\"", linkflags("Release"))
	end


	function suite.pathsOnPackageAndConfig()
		libdirs { "../package" }
		filter "configurations:Debug"
		libdirs { "../debug" }
		filter "configurations:Release"
		libdirs { "../release" }
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\" /libpath:\"..\\package\" /libpath:\"..\\debug\"", linkflags("Debug"))
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\" /libpath:\"..\\package\" /libpath:\"..\\release\"", linkflags("Release"))
	end


--
-- syslibdirs follow libdirs (msc.getLibraryDirectories)
--

	function suite.sysLibDirsOnPackage()
		libdirs { "libs" }
		syslibdirs { "syslibs" }
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\" /libpath:\"libs\" /libpath:\"syslibs\"", linkflags("Debug"))
	end
