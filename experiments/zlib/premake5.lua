--
-- experiments/zlib/premake5.lua
-- Reproduce zlib.dsw + zlib/example/minigzip .dsp files
-- (real-world-test-cases/zlib) with the vs6 module. The script sits at
-- the projects/visualc6 position in the shadow tree, like the real
-- files. Pair with tools/dspdiff.py via run.py.
--
-- Notable shapes: per-config kind (DLL and LIB configurations in one
-- project), per-config target names (zlib1/zlib1d/zlib/zlibd), project
-- dependencies, per-config excludefrombuild, hand-maintained layout
-- quirks. The .asm custom build rules and per-file /I are NOT
-- reproduced (known gaps, see NOTES.md).
--

require "vs6"

-- the three projects share the same 8 configurations (block order is
-- reversed declaration order, so DLL Release comes out first)
local ZCONFIGS = {
	"LIB ASM Debug", "LIB ASM Release", "LIB Debug", "LIB Release",
	"DLL ASM Debug", "DLL ASM Release", "DLL Debug", "DLL Release",
}

workspace "zlib"
	configurations (ZCONFIGS)

local function zcommon()
	characterset "ASCII"
	rtti "Off"
	exceptionhandling "Off"
	defines { "WIN32" }
end

-- per-config shapes shared by all three projects (the DLL/LIB config
-- names describe which zlib variant they link, not their own kind)
local function zshapes()
	filter "configurations:*Release"
		defines { "NDEBUG" }
		optimize "Speed"
	filter "configurations:*Debug"
		defines { "_DEBUG" }
		symbols "On"
		minimalrebuild "On"
		optimize "Off"
	filter {}
	-- all three projects share output dirs; "!" keeps premake5 from
	-- uniquifying the objdir per project
	for _, c in ipairs(ZCONFIGS) do
		local dir = "Win32_" .. c:gsub(" ", "_")
		filter { "configurations:" .. c }
			targetdir(dir)
			objdir("!" .. dir)
	end
	filter {}
end


project "example"
	kind "ConsoleApp"
	language "C"
	location "."
	zcommon()
	zshapes()
	links { "zlib" }

	vpaths {
		["Source Files"] = { "../../example.c" },
		["Header Files"] = { "../../*.h" },
	}

	files { "../../example.c", "../../zconf.h", "../../zlib.h" }


project "minigzip"
	kind "ConsoleApp"
	language "C"
	location "."
	zcommon()
	zshapes()
	links { "zlib" }

	vpaths {
		["Source Files"] = { "../../minigzip.c" },
		["Header Files"] = { "../../*.h" },
	}

	files { "../../minigzip.c", "../../zconf.h", "../../zlib.h" }
project "zlib"
	language "C"
	location "."
	zcommon()
	zshapes()

	filter "configurations:DLL*"
		kind "SharedLib"
	filter "configurations:LIB*"
		kind "StaticLib"
	filter "configurations:*ASM*"
		defines { "ASMINF", "ASMV" }
	filter {}

	-- per-config target names
	filter "configurations:DLL*Release"
		targetname "zlib1"
	filter "configurations:DLL*Debug"
		targetname "zlib1d"
	filter "configurations:LIB*Debug"
		targetname "zlibd"
	filter {}

	vpaths {
		["Source Files"] = { "../../*.c", "../../win32/zlib.def" },
		["Header Files"] = { "../../*.h" },
		["Resource Files"] = { "../../win32/zlib1.rc" },
		["Assembler Files (Unsupported)"] = { "../../contrib/masmx86/*" },
	}

	files {
		"../../adler32.c", "../../compress.c", "../../crc32.c",
		"../../deflate.c", "../../gzio.c", "../../infback.c",
		"../../inffast.c", "../../inflate.c", "../../inftrees.c",
		"../../trees.c", "../../uncompr.c", "../../win32/zlib.def",
		"../../zutil.c",
		"../../crc32.h", "../../deflate.h", "../../inffast.h",
		"../../inffixed.h", "../../inflate.h", "../../inftrees.h",
		"../../trees.h", "../../zconf.h", "../../zlib.h", "../../zutil.h",
		"../../win32/zlib1.rc",
		"../../contrib/masmx86/gvmat32.asm",
		"../../contrib/masmx86/gvmat32c.c",
		"../../contrib/masmx86/inffas32.asm",
		"README.txt",
	}

	-- zlib.def only participates in DLL builds; the assembler files only
	-- in ASM builds (with ml.exe custom build steps there)
	filter { "configurations:LIB*", "files:**/zlib.def" }
		excludefrombuild "On"
	filter { "configurations:not *ASM*", "files:**.asm" }
		excludefrombuild "On"
	filter { "configurations:*ASM*Release", "files:**.asm" }
		buildcommands { 'ml.exe /nologo /c /coff /Cx /Fo"$(IntDir)\\$(InputName).obj" "$(InputPath)"' }
		buildoutputs { "$(IntDir)\\$(InputName).obj" }
	filter { "configurations:*ASM*Debug", "files:**.asm" }
		buildcommands { 'ml.exe /nologo /c /coff /Cx /Zi /Fo"$(IntDir)\\$(InputName).obj" "$(InputPath)"' }
		buildoutputs { "$(IntDir)\\$(InputName).obj" }

	-- gvmat32c.c builds from the source root in ASM configs only
	filter { "configurations:not *ASM*", "files:**/gvmat32c.c" }
		excludefrombuild "On"
	filter { "files:**/gvmat32c.c" }
		includedirs { "../.." }
	filter {}


