--
-- test_vs6_coverage.lua
-- Pairwise coverage of the reachable VC6 build-option space.
--
-- The full cross-product of the options the vs6 module honors is in the
-- thousands, so this suite uses a greedy pairwise construction: every
-- pair of `option=value` assignments from two distinct dimensions appears
-- in at least one generated case. Each case asserts the exact
-- CPP / RSC / LINK32 line (the per-feature suites pin the individual
-- mappings; this suite catches interaction and ordering bugs).
--
-- The expected strings are re-derived here from docs/coverage-matrix.md
-- rather than returned by the module, so a writer/matrix divergence or an
-- interaction regression fails. Explicit tests for the documented
-- legality rules and the buildoptions escape hatch follow the walk.
--

	local p = premake
	local suite = test.declare("vs6_coverage")
	local vs6 = p.modules.vs6
	local dsp = vs6.dsp


--
-- Setup: one console application with a single Debug configuration. Each
-- generated case applies its option dimensions on top of this.
--

	local wks, prj

	function suite.setup()
		p.action.set("vs6")
		wks = workspace("MyProject")
		configurations { "Debug" }
		prj = project("MyPackage")
		language "C++"
		kind "ConsoleApp"
		files { "somefile.txt" }
	end

	local function getcfg()
		return test.getconfig(test.getproject(wks, 1), "Debug")
	end


--
-- Greedy pairwise generator. `specs` maps each dimension name to
-- { order = { value ids }, default = id, values = { [id] = value } }.
-- Returns rows resolved to value tables with every dimension filled.
--

	local function pairwise(spec)
		local names = spec.order
		local specs = spec.factors

		local reqs = {}
		for i = 1, #names do
			for j = i + 1, #names do
				local fi, fj = names[i], names[j]
				for _, vi in ipairs(specs[fi].order) do
					for _, vj in ipairs(specs[fj].order) do
						table.insert(reqs, { fi, vi, fj, vj })
					end
				end
			end
		end

		local rows = {}
		for _, req in ipairs(reqs) do
			local placed = false
			for _, row in ipairs(rows) do
				local a, b = row[req[1]], row[req[3]]
				if (a == nil or a == req[2]) and (b == nil or b == req[4]) then
					row[req[1]] = req[2]
					row[req[3]] = req[4]
					placed = true
					break
				end
			end
			if not placed then
				table.insert(rows, { [req[1]] = req[2], [req[3]] = req[4] })
			end
		end

		local resolved = {}
		for _, row in ipairs(rows) do
			local r = {}
			for _, name in ipairs(names) do
				r[name] = specs[name].values[row[name] or specs[name].default]
			end
			table.insert(resolved, r)
		end
		return resolved
	end


