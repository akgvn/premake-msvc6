--
-- vs6_dsp.lua
-- Visual C++ 6.0 project (.dsp) file writer.
-- Port of premake 3.7 Src/vs6_cpp.c.
--
-- Copyright (c) 2026 the premake5-vs6 project contributors
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
		-- configuration names, so fail fast instead (OQ-5)
		for _, cfg in ipairs(configs) do
			local platform = cfg.platform
			if platform and platform ~= "x86" and platform ~= "Win32" then
				error("vs6: platform '" .. platform .. "' is not supported by Visual C++ 6.0 (project '" .. prj.name .. "')", 0)
			end
		end

		-- features with no VC6 equivalent are ignored with a warning (OQ-13, OQ-16)
		for _, cfg in ipairs(configs) do
			if #cfg.prebuildcommands > 0 then
				p.warnOnce("vs6.prebuildcommands:" .. prj.name,
					"vs6: prebuildcommands are not supported by Visual C++ 6.0 and will be ignored (project '%s')",
					prj.name)
			end
			if cfg.dependson and #cfg.dependson > 0 then
				p.warnOnce("vs6.dependson:" .. prj.name,
					"vs6: dependson is not supported by Visual C++ 6.0 and will be ignored (project '%s')",
					prj.name)
			end
		end

		dsp.header(prj, configs)

		-- 3.x stores configurations in reverse order
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
-- and the CFG= default, like 3.x.
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
		if not vs6.islib(cfg0) then
			p.outln('MTL=midl.exe')
		end
		p.outln('RSC=rc.exe')
		p.outln('')
	end


---
-- One per-configuration !IF/!ELSEIF block. Configs are emitted in reverse
-- order; the first emitted block (the last configuration) gets !IF.
--
-- 3.7 quirk: the Use_Debug_Libraries state of a block is computed from the
-- configuration selected *before* the block's own, i.e. rotated by one
-- (vs6_cpp.c reads the optimize flags before prj_select_config()). The
-- released 3.7 binary exhibits this in its output, so it is reproduced here.
---

	function dsp.configBlock(prj, configs, i)
		local cfg = configs[i]
		local dbglibs = vs6.useDebugLibs(vs6.rotatedConfig(configs, i)) and "1" or "0"

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
			p.outln('LINK32=link.exe -lib')
			p.outln('# ADD BASE LIB32 /nologo')
			p.outln('# ADD LIB32 /nologo /out:"' .. vs6.path(vs6.target(cfg)) .. '"')
		else
			p.outln('LINK32=link.exe')
			p.outln('# ADD BASE LINK32' .. dsp.linkFlags(cfg))
			p.outln('# ADD LINK32' .. dsp.linkFlags(cfg))
		end

		if #cfg.prelinkcommands > 0 or #cfg.postbuildcommands > 0 then
			p.outln('# Begin Special Build Tool')
			if #cfg.prelinkcommands > 0 then
				p.outln('PreLink_Cmds=' .. table.concat(cfg.prelinkcommands, "\t"))
			end
			if #cfg.postbuildcommands > 0 then
				p.outln('PostBuild_Cmds=' .. table.concat(cfg.postbuildcommands, "\t"))
			end
			p.outln('# End Special Build Tool')
		end

		p.outln('')
	end


---
-- Compiler flags for one configuration; port of 3.x writeCppFlags().
-- Returns the flag text following "/nologo" (leading space included).
---

	function dsp.cppFlags(cfg)
		local r = {}
		local debugLibs = vs6.useDebugLibs(cfg)

		if debugLibs then
			table.insert(r, vs6.staticRuntime(cfg) and "/MTd" or "/MDd")
		else
			table.insert(r, vs6.staticRuntime(cfg) and "/MT" or "/MD")
		end

		table.insert(r, "/W" .. vs6.warnLevel(cfg))

		if vs6.fatalWarnings(cfg) then
			table.insert(r, "/WX")
		end

		if debugLibs then
			table.insert(r, "/Gm")  -- minimal rebuild
		end

		if vs6.rtti(cfg) then
			table.insert(r, "/GR")
		end

		if vs6.exceptions(cfg) then
			table.insert(r, "/GX")
		end

		if vs6.symbols(cfg) then
			table.insert(r, "/ZI")  -- debug symbols for edit-and-continue
		end

		if vs6.optimizeSize(cfg) then
			table.insert(r, "/O1")
		elseif vs6.optimizeSpeed(cfg) then
			table.insert(r, "/O2")
		else
			table.insert(r, "/Od")
		end

		if vs6.omitFramePointer(cfg) then
			table.insert(r, "/Oy")
		end

		for _, dir in ipairs(cfg.includedirs) do
			table.insert(r, '/I "' .. vs6.path(p.project.getrelative(cfg.project, dir)) .. '"')
		end

		for _, def in ipairs(cfg.defines) do
			table.insert(r, '/D "' .. def .. '"')
		end

		table.insert(r, "/YX")
		table.insert(r, "/FD")

		if debugLibs then
			table.insert(r, "/GZ")
		end

		table.insert(r, "/c")

		for _, opt in ipairs(cfg.buildoptions) do
			table.insert(r, opt)
		end

		return " " .. table.concat(r, " ")
	end


