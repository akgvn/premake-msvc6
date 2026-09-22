-- Sample workspace for vs6 E2E regression testing.
-- Exercises: all 4 kinds, Debug/Release, sibling dependencies, defines,
-- includedirs, libdirs, links, resources, pre/post-build commands.
-- The module's output for this script is the baseline in tests/golden/.

require "vs6"

workspace "Sample"
	configurations { "Debug", "Release" }

project "core"
	kind "StaticLib"
	language "C++"
	files { "core/core.cpp", "core/core.h" }
	defines { "CORE_LIB" }
	filter "configurations:Release"
		optimize "Speed"
	filter {}

project "engine"
	kind "SharedLib"
	language "C++"
	files { "engine/engine.cpp", "engine/engine.rc" }
	links { "core" }
	defines { "ENGINE_EXPORTS" }
	includedirs { "engine/include" }
	resdefines { "ENGINE_RES" }
	resincludedirs { "engine/res" }
	resoptions { "/x" }
	prebuildcommands { "echo prebuild" }  -- folded into PreLink_Cmds
	prelinkcommands { "echo prelink" }
	postbuildcommands { "echo postbuild" }
	filter "configurations:Release"
		optimize "Speed"
	filter {}

project "app"
	kind "ConsoleApp"
	language "C++"
	files { "app/main.cpp" }
	links { "engine", "core" }
	includedirs { "engine/include" }
	libdirs { "libs" }
	postbuildcommands { "echo done" }
	filter "configurations:Release"
		optimize "Speed"
	filter {}

project "tool"
	kind "WindowedApp"
	language "C++"
	files { "tool/winmain.cpp" }
	links { "core" }
	filter "configurations:Release"
		optimize "Speed"
	filter {}