--
-- Compiler dimensions and expected CPP line.
--

	local CPP = {
		order = {
			"runtime", "warnings", "fatalwarnings", "minimalrebuild", "rtti",
			"exceptions", "debug", "optimize", "omitframepointer", "includedirs",
			"characterset", "defines", "forceincludes", "pch", "buildoptions",
		},
		factors = {
			runtime = {
				default = "md",
				order = { "md", "mdd", "mt", "mtd" },
				values = {
					md  = { flag = "/MD",  apply = function() runtime "Release"; staticruntime "Off" end },
					mdd = { flag = "/MDd", gz = true, apply = function() runtime "Debug";   staticruntime "Off" end },
					mt  = { flag = "/MT",  apply = function() runtime "Release"; staticruntime "On"  end },
					mtd = { flag = "/MTd", gz = true, apply = function() runtime "Debug";   staticruntime "On"  end },
				},
			},
			warnings = {
				default = "default",
				order = { "default", "off", "extra" },
				values = {
					default = { flag = "/W3" },
					off     = { flag = "/W0", apply = function() warnings "Off" end },
					extra   = { flag = "/W4", apply = function() warnings "Extra" end },
				},
			},
			fatalwarnings = {
				default = "off",
				order = { "off", "all" },
				values = {
					off = {},
					all = { on = true, apply = function() fatalwarnings { "All" } end },
				},
			},
			minimalrebuild = {
				default = "off",
				order = { "off", "on" },
				values = {
					off = {},
					on  = { on = true, apply = function() minimalrebuild "On" end },
				},
			},
			rtti = {
				default = "on",
				order = { "on", "off" },
				values = {
					on  = { on = true },
					off = { apply = function() rtti "Off" end },
				},
			},
			exceptions = {
				default = "on",
				order = { "on", "off" },
				values = {
					on  = { on = true },
					off = { apply = function() exceptionhandling "Off" end },
				},
			},
			debug = {
				default = "off",
				order = { "off", "on", "c7", "ecoff" },
				values = {
					off   = {},
					on    = { kind = "on",    apply = function() symbols "On" end },
					c7    = { kind = "c7",    apply = function() symbols "On"; debugformat "c7" end },
					ecoff = { kind = "ecoff", apply = function() symbols "On"; editandcontinue "Off" end },
				},
			},
			optimize = {
				default = "default",
				order = { "default", "off", "debug", "on", "speed", "size", "full" },
				values = {
					default = {},
					off     = { flag = "/Od", apply = function() optimize "Off" end },
					debug   = { flag = "/Od", apply = function() optimize "Debug" end },
					on      = { flag = "/Ot", optimized = true, apply = function() optimize "On" end },
					speed   = { flag = "/O2", optimized = true, apply = function() optimize "Speed" end },
					size    = { flag = "/O1", optimized = true, apply = function() optimize "Size" end },
					full    = { flag = "/Ox", optimized = true, apply = function() optimize "Full" end },
				},
			},
			omitframepointer = {
				default = "off",
				order = { "off", "on" },
				values = {
					off = {},
					on  = { on = true, apply = function() omitframepointer "On" end },
				},
			},
			includedirs = {
				default = "none",
				order = { "none", "one", "all" },
				values = {
					none = {},
					one  = { flags = { '/I "inc"' }, apply = function() includedirs { "inc" } end },
					all  = {
						flags = { '/I "inc"', '/I "ext"', '/I "after"' },
						apply = function()
							includedirs { "inc" }
							externalincludedirs { "ext" }
							includedirsafter { "after" }
						end,
					},
				},
			},
			characterset = {
				default = "default",
				order = { "default", "mbcs", "ascii" },
				values = {
					default = { defines = { '/D "_UNICODE"', '/D "UNICODE"' } },
					mbcs    = { defines = { '/D "_MBCS"' }, apply = function() characterset "MBCS" end },
					ascii   = { defines = {}, apply = function() characterset "ASCII" end },
				},
			},
			defines = {
				default = "none",
				order = { "none", "def", "defundef" },
				values = {
					none     = {},
					def      = { flags = { '/D "MYDEF"' }, apply = function() defines { "MYDEF" } end },
					defundef = {
						flags = { '/D "MYDEF"', '/U "MYUNDEF"' },
						apply = function()
							defines { "MYDEF" }
							undefines { "MYUNDEF" }
						end,
					},
				},
			},
			forceincludes = {
				default = "none",
				order = { "none", "one" },
				values = {
					none = {},
					one  = { flags = { '/FI "pch.h"' }, apply = function() forceincludes { "pch.h" } end },
				},
			},
			pch = {
				default = "default",
				order = { "default", "header", "off" },
				values = {
					default = { flag = "/YX" },
					header  = { flag = '/Yu"stdafx.h"', apply = function() pchheader "stdafx.h" end },
					off     = { apply = function() pchheader "stdafx.h"; enablepch "Off" end },
				},
			},
			buildoptions = {
				default = "none",
				order = { "none", "one" },
				values = {
					none = {},
					one  = { flag = "extra", apply = function() buildoptions { "extra" } end },
				},
			},
		},
	}

	local function expectedCpp(row)
		local r = {}
		table.insert(r, row.runtime.flag)
		table.insert(r, row.warnings.flag)
		if row.fatalwarnings.on then table.insert(r, "/WX") end
		if row.minimalrebuild.on then table.insert(r, "/Gm") end
		if row.rtti.on then table.insert(r, "/GR") end
		if row.exceptions.on then table.insert(r, "/GX") end
		if row.debug.kind == "on" then
			table.insert(r, row.optimize.optimized and "/Zi" or "/ZI")
		elseif row.debug.kind == "c7" then
			table.insert(r, "/Z7")
		elseif row.debug.kind == "ecoff" then
			table.insert(r, "/Zi")
		end
		if row.optimize.flag then table.insert(r, row.optimize.flag) end
		if row.omitframepointer.on then table.insert(r, "/Oy") end
		for _, f in ipairs(row.includedirs.flags or {}) do table.insert(r, f) end
		for _, f in ipairs(row.characterset.defines or {}) do table.insert(r, f) end
		for _, f in ipairs(row.defines.flags or {}) do table.insert(r, f) end
		for _, f in ipairs(row.forceincludes.flags or {}) do table.insert(r, f) end
		if row.pch.flag then table.insert(r, row.pch.flag) end
		table.insert(r, "/FD")
		if row.runtime.gz then table.insert(r, "/GZ") end
		table.insert(r, "/c")
		if row.buildoptions.flag then table.insert(r, row.buildoptions.flag) end
		return " " .. table.concat(r, " ")
	end


