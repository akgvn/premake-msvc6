--
-- vs6_dsp.lua
-- Visual C++ 6.0 project (.dsp) file writer.
--
-- Copyright (c) 2026 the premake-msvc6 project contributors
-- Based on premake 3.x (vs6_cpp.c) by Jason Perkins
-- SPDX-License-Identifier: GPL-2.0-or-later
--

	local p = premake
	local vs6 = p.modules.vs6
	local dsp = {}
	vs6.dsp = dsp

	local KINDINFO = {
		WindowedApp = { tag = "Win32 (x86) Application",            id = "0x0101" },
		ConsoleApp  = { tag = "Win32 (x86) Console Application",    id = "0x0103" },
		SharedLib   = { tag = "Win32 (x86) Dynamic-Link Library",   id = "0x0102" },
		StaticLib   = { tag = "Win32 (x86) Static Library",         id = "0x0104" },
	}


---
-- Entry point, called by the action (see _preload.lua).
---

	function vs6.generateProject(prj)
		local configs = vs6.configs(prj)

		-- VS6 is Win32-only; a bad platform would silently produce garbage
		-- configuration names, so fail fast instead
		for _, cfg in ipairs(configs) do
			local platform = cfg.platform
			if platform and platform ~= "x86" and platform ~= "Win32" then
				error("vs6: platform '" .. platform .. "' is not supported by Visual C++ 6.0 (project '" .. prj.name .. "')", 0)
			end
		end

		dsp.header(prj, configs)

		-- configurations are stored in reverse order
		for i = #configs, 1, -1 do
			dsp.configBlock(prj, configs, i)
		end

		p.outln("!ENDIF")
		p.outln("")
		p.outln("# Begin Target")
		p.outln("")
		for i = #configs, 1, -1 do
			p.outln('# Name "' .. prj.name .. ' - Win32 ' .. configs[i].buildcfg .. '"')
		end

		dsp.sourceTree(prj)

		p.outln("# End Target")
		p.outln("# End Project")

		-- p.generate() captures via buffered.tostring(), which trims one
		-- trailing EOL; emit one extra so the file ends with a newline
		p.outln("")
	end


