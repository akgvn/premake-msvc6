--
-- test_vs6_resources.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Resources.cs
--
-- 3.x merges defines/includepaths into the resource compiler lines; these
-- tests pin that merging. The 3.x Release configuration had an implicit
-- no-symbols flag (NDEBUG resource symbol); premake5 has no such default,
-- and this module keeps the 3.x symbols-on default, so all configurations
-- use _DEBUG unless symbols "Off" is set.
--
-- Note: the module emits Windows path separators (OQ-7).
--

	local p = premake
	local suite = test.declare("vs6_resources")
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

	local function rscflags(cfgname)
		return dsp.rscFlags(test.getconfig(test.getproject(wks, 1), cfgname))
	end


	function suite.usesIncludePaths()
		includedirs { "include" }
		test.isequal(" /l 0x409 /d \"_DEBUG\" /i \"include\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"_DEBUG\" /i \"include\"", rscflags("Release"))
	end


	function suite.usesResourcePaths()
		resincludedirs { "resources" }
		test.isequal(" /l 0x409 /d \"_DEBUG\" /i \"resources\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"_DEBUG\" /i \"resources\"", rscflags("Release"))
	end


	function suite.mergesIncludeAndResourcePaths()
		includedirs { "include" }
		resincludedirs { "resources" }
		test.isequal(" /l 0x409 /d \"_DEBUG\" /i \"include\" /i \"resources\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"_DEBUG\" /i \"include\" /i \"resources\"", rscflags("Release"))
	end


	function suite.usesDefines()
		defines { "MYDEFINE" }
		test.isequal(" /l 0x409 /d \"_DEBUG\" /d \"MYDEFINE\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"_DEBUG\" /d \"MYDEFINE\"", rscflags("Release"))
	end


	function suite.usesResourceDefines()
		resdefines { "RESDEFINE" }
		test.isequal(" /l 0x409 /d \"_DEBUG\" /d \"RESDEFINE\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"_DEBUG\" /d \"RESDEFINE\"", rscflags("Release"))
	end


	function suite.usesDefinesAndResourceDefines()
		defines { "MYDEFINE" }
		resdefines { "RESDEFINE" }
		test.isequal(" /l 0x409 /d \"_DEBUG\" /d \"MYDEFINE\" /d \"RESDEFINE\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"_DEBUG\" /d \"MYDEFINE\" /d \"RESDEFINE\"", rscflags("Release"))
	end


	function suite.usesResourceOptions()
		resoptions { "ABC", "XYZ" }
		test.isequal(" /l 0x409 /d \"_DEBUG\" ABC XYZ", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"_DEBUG\" ABC XYZ", rscflags("Release"))
	end