--
-- Linker dimensions and expected LINK32 line. StaticLib is exercised
-- separately (it emits LIB32, not LINK32).
--

	local LINK = {
		order = {
			"kind", "symbols", "incrementallink", "entrypoint",
			"useimportlib", "mapfile", "profile", "symbolspath",
			"nodefaultlib", "links", "libdirs", "syslibdirs", "linkoptions",
		},
		factors = {
			kind = {
				default = "console",
				order = { "console", "windowed", "shared" },
				values = {
					console  = { subsystem = "/subsystem:console", isexe = true, ext = ".exe" },
					windowed = { subsystem = "/subsystem:windows", isexe = true, ext = ".exe",
						apply = function() kind "WindowedApp" end },
					shared   = { subsystem = "/dll", isdll = true, ext = ".dll",
						apply = function() kind "SharedLib" end },
				},
			},
			symbols = {
				default = "off",
				order = { "off", "on" },
				values = {
					off = {},
					on  = { on = true, apply = function() symbols "On" end },
				},
			},
			incrementallink = {
				default = "default",
				order = { "default", "on", "off" },
				values = {
					default = {},
					on      = { flag = "/incremental:yes", apply = function() incrementallink "On" end },
					off     = { flag = "/incremental:no",  apply = function() incrementallink "Off" end },
				},
			},
			entrypoint = {
				default = "none",
				order = { "none", "set" },
				values = {
					none = {},
					set  = { name = "main2", apply = function() entrypoint "main2" end },
				},
			},
			useimportlib = {
				default = "default",
				order = { "default", "off" },
				values = {
					default = {},
					off     = { off = true, apply = function() useimportlib "Off" end },
				},
			},
			mapfile = {
				default = "off",
				order = { "off", "on", "path" },
				values = {
					off  = {},
					on   = { flag = "/map", apply = function() mapfile "On" end },
					path = { flag = '/map:"logs\\app.map"',
						apply = function() mapfile "On"; mapfilepath "logs/app.map" end },
				},
			},
			profile = {
				default = "off",
				order = { "off", "on" },
				values = {
					off = {},
					on  = { on = true, apply = function() profile "On" end },
				},
			},
			symbolspath = {
				default = "none",
				order = { "none", "set" },
				values = {
					none = {},
					set  = { path = 'logs\\app.pdb', apply = function() symbolspath "logs/app.pdb" end },
				},
			},
			nodefaultlib = {
				default = "none",
				order = { "none", "one" },
				values = {
					none = {},
					one  = { flag = '/nodefaultlib:"libx.lib"',
						apply = function() ignoredefaultlibraries { "libx" } end },
				},
			},
			links = {
				default = "none",
				order = { "none", "one" },
				values = {
					none = {},
					one  = { name = "foo.lib", apply = function() links { "foo" } end },
				},
			},
			libdirs = {
				default = "none",
				order = { "none", "one" },
				values = {
					none = {},
					one  = { flag = '/libpath:"libs"', apply = function() libdirs { "libs" } end },
				},
			},
			syslibdirs = {
				default = "none",
				order = { "none", "one" },
				values = {
					none = {},
					one  = { flag = '/libpath:"syslibs"', apply = function() syslibdirs { "syslibs" } end },
				},
			},
			linkoptions = {
				default = "none",
				order = { "none", "one" },
				values = {
					none = {},
					one  = { flag = "extra", apply = function() linkoptions { "extra" } end },
				},
			},
		},
	}

	local function expectedLink(row)
		local r = {}
		if row.links.name then table.insert(r, row.links.name) end
		table.insert(r, "/nologo")
		if row.nodefaultlib.flag then table.insert(r, row.nodefaultlib.flag) end
		if row.entrypoint.name and row.kind.isexe then
			table.insert(r, '/entry:"' .. row.entrypoint.name .. '"')
		end
		table.insert(r, row.kind.subsystem)
		if row.symbols.on then table.insert(r, "/debug") end
		if row.incrementallink.flag then table.insert(r, row.incrementallink.flag) end
		table.insert(r, "/machine:I386")
		if row.kind.isdll and not row.useimportlib.off then
			table.insert(r, '/implib:"bin\\Debug\\MyPackage.lib"')
		end
		table.insert(r, '/out:"bin\\Debug\\MyPackage' .. (row.kind.ext or ".exe") .. '"')
		if row.symbols.on then
			if row.symbolspath.path then table.insert(r, '/pdb:"' .. row.symbolspath.path .. '"') end
			table.insert(r, "/pdbtype:sept")
		end
		if row.mapfile.flag then table.insert(r, row.mapfile.flag) end
		if row.profile.on then table.insert(r, "/profile") end
		table.insert(r, '/libpath:"bin\\Debug"')
		if row.libdirs.flag then table.insert(r, row.libdirs.flag) end
		if row.syslibdirs.flag then table.insert(r, row.syslibdirs.flag) end
		if row.linkoptions.flag then table.insert(r, row.linkoptions.flag) end
		return " " .. table.concat(r, " ")
	end


