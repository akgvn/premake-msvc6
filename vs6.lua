--
-- vs6.lua
-- Module entry point for the "vs6" action: generates Visual C++ 6.0
-- workspace (.dsw) and project (.dsp) files for C/C++ projects.
--
-- The module follows premake5-native conventions: baked build/link
-- targets, premake5 defaults, and the msc toolset's flag mappings.
-- (It began as a byte-exact port of premake 3.7's vs6 exporter; that
-- state is preserved at tag v1.0-3x-parity. See docs/3x-to-native.md.)
--
-- Copyright (c) 2026 the premake5-vs6 project contributors
-- Based on premake 3.x (vs6.c, vs6_cpp.c) by Jason Perkins
-- SPDX-License-Identifier: GPL-2.0-or-later
--

	-- External modules are only loaded via require(); _preload.lua is not
	-- auto-run, so register the action explicitly (include() is idempotent).
	include("_preload.lua")

	local p = premake

	p.modules.vs6 = {}
	local vs6 = p.modules.vs6


---
-- Path output helper: VC6 files use backslash separators.
---

	function vs6.path(pth)
		return path.translate(pth, "\\")
	end


---
-- Kind helpers. premake5 kinds per configuration map to the VC6 kinds:
-- ConsoleApp = console exe, WindowedApp = windows exe, SharedLib = dll,
-- StaticLib = static lib.
---

	function vs6.isexe(cfg)
		return cfg.kind == p.CONSOLEAPP or cfg.kind == p.WINDOWEDAPP
	end

	function vs6.iswinexe(cfg)
		return cfg.kind == p.WINDOWEDAPP
	end

	function vs6.isdll(cfg)
		return cfg.kind == p.SHAREDLIB
	end

	function vs6.islib(cfg)
		return cfg.kind == p.STATICLIB
	end


---
-- Output locations, straight from the oven-baked targets (premake5
-- semantics: bin/<cfg> defaults, explicit objdir as-is, uniqueness
-- rules, "!" prefix). Returned pre-translation (forward slashes).
---

	-- Output_Dir: directory of the final target
	function vs6.outdir(cfg)
		return p.project.getrelative(cfg.project, cfg.buildtarget.directory)
	end

	-- Intermediate_Dir: baked objects directory
	function vs6.objdir(cfg)
		return p.project.getrelative(cfg.project, cfg.objdir)
	end

	-- the final target path (/out:), relative to the project
	function vs6.target(cfg)
		return cfg.buildtarget.relpath
	end

	-- the import library path (/implib:), or nil when useimportlib is Off
	function vs6.implib(cfg)
		if vs6.noImportLib(cfg) then
			return nil
		end
		return cfg.linktarget.relpath
	end

	-- the trailing /libpath: — the target's own directory, so sibling
	-- project outputs are found
	function vs6.libdir(cfg)
		return p.project.getrelative(cfg.project, cfg.buildtarget.directory)
	end


---
-- Flag accessors, following premake5's msc toolset mappings
-- (src/tools/msc.lua) and vstudio precedents.
---

	-- premake5 default is no symbols
	function vs6.symbols(cfg)
		return cfg.symbols == p.ON
	end

	-- /Z7 / /Zi / /ZI per vstudio's vs200x_vcproj.symbols(): edit-and-
	-- continue (/ZI) is illegal with optimization and disabled when
	-- editandcontinue is Off; /Z7 for debugformat "c7"
	function vs6.debugFlag(cfg)
		if not vs6.symbols(cfg) then
			return nil
		end
		if cfg.debugformat == "c7" then
			return "/Z7"
		end
		if cfg.editandcontinue == p.OFF or p.config.isOptimizedBuild(cfg) then
			return "/Zi"
		end
		return "/ZI"
	end

	-- debug runtime selection, mirroring msc.lua's getRuntimeFlag():
	-- runtime "Debug", or runtime unset for a debug build (symbols
	-- explicitly on, not optimized)
	function vs6.debugRuntime(cfg)
		return cfg.runtime == "Debug"
			or (cfg.runtime == nil and p.config.isDebugBuild(cfg))
	end

	function vs6.staticRuntime(cfg)
		return cfg.staticruntime == p.ON
	end

	-- msc.lua's optimize table; nil means "no flag"
	function vs6.optimizeFlag(cfg)
		local flags = {
			Off   = "/Od",
			Debug = "/Od",
			On    = "/Ot",
			Speed = "/O2",
			Size  = "/O1",
			Full  = "/Ox",
		}
		return flags[cfg.optimize]
	end

	-- msc.lua's warnings table (Everything has no /Wall on VC6 — /W4 is
	-- the highest available)
	function vs6.warnLevel(cfg)
		local w = cfg.warnings
		if w == "Off" then
			return 0
		end
		if w == "Extra" or w == "High" or w == "Everything" then
			return 4
		end
		return 3
	end

	function vs6.fatalWarnings(cfg)
		return cfg.fatalwarnings and table.contains(cfg.fatalwarnings, "All")
	end

	function vs6.rtti(cfg)
		return cfg.rtti ~= p.OFF
	end

	function vs6.exceptions(cfg)
		return cfg.exceptionhandling ~= p.OFF
	end

	function vs6.omitFramePointer(cfg)
		return cfg.omitframepointer == p.ON
	end

	function vs6.noImportLib(cfg)
		if cfg.useimportlib == p.OFF then
			return true
		end
		-- best-effort compat with premake5 beta7, which lacks useimportlib
		return cfg.flags ~= nil and table.contains(cfg.flags, "NoImportLib")
	end

	-- premake5 semantics: /entry: only when entrypoint is explicitly set
	function vs6.entrypoint(cfg)
		local e = cfg.entrypoint
		if e and e ~= "" then
			return e
		end
		return nil
	end


---
-- Configuration enumeration helper.
---

	function vs6.configs(prj)
		local configs = {}
		for cfg in p.project.eachconfig(prj) do
			table.insert(configs, cfg)
		end
		return configs
	end


	include("vs6_dsw.lua")
	include("vs6_dsp.lua")

	return vs6
