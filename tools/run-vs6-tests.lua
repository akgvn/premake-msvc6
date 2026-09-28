--
-- tools/run-vs6-tests.lua
-- Register a `test` action backed by the self-test module that ships
-- inside premake5 release binaries, and point test discovery at the
-- repository root so tests/_tests.lua (and with it this module) is
-- found. Used by tools/test.py.
--
-- Copyright (c) 2026 the premake-msvc6 project contributors
-- SPDX-License-Identifier: GPL-2.0-or-later
--

	local p = premake

	-- This script lives in tools/, but discovery globs
	-- _MAIN_SCRIPT_DIR/**/tests/_tests.lua, so point it at the repo root.
	_MAIN_SCRIPT_DIR = path.getabsolute(path.join(_SCRIPT_DIR, ".."))

	-- Registers the self-test action and the --test-only option; the
	-- suites use the module table through the global `test`.
	test = require("self-test")

	newaction {
		trigger     = "test",
		description = "Run the unit test suites",
		execute     = function()
			p.action.call("self-test")
		end,
	}