--
-- Resource-compiler dimensions and expected RSC line.
--

	local RSC = {
		order = { "locale", "symbols", "declares", "incdirs", "resoptions" },
		factors = {
			locale = {
				default = "default",
				order = { "default", "cs", "de" },
				values = {
					default = { lcid = "0x409" },
					cs      = { lcid = "0x405", apply = function() locale "cs-CZ" end },
					de      = { lcid = "0x407", apply = function() locale "de-DE" end },
				},
			},
			symbols = {
				default = "off",
				order = { "off", "on" },
				values = {
					off = {},
					on  = { on = true, apply = function() symbols "On" end },
				},
			},
			declares = {
				default = "none",
				order = { "none", "defines", "resdefines", "marker" },
				values = {
					none      = {},
					defines   = { defs = { "MYDEF" }, apply = function() defines { "MYDEF" } end },
					resdefines = { res = { "RESDEF" }, apply = function() resdefines { "RESDEF" } end },
					marker    = {
						marker = true,
						apply = function(row)
							if row.symbols.on then defines { "_DEBUG" } else defines { "NDEBUG" } end
						end,
					},
				},
			},
			incdirs = {
				default = "none",
				order = { "none", "inc", "res", "both" },
				values = {
					none = {},
					inc  = { inc = "include", apply = function() includedirs { "include" } end },
					res  = { res = "resources", apply = function() resincludedirs { "resources" } end },
					both = {
						inc = "include", res = "resources",
						apply = function()
							includedirs { "include" }
							resincludedirs { "resources" }
						end,
					},
				},
			},
			resoptions = {
				default = "none",
				order = { "none", "one" },
				values = {
					none = {},
					one  = { flag = "ABC", apply = function() resoptions { "ABC" } end },
				},
			},
		},
	}

	local function expectedRsc(row)
		local marker = row.symbols.on and "_DEBUG" or "NDEBUG"
		local tokens = { "/l " .. row.locale.lcid }

		local defs, res = {}, {}
		for _, d in ipairs(row.declares.defs or {}) do table.insert(defs, d) end
		for _, d in ipairs(row.declares.res or {}) do table.insert(res, d) end
		if row.declares.marker then table.insert(defs, marker) end

		local declared = false
		for _, d in ipairs(defs) do if d == marker then declared = true end end
		for _, d in ipairs(res) do if d == marker then declared = true end end
		if not declared then table.insert(tokens, '/d "' .. marker .. '"') end
		for _, d in ipairs(defs) do table.insert(tokens, '/d "' .. d .. '"') end
		for _, d in ipairs(res) do table.insert(tokens, '/d "' .. d .. '"') end

		if row.incdirs.inc then table.insert(tokens, '/i "' .. row.incdirs.inc .. '"') end
		if row.incdirs.res then table.insert(tokens, '/i "' .. row.incdirs.res .. '"') end
		if row.resoptions.flag then table.insert(tokens, row.resoptions.flag) end

		return " " .. table.concat(tokens, " ")
	end


