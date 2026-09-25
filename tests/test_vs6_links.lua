--
-- test_vs6_links.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Links.cs; expectations follow
-- premake5-native semantics (docs/3x-to-native.md).
--

	local p = premake
	local suite = test.declare("vs6_links")
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


	function suite.linksOnPackage()
		links { "lib1", "lib2" }
		test.isequal(" lib1.lib lib2.lib /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
		test.isequal(" lib1.lib lib2.lib /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\"", linkflags("Release"))
	end


	function suite.linksOnPackageConfig()
		filter "configurations:Debug"
		links { "lib1-d" }
		filter "configurations:Release"
		links { "lib1" }
		test.isequal(" lib1-d.lib /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
		test.isequal(" lib1.lib /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\"", linkflags("Release"))
	end


	function suite.linksOnPackageAndConfig()
		links { "pkglib" }
		filter "configurations:Debug"
		links { "liba-d" }
		filter "configurations:Release"
		links { "liba" }
		test.isequal(" pkglib.lib liba-d.lib /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
		test.isequal(" pkglib.lib liba.lib /nologo /subsystem:console /machine:I386 /out:\"bin\\Release\\MyPackage.exe\" /libpath:\"bin\\Release\"", linkflags("Release"))
	end


--
-- A link name already carrying a library extension is kept as-is
-- (msc.getlinks); otherwise .lib is appended.
--

	function suite.linksWithExtension()
		links { "explicit.lib", "objects.obj", "plain" }
		test.isequal(" explicit.lib objects.obj plain.lib /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
	end


--
-- Path-like link entries: the oven absolutizes them; the module
-- re-relativizes and emits backslashes (VC6-authored style)
--

	function suite.linksWithPath()
		links { "../lib/tran.lib" }
		test.isequal(" ..\\lib\\tran.lib /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
	end


--
-- ignoredefaultlibraries: /nodefaultlib flags after /nologo, .lib
-- appended when no library extension is present (msc.getldflags)
--

	function suite.ignoreDefaultLibraries()
		ignoredefaultlibraries { "libcmt", "msvcrt.lib" }
		test.isequal(" /nologo /nodefaultlib:\"libcmt.lib\" /nodefaultlib:\"msvcrt.lib\" /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
	end


--
-- mapfile "On" (+ optional mapfilepath) and profile
--

	function suite.mapfileOn()
		mapfile "On"
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /map /libpath:\"bin\\Debug\"", linkflags("Debug"))
	end


	function suite.mapfilePath()
		mapfile "On"
		mapfilepath "logs/app.map"
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /map:\"logs\\app.map\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
	end


	function suite.mapfilePathWithoutMapfile()
		mapfilepath "logs/app.map"
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /libpath:\"bin\\Debug\"", linkflags("Debug"))
	end


	function suite.profileOn()
		profile "On"
		test.isequal(" /nologo /subsystem:console /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /profile /libpath:\"bin\\Debug\"", linkflags("Debug"))
	end
