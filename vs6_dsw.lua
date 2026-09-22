--
-- vs6_dsw.lua
-- Visual C++ 6.0 workspace (.dsw) file writer.
-- Port of premake 3.7 Src/vs6.c.
--
-- Copyright (c) 2026 the premake5-vs6 project contributors
-- Based on premake 3.x (vs6.c) by Jason Perkins
-- SPDX-License-Identifier: GPL-2.0-or-later
--

	local p = premake
	local vs6 = p.modules.vs6
	local dsw = {}
	vs6.dsw = dsw


---
-- Entry point, called by the action (see _preload.lua).
---

	function vs6.generateWorkspace(wks)
		p.outln('Microsoft Developer Studio Workspace File, Format Version 6.00')
		p.outln('# WARNING: DO NOT EDIT OR DELETE THIS WORKSPACE FILE!')
		p.outln('')
		p.outln('###############################################################################')
		p.outln('')

		-- 3.x lists the projects in script order (not sorted)
		for _, prj in ipairs(wks.projects) do
			dsw.projectEntry(wks, prj)
		end

		p.outln('Global:')
		p.outln('')
		p.outln('Package=<5>')
		p.outln('{{{')
		p.outln('}}}')
		p.outln('')
		p.outln('Package=<3>')
		p.outln('{{{')
		p.outln('}}}')
		p.outln('')
		p.outln('###############################################################################')
		p.outln('')

		-- p.generate() captures via buffered.tostring(), which trims one
		-- trailing EOL; emit one extra so the file ends with a newline
		p.outln("")
	end


---
-- One project entry: the Project: line and its Package blocks, including
-- dependencies on sibling projects. Like 3.x, only the first
-- configuration's links are considered (OQ-6), and links naming another
-- project of the workspace become VC6 project dependencies.
---

	function dsw.projectEntry(wks, prj)
		local rel = path.getrelative(wks.location, prj.location)
		p.outln('Project: "' .. prj.name .. '"=' .. vs6.path(rel) .. '\\' .. prj.name .. '.dsp - Package Owner=<4>')
		p.outln('')
		p.outln('Package=<5>')
		p.outln('{{{')
		p.outln('}}}')
		p.outln('')
		p.outln('Package=<4>')
		p.outln('{{{')

		local configs = vs6.configs(prj)
		local cfg0 = configs[1]
		if cfg0 then
			for _, link in ipairs(cfg0.links) do
				local name = link:gsub(":static$", ""):gsub(":shared$", "")
				local dep = p.workspace.findproject(wks, name)
				if dep then
					p.outln('    Begin Project Dependency')
					p.outln('    Project_Dep_Name ' .. dep.name)
					p.outln('    End Project Dependency')
				end
			end
		end

		p.outln('}}}')
		p.outln('')
		p.outln('###############################################################################')
		p.outln('')
	end
