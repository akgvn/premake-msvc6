--
-- test_vs6_resources.lua
-- Resource compiler line behavior: defines/includedirs are merged with
-- the resource-specific lists. The debug symbol follows premake5's
-- symbols setting (default NDEBUG — docs/3x-to-native.md). The module
-- emits Windows path separators.
--

	local p = premake
	local suite = test.declare("vs6_resources")
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

	local function rscflags(cfgname)
		return dsp.rscFlags(test.getconfig(test.getproject(wks, 1), cfgname))
	end


	function suite.usesIncludePaths()
		includedirs { "include" }
		test.isequal(" /l 0x409 /d \"NDEBUG\" /i \"include\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"NDEBUG\" /i \"include\"", rscflags("Release"))
	end


	function suite.usesResourcePaths()
		resincludedirs { "resources" }
		test.isequal(" /l 0x409 /d \"NDEBUG\" /i \"resources\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"NDEBUG\" /i \"resources\"", rscflags("Release"))
	end


	function suite.mergesIncludeAndResourcePaths()
		includedirs { "include" }
		resincludedirs { "resources" }
		test.isequal(" /l 0x409 /d \"NDEBUG\" /i \"include\" /i \"resources\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"NDEBUG\" /i \"include\" /i \"resources\"", rscflags("Release"))
	end


	function suite.usesDefines()
		defines { "MYDEFINE" }
		test.isequal(" /l 0x409 /d \"NDEBUG\" /d \"MYDEFINE\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"NDEBUG\" /d \"MYDEFINE\"", rscflags("Release"))
	end


	function suite.usesResourceDefines()
		resdefines { "RESDEFINE" }
		test.isequal(" /l 0x409 /d \"NDEBUG\" /d \"RESDEFINE\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"NDEBUG\" /d \"RESDEFINE\"", rscflags("Release"))
	end


	function suite.usesDefinesAndResourceDefines()
		defines { "MYDEFINE" }
		resdefines { "RESDEFINE" }
		test.isequal(" /l 0x409 /d \"NDEBUG\" /d \"MYDEFINE\" /d \"RESDEFINE\"", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"NDEBUG\" /d \"MYDEFINE\" /d \"RESDEFINE\"", rscflags("Release"))
	end


	function suite.usesResourceOptions()
		resoptions { "ABC", "XYZ" }
		test.isequal(" /l 0x409 /d \"NDEBUG\" ABC XYZ", rscflags("Debug"))
		test.isequal(" /l 0x409 /d \"NDEBUG\" ABC XYZ", rscflags("Release"))
	end


--
-- locale: the RSC /l LCID follows premake5's locale API (the same
-- culture codes vstudio uses for its Culture element); default is 0x409
--

	function suite.localeCzech()
		locale "cs-CZ"
		test.isequal(" /l 0x405 /d \"NDEBUG\"", rscflags("Debug"))
	end


	function suite.localeGerman()
		locale "de-DE"
		test.isequal(" /l 0x407 /d \"NDEBUG\"", rscflags("Debug"))
	end


	function suite.localeUnsetIsDefault()
		test.isequal(" /l 0x409 /d \"NDEBUG\"", rscflags("Debug"))
	end