--
-- Register one test per generated row.
--

	local function register(prefix, spec, actualFn, expectedFn)
		local rows = pairwise(spec)
		for i, row in ipairs(rows) do
			local name = string.format("%s_%02d", prefix, i)
			suite[name] = function()
				for _, value in pairs(row) do
					if value.apply then value.apply(row) end
				end
				test.isequal(expectedFn(row), actualFn())
			end
		end
	end

	register("cpp", CPP, function() return dsp.cppFlags(getcfg()) end, expectedCpp)
	register("link", LINK, function() return dsp.linkFlags(getcfg()) end, expectedLink)
	register("rsc", RSC, function() return dsp.rscFlags(getcfg()) end, expectedRsc)


--
-- Documented legality rules (explicit, pinned strings).
--

	function suite.legality_ziUnderOptimization()
		symbols "On"
		optimize "Speed"
		test.isequal(" /MD /W3 /GR /GX /Zi /O2 /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", dsp.cppFlags(getcfg()))
	end


	function suite.legality_ziWhenEditAndContinueOff()
		symbols "On"
		editandcontinue "Off"
		test.isequal(" /MDd /W3 /GR /GX /Zi /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /GZ /c", dsp.cppFlags(getcfg()))
	end


	function suite.legality_ziWhenNotOptimized()
		symbols "On"
		test.isequal(" /MDd /W3 /GR /GX /ZI /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /GZ /c", dsp.cppFlags(getcfg()))
	end


	function suite.legality_c7SuppressesPdbFile()
		symbols "On"
		debugformat "c7"
		symbolspath "logs/app.pdb"
		test.isequal(" /nologo /subsystem:console /debug /machine:I386 /out:\"bin\\Debug\\MyPackage.exe\" /pdbtype:sept /libpath:\"bin\\Debug\"", dsp.linkFlags(getcfg()))
	end


	function suite.legality_gzOnlyWithDebugRuntime()
		runtime "Debug"
		test.isequal(" /MDd /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /GZ /c", dsp.cppFlags(getcfg()))
	end


	function suite.legality_noGzWithReleaseRuntime()
		runtime "Release"
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c", dsp.cppFlags(getcfg()))
	end


	function suite.legality_implibAbsentWithUseimportlibOff()
		kind "SharedLib"
		useimportlib "Off"
		local cfg = getcfg()
		test.isnil(vs6.implib(cfg))
		test.isequal(" /nologo /dll /machine:I386 /out:\"bin\\Debug\\MyPackage.dll\" /libpath:\"bin\\Debug\"", dsp.linkFlags(cfg))
	end


--
-- Buildoptions escape hatch carries the single-flag enums that have no
-- dedicated mapping (see docs/coverage-matrix.md).
--

	function suite.escapeHatch_singleFlagEnums()
		buildoptions { "/Gd", "/Zp8", "/GF", "/Oi", "/Gy", "/J", "/TC", "/Ob1" }
		test.isequal(" /MD /W3 /GR /GX /D \"_UNICODE\" /D \"UNICODE\" /YX /FD /c /Gd /Zp8 /GF /Oi /Gy /J /TC /Ob1", dsp.cppFlags(getcfg()))
	end


--
-- StaticLib takes the LIB32 branch (no LINK32 flags, no MTL).
--

	function suite.staticLibUsesLibrarian()
		kind "StaticLib"
		local bprj = test.getproject(wks, 1)
		local configs = vs6.configs(bprj)
		dsp.configBlock(bprj, configs, 1)
		test.capture [[
!IF  "$(CFG)" == "MyPackage - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Debug"
# PROP BASE Intermediate_Dir "obj"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Debug"
# PROP Intermediate_Dir "obj"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"bin\Debug\MyPackage.lib"

		]]
	end
