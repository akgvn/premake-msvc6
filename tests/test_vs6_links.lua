--
-- test_vs6_links.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Links.cs
--

	local p = premake
	local suite = test.declare("vs6_links")
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


	function suite.linksOnPackage()
		links { "lib1", "lib2" }
		test.isequal(" lib1.lib lib2.lib /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Debug"))
		test.isequal(" lib1.lib lib2.lib /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Release"))
	end


	function suite.linksOnPackageConfig()
		filter "configurations:Debug"
		links { "lib1-d" }
		filter "configurations:Release"
		links { "lib1" }
		test.isequal(" lib1-d.lib /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Debug"))
		test.isequal(" lib1.lib /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Release"))
	end


	function suite.linksOnPackageAndConfig()
		links { "pkglib" }
		filter "configurations:Debug"
		links { "liba-d" }
		filter "configurations:Release"
		links { "liba" }
		test.isequal(" pkglib.lib liba-d.lib /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Debug"))
		test.isequal(" pkglib.lib liba.lib /nologo /entry:\"mainCRTStartup\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Release"))
	end