---
-- File header: identification, TARGTYPE, CFG=, the !MESSAGE block, and the
-- fixed project properties. The first configuration decides the TARGTYPE
-- and the CFG= default.
---

	function dsp.header(prj, configs)
		local cfg0 = configs[1]
		local ki = KINDINFO[cfg0.kind]
		if not ki then
			error("vs6: unrecognized project kind '" .. tostring(cfg0.kind) .. "'", 0)
		end

		p.outln('# Microsoft Developer Studio Project File - Name="' .. prj.name .. '" - Package Owner=<4>')
		p.outln('# Microsoft Developer Studio Generated Build File, Format Version 6.00')
		p.outln('# ** DO NOT EDIT **')
		p.outln('')
		p.outln('# TARGTYPE "' .. ki.tag .. '" ' .. ki.id)
		p.outln('')

		p.outln('CFG=' .. prj.name .. ' - Win32 ' .. cfg0.buildcfg)
		p.outln('!MESSAGE This is not a valid makefile. To build this project using NMAKE,')
		p.outln('!MESSAGE use the Export Makefile command and run')
		p.outln('!MESSAGE ')
		p.outln('!MESSAGE NMAKE /f "' .. prj.name .. '.mak".')
		p.outln('!MESSAGE ')
		p.outln('!MESSAGE You can specify a configuration when running NMAKE')
		p.outln('!MESSAGE by defining the macro CFG on the command line. For example:')
		p.outln('!MESSAGE ')
		p.outln('!MESSAGE NMAKE /f "' .. prj.name .. '.mak" CFG="' .. prj.name .. ' - Win32 ' .. cfg0.buildcfg .. '"')
		p.outln('!MESSAGE ')
		p.outln('!MESSAGE Possible choices for configuration are:')
		p.outln('!MESSAGE ')

		for i = #configs, 1, -1 do
			p.outln('!MESSAGE "' .. prj.name .. ' - Win32 ' .. configs[i].buildcfg .. '" (based on "' .. ki.tag .. '")')
		end

		p.outln('!MESSAGE ')
		p.outln('')
		p.outln('# Begin Project')
		p.outln('# PROP AllowPerConfigDependencies 0')
		p.outln('# PROP Scc_ProjName ""')
		p.outln('# PROP Scc_LocalPath ""')
		p.outln('CPP=cl.exe')
		-- MTL appears only where MIDL settings make sense (VC-authored
		-- console apps and static libraries don't carry it)
		if vs6.iswinexe(cfg0) or vs6.isdll(cfg0) then
			p.outln('MTL=midl.exe')
		end
		p.outln('RSC=rc.exe')
		p.outln('')
	end


---
-- One per-configuration !IF/!ELSEIF block. Configs are emitted in reverse
-- order; the first emitted block (the last configuration) gets !IF.
---

	function dsp.configBlock(prj, configs, i)
		local cfg = configs[i]
		local dbglibs = vs6.debugRuntime(cfg) and "1" or "0"

		p.outln((i == #configs and '!IF' or '!ELSEIF') .. '  "$(CFG)" == "' .. prj.name .. ' - Win32 ' .. cfg.buildcfg .. '"')
		p.outln('')

		p.outln('# PROP BASE Use_MFC 0')
		p.outln('# PROP BASE Use_Debug_Libraries ' .. dbglibs)
		p.outln('# PROP BASE Output_Dir "' .. vs6.path(vs6.outdir(cfg)) .. '"')
		p.outln('# PROP BASE Intermediate_Dir "' .. vs6.path(vs6.objdir(cfg)) .. '"')
		p.outln('# PROP BASE Target_Dir ""')
		p.outln('# PROP Use_MFC 0')
		p.outln('# PROP Use_Debug_Libraries ' .. dbglibs)
		p.outln('# PROP Output_Dir "' .. vs6.path(vs6.outdir(cfg)) .. '"')
		p.outln('# PROP Intermediate_Dir "' .. vs6.path(vs6.objdir(cfg)) .. '"')
		if vs6.isdll(cfg) and vs6.noImportLib(cfg) then
			p.outln('# PROP Ignore_Export_Lib 1')
		end
		p.outln('# PROP Target_Dir ""')

		p.outln('# ADD BASE CPP /nologo' .. dsp.cppFlags(cfg))
		p.outln('# ADD CPP /nologo' .. dsp.cppFlags(cfg))

		local sym = vs6.symbols(cfg) and "_DEBUG" or "NDEBUG"

		if vs6.iswinexe(cfg) or vs6.isdll(cfg) then
			p.outln('# ADD BASE MTL /nologo /D "' .. sym .. '" /mktyplib203 /win32')
			p.outln('# ADD MTL /nologo /D "' .. sym .. '" /mktyplib203 /win32')
		end

		local rsc = dsp.rscFlags(cfg)
		p.outln('# ADD BASE RSC' .. rsc)
		p.outln('# ADD RSC' .. rsc)

		p.outln('BSC32=bscmake.exe')
		p.outln('# ADD BASE BSC32 /nologo')
		p.outln('# ADD BSC32 /nologo')

		if vs6.islib(cfg) then
			p.outln('LIB32=link.exe -lib')
			p.outln('# ADD BASE LIB32 /nologo')
			p.outln('# ADD LIB32 /nologo /out:"' .. vs6.path(vs6.target(cfg)) .. '"')
		else
			p.outln('LINK32=link.exe')
			p.outln('# ADD BASE LINK32' .. dsp.linkFlags(cfg))
			p.outln('# ADD LINK32' .. dsp.linkFlags(cfg))
		end

		local prelink = table.join(table.shallowcopy(cfg.prebuildcommands), cfg.prelinkcommands)
		if #prelink > 0 or #cfg.postbuildcommands > 0 then
			p.outln('# Begin Special Build Tool')
			if #prelink > 0 then
				p.outln('PreLink_Cmds=' .. table.concat(prelink, "\t"))
			end
			if #cfg.postbuildcommands > 0 then
				p.outln('PostBuild_Cmds=' .. table.concat(cfg.postbuildcommands, "\t"))
			end
			p.outln('# End Special Build Tool')
		end

		p.outln('')
	end


---
-- Compiler flags for one configuration, following premake5's msc toolset
-- mappings. Returns the flag text following "/nologo" (leading space
-- included).
---

	function dsp.cppFlags(cfg)
		local r = {}
		local debugRuntime = vs6.debugRuntime(cfg)

		table.insert(r, (vs6.staticRuntime(cfg) and "/MT" or "/MD") .. (debugRuntime and "d" or ""))

		table.insert(r, "/W" .. vs6.warnLevel(cfg))

		if vs6.fatalWarnings(cfg) then
			table.insert(r, "/WX")
		end

		if cfg.minimalrebuild == p.ON then
			table.insert(r, "/Gm")
		end

		if vs6.rtti(cfg) then
			table.insert(r, "/GR")
		end

		if vs6.exceptions(cfg) then
			table.insert(r, "/GX")
		end

		local z = vs6.debugFlag(cfg)
		if z then
			table.insert(r, z)
		end

		local o = vs6.optimizeFlag(cfg)
		if o then
			table.insert(r, o)
		end

		if vs6.omitFramePointer(cfg) then
			table.insert(r, "/Oy")
		end

		for _, dir in ipairs(cfg.includedirs) do
			table.insert(r, '/I "' .. vs6.path(p.project.getrelative(cfg.project, dir)) .. '"')
		end

		for _, dir in ipairs(cfg.externalincludedirs) do
			table.insert(r, '/I "' .. vs6.path(p.project.getrelative(cfg.project, dir)) .. '"')
		end

		for _, dir in ipairs(cfg.includedirsafter) do
			table.insert(r, '/I "' .. vs6.path(p.project.getrelative(cfg.project, dir)) .. '"')
		end

		-- characterset defines first, then user defines (msc.getdefines)
		for _, def in ipairs(vs6.charactersetDefines(cfg)) do
			table.insert(r, def)
		end

		for _, def in ipairs(cfg.defines) do
			table.insert(r, '/D "' .. def .. '"')
		end

		for _, undef in ipairs(cfg.undefines) do
			table.insert(r, '/U "' .. undef .. '"')
		end

		for _, file in ipairs(cfg.forceincludes) do
			table.insert(r, '/FI "' .. vs6.path(p.project.getrelative(cfg.project, file)) .. '"')
		end

		if cfg.enablepch ~= p.OFF and cfg.pchheader then
			table.insert(r, '/Yu"' .. cfg.pchheader .. '"')
		elseif cfg.enablepch ~= p.OFF then
			table.insert(r, "/YX")
		end
		table.insert(r, "/FD")

		if debugRuntime then
			table.insert(r, "/GZ")
		end

		table.insert(r, "/c")

		for _, opt in ipairs(cfg.buildoptions) do
			table.insert(r, opt)
		end

		return " " .. table.concat(r, " ")
	end


---
-- Resource compiler flags for one configuration. premake5 merges the
-- regular defines/includedirs with the resource-specific ones.
---

	function dsp.rscFlags(cfg)
		-- /l takes an LCID; premake5's locale API maps ISO locale ids to
		-- culture codes (vstudio.cultureForLocale, used for vs2010's
		-- Culture element). Default is VC6's en-US 0x409.
		local langid = "0x409"
		if cfg.locale then
			-- vstudio is an embedded premake5 module; load on demand
			local culture = require("vstudio").cultureForLocale(cfg.locale)
			if culture then
				langid = string.format("0x%x", culture)
			end
		end

		-- the automatic debug marker is skipped when the script already
		-- defines one explicitly (VC6-parity scripts define _DEBUG/NDEBUG)
		local sym = vs6.symbols(cfg) and "_DEBUG" or "NDEBUG"
		local r = {}
		if not table.contains(cfg.defines, sym) and not table.contains(cfg.resdefines, sym) then
			table.insert(r, '/l ' .. langid .. ' /d "' .. sym .. '"')
		else
			table.insert(r, '/l ' .. langid)
		end

		for _, def in ipairs(cfg.defines) do
			table.insert(r, '/d "' .. def .. '"')
		end
		for _, def in ipairs(cfg.resdefines) do
			table.insert(r, '/d "' .. def .. '"')
		end
		for _, dir in ipairs(cfg.includedirs) do
			table.insert(r, '/i "' .. vs6.path(p.project.getrelative(cfg.project, dir)) .. '"')
		end
		for _, dir in ipairs(cfg.resincludedirs) do
			table.insert(r, '/i "' .. vs6.path(p.project.getrelative(cfg.project, dir)) .. '"')
		end
		for _, opt in ipairs(cfg.resoptions) do
			table.insert(r, opt)
		end

		return " " .. table.concat(r, " ")
	end


---
-- Linker flags for one configuration. Returns the flag text following
-- "# ADD BASE LINK32" (leading space included). Only used for
-- non-static-library kinds.
---

	function dsp.linkFlags(cfg)
		local r = {}
		local wks = cfg.workspace

		-- sibling projects are linked implicitly by VC6; only external
		-- libraries are listed. Like msc.getlinks(), append .lib only
		-- when the name doesn't already carry a library extension. The
		-- oven absolutizes path-like link entries; re-relativize them
		for _, link in ipairs(cfg.links) do
			local name = link:gsub(":static$", ""):gsub(":shared$", "")
			if not p.workspace.findproject(wks, name) then
				if path.isabsolute(name) then
					name = p.project.getrelative(cfg.project, name)
				end
				if not p.tools.msc.getLibraryExtensions()[name:match("[^.]+$")] then
					name = name .. ".lib"
				end
				table.insert(r, vs6.path(name))
			end
		end

		table.insert(r, "/nologo")

		for _, ignore in ipairs(cfg.ignoredefaultlibraries) do
			if not p.tools.msc.getLibraryExtensions()[ignore:match("[^.]+$")] then
				ignore = path.appendextension(ignore, ".lib")
			end
			table.insert(r, '/nodefaultlib:"' .. ignore .. '"')
		end

		local entry = vs6.entrypoint(cfg)
		if vs6.isexe(cfg) and entry then
			table.insert(r, '/entry:"' .. entry .. '"')
		end

		if vs6.iswinexe(cfg) then
			table.insert(r, "/subsystem:windows")
		elseif vs6.isexe(cfg) then
			table.insert(r, "/subsystem:console")
		else
			table.insert(r, "/dll")
		end

		if vs6.symbols(cfg) then
			table.insert(r, "/debug")
		end

		if cfg.incrementallink == p.ON then
			table.insert(r, "/incremental:yes")
		elseif cfg.incrementallink == p.OFF then
			table.insert(r, "/incremental:no")
		end

		table.insert(r, "/machine:I386")

		if vs6.isdll(cfg) then
			local implib = vs6.implib(cfg)
			if implib then
				table.insert(r, '/implib:"' .. vs6.path(implib) .. '"')
			end
		end

		table.insert(r, '/out:"' .. vs6.path(vs6.target(cfg)) .. '"')

		if vs6.symbols(cfg) then
			if cfg.symbolspath and cfg.debugformat ~= "c7" then
				table.insert(r, '/pdb:"' .. vs6.path(p.project.getrelative(cfg.project, cfg.symbolspath)) .. '"')
			end
			table.insert(r, "/pdbtype:sept")
		end

		if cfg.mapfile == p.ON then
			if cfg.mapfilepath then
				table.insert(r, '/map:"' .. vs6.path(p.project.getrelative(cfg.project, cfg.mapfilepath)) .. '"')
			else
				table.insert(r, "/map")
			end
		end

		if cfg.profile then
			table.insert(r, "/profile")
		end

		table.insert(r, '/libpath:"' .. vs6.path(vs6.libdir(cfg)) .. '"')

		for _, dir in ipairs(table.join(cfg.libdirs, cfg.syslibdirs)) do
			table.insert(r, '/libpath:"' .. vs6.path(p.project.getrelative(cfg.project, dir)) .. '"')
		end

		for _, opt in ipairs(cfg.linkoptions) do
			table.insert(r, opt)
		end

		return " " .. table.concat(r, " ")
	end


---
-- The source file tree. Files are grouped by their virtual path (premake5
-- `vpath`; falls back to the physical relative path when no vpath rule
-- matches). Groups are emitted in order of first appearance, before the
-- files of their parent directory; group roots named ".." are skipped.
---

	function dsp.sourceTree(prj)
		-- prj._.files is sorted alphabetically by virtual path; fcfg.order
		-- holds the script declaration index
		local files = {}
		local ordered = table.shallowcopy(prj._.files)
		table.sort(ordered, function(a, b)
			return (a.order or math.huge) < (b.order or math.huge)
		end)
		for _, fcfg in ipairs(ordered) do
			table.insert(files, {
				node = fcfg,
				group = fcfg.vpath,
				source = fcfg.relpath,
			})
		end
		dsp._sourceTree(prj, files, "")
	end

	function dsp._sourceTree(prj, files, dir)
		dsp._treeNode(dir:gsub("/$", ""), "open")

		-- recurse into subdirectories, in order of first appearance
		for i, f in ipairs(files) do
			if #f.group > #dir and f.group:sub(1, #dir) == dir then
				local s = f.group:find("/", #dir + 1, true)
				if s then
					local sub = f.group:sub(1, s)
					local first
					for j, g in ipairs(files) do
						if g.group:sub(1, #sub) == sub then
							first = j
							break
						end
					end
					if first == i then
						dsp._sourceTree(prj, files, sub)
					end
				end
			end
		end

		-- then emit the files that live directly in this directory
		for _, f in ipairs(files) do
			local lastslash = f.group:match("^.*()/")
			if f.group:sub(1, #dir) == dir and (not lastslash or lastslash <= #dir) then
				dsp.sourceFile(prj, f)
			end
		end

		dsp._treeNode(dir:gsub("/$", ""), "close")
	end

	function dsp._treeNode(name, stage)
		-- the last path component is the group name; groups named ".." (and
		-- the anonymous root) are skipped
		local leaf = name:match("[^/]*$")
		if stage == "open" then
			if #name > 0 and leaf ~= ".." then
				p.outln('# Begin Group "' .. vs6.path(leaf) .. '"')
				p.outln('')
				p.outln('# PROP Default_Filter ""')
			end
		elseif stage == "close" then
			if #name > 0 and leaf ~= ".." then
				p.outln('# End Group')
			end
		end
	end


---
-- One source file node: the SOURCE= line (quoted when the path contains
-- spaces — VC6 won't parse unquoted paths with spaces) followed by
-- per-configuration blocks for the configurations the file is excluded
-- from (premake5's excludefrombuild) or custom-built in (premake5's
-- buildcommands/buildoutputs on a files: filter).
---

	function dsp.sourceFile(prj, file)
		p.outln('# Begin Source File')
		p.outln('')

		local src = vs6.path(file.source)
		if src:find(" ", 1, true) then
			src = '"' .. src .. '"'
		end
		p.outln('SOURCE=' .. src)

		-- VC6 mentions only the configurations that differ, in the same
		-- reversed order as the project's configuration blocks
		local configs = vs6.configs(prj)

		-- the PCH source builds the precompiled header; VC6 writes the
		-- /Yc mark config-independent when pchheader is uniform
		local pchflag
		local pchuniform = true
		for _, cfg in ipairs(configs) do
			if cfg.enablepch ~= p.OFF and cfg.pchheader
					and cfg.pchsource == file.node.abspath then
				if pchflag and pchflag ~= cfg.pchheader then
					pchuniform = false
				end
				pchflag = pchflag or cfg.pchheader
			end
		end

		local bodies = {}
		for i = #configs, 1, -1 do
			local cfg = configs[i]
			local fcfg = p.fileconfig.getconfig(file.node, cfg)
			if fcfg then
				local body = { cfg = cfg }
				if fcfg.excludefrombuild then
					body.exclude = true
				end
				if p.fileconfig.hasCustomBuildRule(fcfg) then
					body.custom = fcfg
				end
				-- per-file compiler additions (defines, undefines,
				-- include dirs, buildoptions)
				local cpp = {}
				for _, def in ipairs(fcfg.defines) do
					table.insert(cpp, '/D "' .. def .. '"')
				end
				for _, undef in ipairs(fcfg.undefines) do
					table.insert(cpp, '/U "' .. undef .. '"')
				end
				for _, dir in ipairs(fcfg.includedirs) do
					table.insert(cpp, '/I "' .. vs6.path(p.project.getrelative(cfg.project, dir)) .. '"')
				end
				for _, opt in ipairs(fcfg.buildoptions) do
					table.insert(cpp, opt)
				end
				-- non-uniform pchheader: /Yc lands in the per-config chain
				if not pchuniform and cfg.enablepch ~= p.OFF and cfg.pchheader
						and cfg.pchsource == file.node.abspath then
					table.insert(cpp, 1, '/Yc"' .. cfg.pchheader .. '"')
				end
				if #cpp > 0 then
					body.cpp = cpp
				end
				if body.exclude or body.custom or body.cpp then
					table.insert(bodies, body)
				end
			end
		end

		if pchuniform and pchflag then
			p.outln('')
			p.outln('# ADD CPP /Yc"' .. pchflag .. '"')
		end

		if #bodies > 0 then
			-- VC6 idiom: per-file CPP flags that are uniform across all
			-- configurations are written without the !IF chain (excludes
			-- and custom builds are always chained)
			local uniform = #bodies == #configs
			local first = bodies[1].cpp
			if uniform and first then
				for _, body in ipairs(bodies) do
					if body.exclude or body.custom or not body.cpp
							or table.concat(body.cpp, "\1") ~= table.concat(first, "\1") then
						uniform = false
						break
					end
				end
			else
				uniform = false
			end
			if uniform then
				p.outln('')
				p.outln('# ADD CPP ' .. table.concat(first, " "))
			else
				p.outln('')
				for i, body in ipairs(bodies) do
					p.outln((i == 1 and '!IF' or '!ELSEIF') .. '  "$(CFG)" == "' .. prj.name .. ' - Win32 ' .. body.cfg.buildcfg .. '"')
					p.outln('')
					if body.exclude then
						p.outln('# PROP Exclude_From_Build 1')
					end
					if body.cpp then
						p.outln('# ADD CPP ' .. table.concat(body.cpp, " "))
					end
					if body.custom then
						dsp.customBuild(body.cfg, body.custom, file)
					end
					p.outln('')
				end
				-- VC6-authored files write the per-file !ENDIF with a
				-- trailing space
				p.outln('!ENDIF ')
				p.outln('')
			end
		end

		p.outln('# End Source File')
	end


---
-- The custom build block for one file in one configuration. Commands
-- and outputs are emitted verbatim (premake5 does not translate build
-- step macros either; scripts use VC6's $(IntDir)/$(InputPath) macros
-- directly). The IntDir=/OutDir= header follows where the first output
-- points, matching VC6's own convention.
---

	function dsp.customBuild(cfg, fcfg, file)
		p.outln('# Begin Custom Build')

		local firstout = fcfg.buildoutputs[1] or ""
		if firstout:find("%$%(OUTDIR%)") then
			p.outln('OutDir=' .. vs6.path(vs6.outdir(cfg)))
		else
			p.outln('IntDir=' .. vs6.path(vs6.objdir(cfg)))
		end
		p.outln('InputPath=' .. vs6.path(file.source))
		p.outln('InputName=' .. path.getbasename(file.source))
		p.outln('')

		local outputs = table.translate(fcfg.buildoutputs, function(o)
			return '"' .. vs6.path(o) .. '"'
		end)
		p.outln(table.concat(outputs, " ") .. ' : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"')
		for _, cmd in ipairs(fcfg.buildcommands) do
			p.outln('\t' .. cmd)
		end
		p.outln('')

		p.outln('# End Custom Build')
	end
