--
-- experiments/libpng/premake5.lua
-- Reproduce libpng.dsw + libpng/pngtest .dsp files
-- (real-world-test-cases/libpng) with the vs6 module. The script sits at
-- the projects/visualc6 position of a libpng source tree with a sibling
-- zlib tree (the real libpng.dsw references ../../../zlib). Pair with
-- tools/dspdiff.py via run.py.
--
-- Notable shapes: per-config kind and target names (libpng13/libpng13d/
-- libpng/libpngd/libpng13vb), explicit library paths per configuration,
-- dependson for build order, postbuild events (tab-separated commands),
-- per-config defines with values (PNG_DEBUG=1). The "DLL VB" config is
-- appended to the shared workspace set and lands first in libpng's block
-- order (real file has it in the middle) — a premake5 limitation
-- (project-level configurations append; nothing can be removed).
--

require "vs6"

-- shared by libpng and pngtest (the zlib project keeps its own shape);
-- reversed declaration order, DLL Release first in block order
local LPCONFIGS = {
	"LIB ASM Debug", "LIB ASM Release", "LIB Debug", "LIB Release",
	"DLL ASM Debug", "DLL ASM Release", "DLL Debug", "DLL Release",
}

workspace "libpng"
	configurations (LPCONFIGS)

local function lpcommon()
	characterset "ASCII"
	rtti "Off"
	exceptionhandling "Off"
	defines { "WIN32" }
	includedirs { "../..", "../../../zlib" }
	resincludedirs { "../.." }
end

local function lpshapes()
	filter "configurations:*Release"
		defines { "NDEBUG" }
		optimize "Speed"
	filter "configurations:*Debug"
		defines { "_DEBUG" }
		symbols "On"
		minimalrebuild "On"
		optimize "Off"
	filter {}
	for _, c in ipairs(LPCONFIGS) do
		local dir = "Win32_" .. c:gsub(" ", "_")
		filter { "configurations:" .. c }
			targetdir(dir)
			objdir("!" .. dir)
	end
	filter {}
end

-- libpng's per-config target names
local function lpnames()
	filter "configurations:DLL*Debug"
		targetname "libpng13d"
	filter "configurations:DLL*Release"
		targetname "libpng13"
	filter "configurations:LIB*Debug"
		targetname "libpngd"
	-- LIB*Release: default (libpng)
	filter {}
end

-- zlib's own output dirs per configuration (for link paths)
local function zlibdir(c)
	return "../../../zlib/projects/visualc6/Win32_" .. c:gsub(" ", "_")
end


