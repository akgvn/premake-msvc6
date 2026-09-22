--
-- _preload.lua
-- Define the "vs6" action: Visual C++ 6.0 workspace (.dsw) and project
-- (.dsp) file generation.
--
-- This file is only auto-executed for embedded modules; when used as an
-- external module, vs6.lua includes it explicitly (idempotent).
--
-- Copyright (c) 2026 the premake5-vs6 project contributors
-- Based on premake 3.x (vs6.c, vs6_cpp.c) by Jason Perkins
-- SPDX-License-Identifier: GPL-2.0-or-later
--

	local p = premake

	newaction {
		-- Metadata for the command line and help system

		trigger         = "vs6",
		shortname       = "Visual Studio 6",
		description     = "Generate Visual C++ 6.0 project files",

		-- VS6 is Win32-only, and always uses the MSVC toolset

		targetos        = "windows",
		toolset         = "msc",

		-- The capabilities of this action

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		valid_languages = { "C", "C++" },
		valid_tools     = {
			cc = { "msc" },
		},

		-- Workspace and project generation logic

		onInitialize = function()
			require("vs6")
		end,

		onWorkspace = function(wks)
			p.indent("")
			p.eol("\r\n")
			p.generate(wks, ".dsw", p.modules.vs6.generateWorkspace)
		end,

		onProject = function(prj)
			p.indent("")
			p.eol("\r\n")
			p.generate(prj, ".dsp", p.modules.vs6.generateProject)
		end,
	}


	-- As an external module the action is registered during runUserScript,
	-- after prepareAction already ran; re-apply it so targetos/targetarch
	-- take effect before baking.
	if _ACTION == "vs6" then
		p.action.set("vs6")
	end


--
-- Decide when the full module should be loaded (embedded use).
--

	return function(cfg)
		return (_ACTION == "vs6")
	end