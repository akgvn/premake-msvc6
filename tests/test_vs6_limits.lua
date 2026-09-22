--
-- test_vs6_limits.lua
-- Tests for module behaviors that have no 3.x test counterpart; these pin
-- decisions from PLAN.md: OQ-3 (entrypoint), OQ-5 (fail fast on non-Win32
-- platforms), OQ-13/OQ-16 (prebuildcommands/dependson ignored + warned),
-- OQ-15 (premake5-only values warn + fall back to the 3.x default).
--

	local p = premake
	local suite = test.declare("vs6_limits")
	local vs6 = p.modules.vs6
	local dsp = vs6.dsp


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

	local function getcfg(cfgname)
		return test.getconfig(test.getproject(wks, 1), cfgname)
	end

	local function linkflags(cfgname)
		return dsp.linkFlags(getcfg(cfgname))
	end


--
-- OQ-3: entrypoint "X" replaces the default /entry:"mainCRTStartup".
--

	function suite.customEntrypoint()
		entrypoint "myMain"
		test.isequal(" /nologo /entry:\"myMain\" /subsystem:console /incremental:yes /debug /machine:I386 /out:\"MyPackage.exe\" /pdbtype:sept /libpath:\".\"", linkflags("Debug"))
	end


--
-- OQ-5: platforms other than Win32/x86 are rejected; x86 is accepted.
--

	function suite.unsupportedPlatformErrors()
		platforms { "x64" }
		local bprj = test.getproject(wks, 1)
		local ok, err = pcall(vs6.generateProject, bprj)
		test.isfalse(ok)
		test.isnotnil(string.find(err, "not supported", 1, true))
	end

	function suite.x86PlatformAccepted()
		platforms { "x86" }
		local bprj = test.getproject(wks, 1)
		local ok, err = pcall(vs6.generateProject, bprj)
		test.istrue(ok)
	end


--
-- OQ-13: prebuildcommands are ignored with a warning.
--

	function suite.prebuildcommandsIgnored()
		prebuildcommands { "echo pre" }
		local bprj = test.getproject(wks, 1)
		vs6.generateProject(bprj)
		test.stderr("prebuildcommands")
	end


--
-- OQ-16: dependson is ignored with a warning.
--

	function suite.dependsonIgnored()
		dependson { "someproject" }
		local bprj = test.getproject(wks, 1)
		vs6.generateProject(bprj)
		test.stderr("dependson")
	end


--
-- OQ-15: premake5-only optimize/warnings values warn and fall back to
-- the 3.x default behavior.
--

	function suite.unmappedOptimizeWarns()
		optimize "Off"
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", dsp.cppFlags(getcfg("Debug")))
		test.stderr("optimize 'Off'")
	end

	function suite.unmappedWarningsWarns()
		warnings "Off"
		test.isequal(" /MDd /W3 /Gm /GR /GX /ZI /Od /YX /FD /GZ /c", dsp.cppFlags(getcfg("Debug")))
		test.stderr("warnings 'Off'")
	end