project "libpng"
	language "C"
	location "."
	configurations { "DLL VB" }
	kind "SharedLib"
	lpcommon()
	lpshapes()
	lpnames()
	dependson { "zlib" }

	filter "configurations:DLL*"
		kind "SharedLib"
		defines { "PNG_BUILD_DLL", "ZLIB_DLL", "_CRT_SECURE_NO_WARNINGS" }
	filter "configurations:LIB*"
		kind "StaticLib"
		defines { "_CRT_SECURE_NO_WARNINGS" }
	filter "configurations:*Debug"
		defines { "DEBUG", "PNG_DEBUG=1" }
		resdefines { "PNG_DEBUG=1" }
	filter { "configurations:not *ASM*", "configurations:not *VB*" }
		defines { "PNG_NO_MMX_CODE" }
	filter "configurations:*ASM*"
		defines { "PNG_USE_PNGVCRD", "PNG_LIBPNG_SPECIALBUILD" }
	filter "configurations:DLL VB"
		kind "SharedLib"
		targetdir "Win32_DLL_VB"
		objdir "!Win32_DLL_VB"
		targetname "libpng13vb"
		defines { "PNG_BUILD_DLL", "ZLIB_DLL", "PNGAPI=__stdcall",
			"PNG_NO_MODULEDEF", "PNG_LIBPNG_SPECIALBUILD",
			"_CRT_SECURE_NO_WARNINGS" }
		optimize "Speed"
		defines { "NDEBUG" }
		postbuildcommands {
			[[echo    Deleting $(targetname) import library and export file (Not required for VB projects)]],
			[[del $(outdir)\$(targetname).lib]],
			[[del $(outdir)\$(targetname).exp]],
		}
	filter {}

	-- link against zlib's import library per config (DLL configs only;
	-- LIB configs have no link step)
	for _, c in ipairs({ "DLL Release", "DLL Debug", "DLL ASM Release",
			"DLL ASM Debug", "DLL VB" }) do
		local lib = c:match("Debug") and "zlib1d" or "zlib1"
		-- the VB config links the plain Release import library
		local zdir = (c == "DLL VB") and zlibdir("DLL Release") or zlibdir(c)
		filter { "configurations:" .. c }
			links { lib }
			libdirs { zdir }
	end
	filter {}

	vpaths {
		["Source Files"] = { "../../*.c", "../../scripts/pngw32.def" },
		["Header Files"] = { "../../*.h" },
		["Resource Files"] = { "../../scripts/pngw32.rc" },
	}

	files {
		"../../png.c", "../../pngerror.c", "../../pngget.c",
		"../../pngmem.c", "../../pngpread.c", "../../pngread.c",
		"../../pngrio.c", "../../pngrtran.c", "../../pngrutil.c",
		"../../pngset.c", "../../pngtrans.c", "../../pngwio.c",
		"../../pngwrite.c", "../../pngwtran.c", "../../pngwutil.c",
		"../../png.h", "../../pngconf.h",
		"../../scripts/pngw32.def", "../../scripts/pngw32.rc",
		"README.txt",
	}

	-- the module-definition file and resource only participate in DLL
	-- builds (and the VB config doesn't use the .def)
	filter { "configurations:LIB*", "files:**/pngw32.def" }
		excludefrombuild "On"
	filter { "configurations:DLL VB", "files:**/pngw32.def" }
		excludefrombuild "On"
	filter { "configurations:LIB*", "files:**/pngw32.rc" }
		excludefrombuild "On"
	filter {}


project "pngtest"
	kind "ConsoleApp"
	language "C"
	location "."
	characterset "ASCII"
	rtti "Off"
	exceptionhandling "Off"
	defines { "WIN32" }
	includedirs { "../../../zlib" }
	lpshapes()
	dependson { "libpng" }

	filter "configurations:DLL*"
		defines { "PNG_DLL", "PNG_NO_STDIO", "PNG_NO_GLOBAL_ARRAYS" }
	filter {}

	-- explicit per-config library paths (VC6-authored style)
	for _, c in ipairs(LPCONFIGS) do
		local debug = c:match("Debug") ~= nil
		local isdll = c:match("^DLL") ~= nil
		local dir = "Win32_" .. c:gsub(" ", "_")
		local lp = isdll and (debug and "libpng13d" or "libpng13")
			or (debug and "libpngd" or "libpng")
		local zl = isdll and (debug and "zlib1d" or "zlib1")
			or (debug and "zlibd" or "zlib")
		filter { "configurations:" .. c }
			links { dir .. "/" .. lp .. ".lib", zlibdir(c) .. "/" .. zl .. ".lib" }
	end
	filter {}

	-- postbuild test run; DLL configs extend the DLL search path first
	for _, c in ipairs(LPCONFIGS) do
		filter { "configurations:" .. c }
		if c:match("^DLL") then
			postbuildcommands {
				[[set path=$(outdir);]] .. zlibdir(c):gsub("/", "\\") .. ";",
				[[$(outdir)\pngtest.exe ..\..\pngtest.png]],
			}
		else
			postbuildcommands { [[$(outdir)\pngtest.exe ..\..\pngtest.png]] }
		end
	end
	filter {}

	vpaths { ["Source Files"] = { "../../pngtest.c" } }
	files { "../../pngtest.c" }


-- libpng.dsw references the zlib project from its sibling tree; the
-- module regenerates that .dsp into the shadow zlib tree (its own
-- experiment covers the contents)
project "zlib"
	language "C"
	location "../../../zlib/projects/visualc6"
	characterset "ASCII"
	rtti "Off"
	exceptionhandling "Off"
	defines { "WIN32" }

	filter "configurations:DLL*"
		kind "SharedLib"
	filter "configurations:LIB*"
		kind "StaticLib"
	filter "configurations:*Release"
		defines { "NDEBUG" }
		optimize "Speed"
	filter "configurations:*Debug"
		defines { "_DEBUG" }
		symbols "On"
		minimalrebuild "On"
		optimize "Off"
	filter "configurations:*ASM*"
		defines { "ASMINF", "ASMV" }
	filter {}
	for _, c in ipairs(LPCONFIGS) do
		local dir = "Win32_" .. c:gsub(" ", "_")
		filter { "configurations:" .. c }
			targetdir(dir)
			objdir("!" .. dir)
	end
	filter "configurations:DLL*Release"
		targetname "zlib1"
	filter "configurations:DLL*Debug"
		targetname "zlib1d"
	filter "configurations:LIB*Debug"
		targetname "zlibd"
	filter {}

	files {
		"../../../zlib/adler32.c", "../../../zlib/compress.c",
		"../../../zlib/crc32.c", "../../../zlib/deflate.c",
		"../../../zlib/gzio.c", "../../../zlib/infback.c",
		"../../../zlib/inffast.c", "../../../zlib/inflate.c",
		"../../../zlib/inftrees.c", "../../../zlib/trees.c",
		"../../../zlib/uncompr.c", "../../../zlib/win32/zlib.def",
		"../../../zlib/zutil.c",
		"../../../zlib/crc32.h", "../../../zlib/deflate.h",
		"../../../zlib/inffast.h", "../../../zlib/inffixed.h",
		"../../../zlib/inflate.h", "../../../zlib/inftrees.h",
		"../../../zlib/trees.h", "../../../zlib/zconf.h",
		"../../../zlib/zlib.h", "../../../zlib/zutil.h",
		"../../../zlib/win32/zlib1.rc",
		"../../../zlib/contrib/masmx86/gvmat32.asm",
		"../../../zlib/contrib/masmx86/gvmat32c.c",
		"../../../zlib/contrib/masmx86/inffas32.asm",
	}
