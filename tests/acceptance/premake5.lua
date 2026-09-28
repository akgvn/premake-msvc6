--
-- tests/acceptance/premake5.lua
-- Generates one VC6 project per acceptance profile into a single
-- workspace. Run via `uv run tests/acceptance/generate.py`; the generated
-- vc6_acceptance.dsw + .dsp files are then built on Windows by run.bat
-- with the real VC6 toolchain (see README.md).
--
-- Every switch the module can emit appears in at least one profile; the
-- profiles deliberately mirror the dimensions in
-- tests/test_vs6_coverage.lua and docs/coverage-matrix.md.
--

require "vs6"

workspace "vc6_acceptance"
	configurations { "Debug", "Release" }
	location "."

local DEFAULT_FILES = { "sources/main.c", "sources/app.rc" }

local profiles = {
	-- compiler flags -----------------------------------------------------
	{ name = "cpp_default" },
	{ name = "cpp_debug",         opts = function() runtime "Debug" end },
	{ name = "cpp_static",        opts = function() staticruntime "On" end },
	{ name = "cpp_static_debug",  opts = function() staticruntime "On"; runtime "Debug" end },
	{ name = "cpp_warn_off",      opts = function() warnings "Off" end },
	{ name = "cpp_warn_extra",    opts = function() warnings "Extra" end },
	{ name = "cpp_warn_fatal",    opts = function() warnings "Extra"; fatalwarnings { "All" } end },
	{ name = "cpp_minrebuild",    opts = function() minimalrebuild "On" end },
	{ name = "cpp_nortti",        opts = function() rtti "Off" end },
	{ name = "cpp_noexcept",      opts = function() exceptionhandling "Off" end },
	{ name = "cpp_zi",            opts = function() symbols "On" end },
	{ name = "cpp_zi_opt",        opts = function() symbols "On"; optimize "Speed" end },
	{ name = "cpp_z7",            opts = function() symbols "On"; debugformat "c7" end },
	{ name = "cpp_zi_ecoff",      opts = function() symbols "On"; editandcontinue "Off" end },
	{ name = "cpp_od",            opts = function() optimize "Off" end },
	{ name = "cpp_ot",            opts = function() optimize "On" end },
	{ name = "cpp_o1",            opts = function() optimize "Size" end },
	{ name = "cpp_o2",            opts = function() optimize "Speed" end },
	{ name = "cpp_ox",            opts = function() optimize "Full" end },
	{ name = "cpp_omitfp",        opts = function() omitframepointer "On" end },
	{ name = "cpp_mbcs",          opts = function() characterset "MBCS" end },
	{ name = "cpp_ascii",         opts = function() characterset "ASCII" end },
	{ name = "cpp_defines",       opts = function() defines { "ACCEPT_DEFINE" }; undefines { "ACCEPT_UNDEF" } end },
	{ name = "cpp_includes",      opts = function()
		includedirs { "include" }
		externalincludedirs { "include" }
		includedirsafter { "include" }
	end },
	{ name = "cpp_forceinclude",  opts = function() forceincludes { "accept.h" } end },
	{ name = "cpp_buildoptions",  opts = function()
		-- the escape-hatch-only single-flag enums
		buildoptions { "/Gd", "/Zp8", "/GF", "/Oi", "/Gy", "/J", "/Ob1" }
	end },
	{ name = "cpp_pch",
		files = { "sources/stdafx.c", "sources/pchmain.c", "sources/app.rc" },
		opts = function() pchheader "accept.h"; pchsource "sources/stdafx.c" end },

	-- linker flags -------------------------------------------------------
	{ name = "link_console" },
	{ name = "link_windowed",     kind = "WindowedApp", files = { "sources/winmain.c", "sources/app.rc" } },
	{ name = "link_dll",          kind = "SharedLib", files = { "sources/lib.c", "sources/app.rc" },
		opts = function() symbols "On" end },
	{ name = "link_dll_noimplib", kind = "SharedLib", files = { "sources/lib.c", "sources/app.rc" },
		opts = function() useimportlib "Off" end },
	{ name = "link_symbols",      opts = function() symbols "On" end },
	{ name = "link_symbols_pdb",  opts = function() symbols "On"; symbolspath "bin/accept.pdb" end },
	{ name = "link_incr_yes",     opts = function() incrementallink "On" end },
	{ name = "link_incr_no",      opts = function() incrementallink "Off" end },
	{ name = "link_entry",        opts = function() entrypoint "main" end },
	{ name = "link_map",          opts = function() mapfile "On" end },
	{ name = "link_map_path",     opts = function() mapfile "On"; mapfilepath "bin/accept.map" end },
	{ name = "link_profile",      opts = function() profile "On" end },
	{ name = "link_libdirs",      opts = function() libdirs { "libs" }; syslibdirs { "include" } end },
	{ name = "link_links",        opts = function() links { "user32" } end },
	{ name = "link_nodefaultlib", opts = function() ignoredefaultlibraries { "oldnames" } end },
	{ name = "link_options",      opts = function() linkoptions { "/verbose" } end },
	{ name = "lib_static",        kind = "StaticLib", files = { "sources/lib.c" } },

	-- resource compiler flags -------------------------------------------
	{ name = "rsc_locale",        opts = function() locale "cs-CZ" end },
	{ name = "rsc_locale_de",     opts = function() locale "de-DE" end },
	{ name = "rsc_defines",       opts = function() resdefines { "RES_DEFINE" } end },
	{ name = "rsc_options",       opts = function() resoptions { "/c65001" } end },
	{ name = "rsc_symbols",       opts = function() symbols "On" end },
}

for _, prof in ipairs(profiles) do
	project(prof.name)
		language "C++"
		kind(prof.kind or "ConsoleApp")
		files(prof.files or DEFAULT_FILES)
		if prof.opts then
			prof.opts()
		end
end


--
-- The Windows harness reads this manifest: one line per project/config,
-- pipe-separated as name|config|relative-target.
--

local ext = {
	ConsoleApp = ".exe",
	WindowedApp = ".exe",
	SharedLib = ".dll",
	StaticLib = ".lib",
}

local manifest = io.open("manifest.txt", "w")
for _, prof in ipairs(profiles) do
	local k = prof.kind or "ConsoleApp"
	for _, cfg in ipairs({ "Debug", "Release" }) do
		manifest:write(string.format("%s|%s|bin\\%s\\%s%s\n", prof.name, cfg, cfg, prof.name, ext[k]))
	end
end
manifest:close()
