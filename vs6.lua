--
-- vs6.lua
-- Module entry point for the "vs6" action: generates Visual C++ 6.0
-- workspace (.dsw) and project (.dsp) files for C/C++ projects.
--
-- The module is a faithful port of the premake 3.7 vs6 exporter, so the
-- generated files match the premake 3.x output (including its quirks and
-- default directory semantics), not premake5-native conventions.
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
-- Fetch a configuration value as written in the project script, bypassing
-- any post-processing the oven applied to the baked configuration (e.g.
-- cfg.objdir is rewritten to an absolute, buildcfg-suffixed path by
-- oven.bakeObjDirs, which is useless for 3.x-compatible output).
---

	function vs6.rawvalue(cfg, name)
		local field = p.field.get(name)
		if field then
			return p.configset.fetch(cfg._cfgset, field, cfg.terms, cfg)
		end
		return nil
	end


---
-- Path output helper: VC6 files use backslash separators.
---

	function vs6.path(pth)
		return path.translate(pth, "\\")
	end


---
-- Kind helpers. premake5 kinds per configuration map to the 3.x kinds:
-- ConsoleApp = "exe", WindowedApp = "winexe", SharedLib = "dll",
-- StaticLib = "lib".
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
-- Flag accessors, mapping premake5 APIs to the equivalent 3.x build flags.
---

	function vs6.optimizeSize(cfg)
		return cfg.optimize == "Size"
	end

	function vs6.optimizeSpeed(cfg)
		return cfg.optimize == "On" or cfg.optimize == "Speed"
	end

	-- premake5-only optimize values have no 3.x equivalent: warn + default (OQ-15)
	local function checkOptimize(cfg)
		local opt = cfg.optimize
		if opt and not vs6.optimizeSize(cfg) and not vs6.optimizeSpeed(cfg) then
			p.warnOnce("vs6.optimize." .. opt,
				"vs6: optimize '%s' has no VC6 equivalent; using no optimization", opt)
		end
	end

	function vs6.useDebugLibs(cfg)
		checkOptimize(cfg)
		return not vs6.optimizeSize(cfg) and not vs6.optimizeSpeed(cfg)
	end

	function vs6.staticRuntime(cfg)
		return cfg.staticruntime == p.ON
	end

	function vs6.warnLevel(cfg)
		local w = cfg.warnings
		if w == "Extra" then
			return 4
		end
		if w and w ~= "Default" and w ~= "Off" then
			-- "High"/"Everything" have no 3.x equivalent (OQ-15)
			p.warnOnce("vs6.warnings." .. w,
				"vs6: warnings '%s' has no VC6 equivalent; using /W3", w)
		elseif w == "Off" then
			p.warnOnce("vs6.warnings.Off",
				"vs6: warnings 'Off' has no VC6 equivalent; using /W3")
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

	-- 3.x emits debug symbols unless told otherwise; keep that default (the
	-- premake5-native default of "no symbols" would diverge from the oracle)
	function vs6.symbols(cfg)
		return cfg.symbols ~= p.OFF
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

	-- 3.x parity (OQ-3): executables get /entry:"mainCRTStartup" unless an
	-- entrypoint is explicitly set; entrypoint "" suppresses it
	function vs6.entrypoint(cfg)
		local e = cfg.entrypoint
		if e == nil then
			return "mainCRTStartup"
		elseif e == "" then
			return nil
		end
		return e
	end


---
-- Directory and target name computations, following 3.x semantics (OQ-14):
--
-- - targetdir/objdir are read raw (nil means "not set"); the premake5 baked
--   defaults (bin/<cfg>, absolute objdirs) are NOT 3.x compatible.
-- - objdir always gets the configuration name appended.
-- - the 3.x "libdir" (library output dir) maps to the target's own
--   directory for executables/static libraries, and to implibdir for DLL
--   import libraries.
---

	function vs6.targetname(cfg)
		return vs6.rawvalue(cfg, "targetname") or cfg.project.name
	end

	-- 3.x prj_get_outdir_for(): the output directory for the final target
	function vs6.outdir(cfg)
		local dir = vs6.rawvalue(cfg, "targetdir") or "."
		local sub = path.getdirectory(vs6.targetname(cfg))
		if sub and sub ~= "" and sub ~= "." then
			dir = dir .. "/" .. sub
		end
		return dir
	end

	-- 3.x prj_get_objdir(): always <objdir>/<config>
	function vs6.objdir(cfg)
		local dir = vs6.rawvalue(cfg, "objdir") or "obj"
		return dir .. "/" .. cfg.buildcfg
	end

	-- 3.x prj_get_libdir(): where sibling library outputs land; drives the
	-- trailing /libpath: and the DLL import library location
	function vs6.libdir(cfg)
		return vs6.rawvalue(cfg, "targetdir") or "."
	end

	-- 3.x prj_get_target_for(), Windows naming (VS6 is Win32-only)
	function vs6.target(cfg)
		local targetname = vs6.targetname(cfg)
		local basename = path.getbasename(targetname)
		local prefix = cfg.targetprefix or ""

		local ext = cfg.targetextension
		if ext then
			-- premake5 spells it with a leading dot, 3.x without
			ext = ext:gsub("^%.", "")
		elseif vs6.islib(cfg) then
			ext = "lib"
		elseif vs6.isdll(cfg) then
			ext = "dll"
		else
			ext = "exe"
		end

		local outdir = vs6.outdir(cfg)
		local result = ""
		if outdir ~= "." then
			result = outdir .. "/"
		end
		return result .. prefix .. basename .. "." .. ext
	end

	-- 3.x import library path algorithm (vs6_cpp.c writeLinkFlags)
	function vs6.implib(cfg)
		local name = cfg.implibname or path.getbasename(vs6.targetname(cfg))
		if vs6.noImportLib(cfg) then
			return vs6.objdir(cfg) .. "/" .. name .. ".lib"
		end
		local dir = vs6.rawvalue(cfg, "implibdir") or vs6.libdir(cfg)
		local sub = path.getdirectory(vs6.targetname(cfg))
		if sub and sub ~= "" and sub ~= "." then
			dir = dir .. "/" .. sub
		end
		return dir .. "/" .. name .. ".lib"
	end


---
-- Configuration enumeration helpers. 3.x stores configurations in reverse
-- order in the .dsp file and computes a couple of values from the "next"
-- configuration (an off-by-one quirk in 3.7 that is part of its observable
-- output and therefore reproduced here).
---

	function vs6.configs(prj)
		local configs = {}
		for cfg in p.project.eachconfig(prj) do
			table.insert(configs, cfg)
		end
		return configs
	end

	-- the configuration whose flag state is shown by config at index i
	function vs6.rotatedConfig(configs, i)
		return configs[(i % #configs) + 1]
	end


	include("vs6_dsw.lua")
	include("vs6_dsp.lua")

	return vs6