---
-- Resource compiler flags for one configuration. 3.x merges the regular
-- defines/includepaths with the resource-specific ones.
---

	function dsp.rscFlags(cfg)
		local r = { '/l 0x409 /d "' .. (vs6.symbols(cfg) and "_DEBUG" or "NDEBUG") .. '"' }

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
-- Linker flags for one configuration; port of 3.x writeLinkFlags().
-- Returns the flag text following "# ADD BASE LINK32" (leading space
-- included). Only used for non-static-library kinds.
---

	function dsp.linkFlags(cfg)
		local r = {}
		local wks = cfg.workspace

		-- sibling projects are linked implicitly by VC6; only external
		-- libraries are listed, decorated with the .lib extension
		for _, link in ipairs(cfg.links) do
			local name = link:gsub(":static$", ""):gsub(":shared$", "")
			if not p.workspace.findproject(wks, name) then
				table.insert(r, name .. ".lib")
			end
		end

		table.insert(r, "/nologo")

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
			table.insert(r, "/incremental:yes")
			table.insert(r, "/debug")
		end

		table.insert(r, "/machine:I386")

		if vs6.isdll(cfg) then
			table.insert(r, '/implib:"' .. vs6.path(vs6.implib(cfg)) .. '"')
		end

		table.insert(r, '/out:"' .. vs6.path(vs6.target(cfg)) .. '"')

		if vs6.symbols(cfg) then
			table.insert(r, "/pdbtype:sept")
		end

		table.insert(r, '/libpath:"' .. vs6.path(vs6.libdir(cfg)) .. '"')

		for _, dir in ipairs(cfg.libdirs) do
			table.insert(r, '/libpath:"' .. vs6.path(p.project.getrelative(cfg.project, dir)) .. '"')
		end

		for _, opt in ipairs(cfg.linkoptions) do
			table.insert(r, opt)
		end

		return " " .. table.concat(r, " ")
	end


---
-- The source file tree; port of 3.x print_source_tree() + the vs6_cpp.c
-- listFiles() callback. Groups are emitted in order of first appearance,
-- before the files of their parent directory; group roots named ".." are
-- skipped.
---

	function dsp.sourceTree(prj)
		-- prj._.files is sorted alphabetically by virtual path; fcfg.order
		-- holds the script declaration index (3.x order)
		local files = {}
		local ordered = table.shallowcopy(prj._.files)
		table.sort(ordered, function(a, b)
			return (a.order or math.huge) < (b.order or math.huge)
		end)
		for _, fcfg in ipairs(ordered) do
			table.insert(files, fcfg.relpath)
		end
		dsp._sourceTree(files, "")
	end

	function dsp._sourceTree(files, dir)
		dsp._treeNode(dir:gsub("/$", ""), "open")

		-- recurse into subdirectories, in order of first appearance
		for i, f in ipairs(files) do
			if #f > #dir and f:sub(1, #dir) == dir then
				local s = f:find("/", #dir + 1, true)
				if s then
					local sub = f:sub(1, s)
					local first
					for j, g in ipairs(files) do
						if g:sub(1, #sub) == sub then
							first = j
							break
						end
					end
					if first == i then
						dsp._sourceTree(files, sub)
					end
				end
			end
		end

		-- then emit the files that live directly in this directory
		for _, f in ipairs(files) do
			local lastslash = f:match("^.*()/")
			if f:sub(1, #dir) == dir and (not lastslash or lastslash <= #dir) then
				dsp._treeNode(f, "file")
			end
		end

		dsp._treeNode(dir:gsub("/$", ""), "close")
	end

	function dsp._treeNode(name, stage)
		-- 3.x uses the last path component as the group name, and skips
		-- groups named ".." (and the anonymous root)
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
		else
			p.outln('# Begin Source File')
			p.outln('')
			p.outln('SOURCE=' .. vs6.path(name))
			p.outln('# End Source File')
		end
	end
