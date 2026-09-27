--
-- experiments/quake2/premake5.lua
-- Reproduce the id Software Quake 2 v3.19 workspace (quake2.dsw + the five
-- .dsp projects in real-world-test-cases/quake2) with the vs6 module.
--
-- The script sits at the workspace root of the shadow tree, like the real
-- quake2.dsw; the four DLL projects live in their own subdirectories
-- (ctf/, game/, ref_gl/, ref_soft/) and reference shared sources with ..\
-- paths. File paths and output dirs are script-relative (premake5
-- convention), hence the "game\..." / "ref_gl\..." prefixes. Pair with
-- tools/dspdiff.py via run.sh.
--
-- Notable shapes: four configurations per project including two ALPHA
-- ones (/QA21164 /Gt0 /QAieee1 /D C_ONLY through buildoptions;
-- /machine:ALPHA is not reproducible -- the module pins /machine:I386, the
-- one documented residual), per-config static runtime /MT(d), per-config
-- mapfile + incrementallink, ref_soft's ml.exe per-file custom builds
-- (excluded from the ALPHA configs), ref_gl's opengl32 in Debug Alpha
-- only, ref_soft's /nodefaultlib:"libc", and /subsystem:windows on the DLL
-- link lines (the module omits it for SharedLib; VC-authored DLL projects
-- carry it).
--

require "vs6"

-- declaration order is reversed relative to the emitted block order, so
-- the first configuration block is "Release" (see vs6_dsp.configBlock)
local QCONFIGS = { "Release Alpha", "Debug Alpha", "Debug", "Release" }

workspace "quake2"
	configurations (QCONFIGS)

-- settings shared by every project: ASCII source, static runtime, /GX,
-- no /GR, and the release/debug split
local function common()
	characterset "ASCII"
	staticruntime "On"
	rtti "Off"
	exceptionhandling "On"
	defines { "WIN32", "_WINDOWS" }

	filter "configurations:Release"
		optimize "Speed"
		warnings "Extra"
		defines "NDEBUG"
	filter "configurations:Debug"
		optimize "Off"
		symbols "On"
		defines "_DEBUG"
	filter "configurations:Release Alpha"
		optimize "Speed"
		defines "NDEBUG"
	filter "configurations:Debug Alpha"
		optimize "Off"
		symbols "On"
		editandcontinue "Off"
		defines "_DEBUG"
	filter {}
end

-- per-configuration output dirs, extra compiler switches, links and the
-- rare per-config library flags. Keys are the configuration names; the
-- dirs are script-relative (premake5 semantics).
local function perconfig(spec)
	for name, s in pairs(spec) do
		filter { "configurations:" .. name }
			targetdir(s.targetdir)
			objdir(s.objdir)
			if s.defines then defines(s.defines) end
			if s.buildoptions then buildoptions(s.buildoptions) end
			if s.links then links(s.links) end
			if s.ignoredefaultlibraries then
				ignoredefaultlibraries(s.ignoredefaultlibraries)
			end
			if s.mapfile then mapfile "On" end
			if s.incrementallink then incrementallink(s.incrementallink) end
			if s.minimalrebuild then minimalrebuild "On" end
		filter {}
	end
end

-- file -> logical group by extension (all groups flat, like the originals)
local function filegroups()
	return {
		["Source Files"] = { "**.c", "**.asm" },
		["Header Files"] = { "**.h" },
		["Resource Files"] = { "**.def", "**.rc", "**.ico" },
	}
end

-- VC-authored DLL projects ask for /subsystem:windows explicitly; the
-- module leaves it to the /dll default (premake5-native), so the scripts
-- add it back through the linkoptions escape hatch
local function dllsubsystem()
	linkoptions { "/subsystem:windows" }
end


project "ctf"
	kind "SharedLib"
	language "C"
	location "ctf"
	common()
	dllsubsystem()
	-- ctf is the odd one out: no /G5, and its ALPHA configs carry only
	-- /Gt0 (no /QA21164 //QAieee1, no C_ONLY)
	perconfig {
		["Release"] = {
			targetdir = "ctf/release", objdir = "ctf/release",
			links = { "winmm" },
		},
		["Debug"] = {
			targetdir = "ctf/debug", objdir = "ctf/debug",
			buildoptions = { "/FR" },
			minimalrebuild = true, mapfile = true,
			incrementallink = "Off",
			links = { "winmm" },
		},
		["Debug Alpha"] = {
			targetdir = "DebugAXP", objdir = "ctf/DebugAXP",
			buildoptions = { "/Gt0", "/FR" },
			mapfile = true,
			links = { "winmm" },
		},
		["Release Alpha"] = {
			targetdir = "ReleaseAXP", objdir = "ctf/ReleaseAXP",
			buildoptions = { "/Gt0" },
			links = { "winmm" },
		},
	}
	targetname "gamex86"
	vpaths (filegroups())
	files {
		"ctf/g_ai.c", "ctf/g_chase.c", "ctf/g_cmds.c", "ctf/g_combat.c",
		"ctf/g_ctf.c", "ctf/g_func.c", "ctf/g_items.c", "ctf/g_main.c",
		"ctf/g_misc.c", "ctf/g_monster.c", "ctf/g_phys.c", "ctf/g_save.c",
		"ctf/g_spawn.c", "ctf/g_svcmds.c", "ctf/g_target.c",
		"ctf/g_trigger.c", "ctf/g_utils.c", "ctf/g_weapon.c",
		"ctf/m_move.c", "ctf/p_client.c", "ctf/p_hud.c", "ctf/p_menu.c",
		"ctf/p_trail.c", "ctf/p_view.c", "ctf/p_weapon.c",
		"ctf/q_shared.c",
		"ctf/g_ctf.h", "ctf/g_local.h", "ctf/game.h", "ctf/m_player.h",
		"ctf/p_menu.h", "ctf/q_shared.h",
		"ctf/ctf.def",
	}


project "game"
	kind "SharedLib"
	language "C"
	location "game"
	common()
	dllsubsystem()
	perconfig {
		["Release"] = {
			targetdir = "release", objdir = "game/release",
			buildoptions = { "/G5", "/Zd" },
			links = { "winmm" },
		},
		["Debug"] = {
			targetdir = "debug", objdir = "game/debug",
			buildoptions = { "/G5", "/FR" },
			defines = { "BUILDING_REF_GL" },
			minimalrebuild = true, mapfile = true,
			incrementallink = "Off",
			links = { "winmm" },
		},
		["Debug Alpha"] = {
			targetdir = "DebugAxp", objdir = "game/DebugAxp",
			buildoptions = { "/QA21164", "/Gt0" },
			defines = { "C_ONLY" },
		},
		["Release Alpha"] = {
			targetdir = "ReleaseAXP", objdir = "game/ReleaseAXP",
			buildoptions = { "/QA21164", "/Gt0" },
			defines = { "C_ONLY" },
		},
	}
	targetname "gamex86"
	linkoptions { '/base:"0x20000000"' }
	vpaths (filegroups())
	files {
		"game/g_ai.c", "game/g_chase.c", "game/g_cmds.c",
		"game/g_combat.c", "game/g_func.c", "game/g_items.c",
		"game/g_main.c", "game/g_misc.c", "game/g_monster.c",
		"game/g_phys.c", "game/g_save.c", "game/g_spawn.c",
		"game/g_svcmds.c", "game/g_target.c", "game/g_trigger.c",
		"game/g_turret.c", "game/g_utils.c", "game/g_weapon.c",
		"game/m_actor.c", "game/m_berserk.c", "game/m_boss2.c",
		"game/m_boss3.c", "game/m_boss31.c", "game/m_boss32.c",
		"game/m_brain.c", "game/m_chick.c", "game/m_flash.c",
		"game/m_flipper.c", "game/m_float.c", "game/m_flyer.c",
		"game/m_gladiator.c", "game/m_gunner.c", "game/m_hover.c",
		"game/m_infantry.c", "game/m_insane.c", "game/m_medic.c",
		"game/m_move.c", "game/m_mutant.c", "game/m_parasite.c",
		"game/m_soldier.c", "game/m_supertank.c", "game/m_tank.c",
		"game/p_client.c", "game/p_hud.c", "game/p_trail.c",
		"game/p_view.c", "game/p_weapon.c", "game/q_shared.c",
		"game/g_local.h", "game/game.h", "game/m_actor.h",
		"game/m_berserk.h", "game/m_boss2.h", "game/m_boss31.h",
		"game/m_boss32.h", "game/m_brain.h", "game/m_chick.h",
		"game/m_flipper.h", "game/m_float.h", "game/m_flyer.h",
		"game/m_gladiator.h", "game/m_gunner.h", "game/m_hover.h",
		"game/m_infantry.h", "game/m_insane.h", "game/m_medic.h",
		"game/m_mutant.h", "game/m_parasite.h", "game/m_player.h",
		"game/m_soldier.h", "game/m_supertank.h", "game/m_tank.h",
		"game/q_shared.h",
		"game/game.def",
	}


project "quake2"
	kind "WindowedApp"
	language "C"
	location "."
	common()
	perconfig {
		["Release"] = {
			targetdir = "release", objdir = "release",
			buildoptions = { "/G5", "/Zd" },
			links = { "winmm", "wsock32" },
		},
		["Debug"] = {
			targetdir = "debug", objdir = "debug",
			buildoptions = { "/G5", "/FR" },
			mapfile = true, incrementallink = "Off",
			links = { "winmm", "wsock32" },
		},
		["Debug Alpha"] = {
			targetdir = "DebugAxp", objdir = "DebugAxp",
			buildoptions = { "/QA21164", "/Gt0", "/QAieee1" },
			defines = { "C_ONLY" },
			links = { "winmm", "wsock32" },
		},
		["Release Alpha"] = {
			targetdir = "ReleaseAXP", objdir = "ReleaseAXP",
			buildoptions = { "/QA21164", "/Gt0", "/QAieee1" },
			defines = { "C_ONLY" },
			links = { "winmm", "wsock32" },
		},
	}
	vpaths (filegroups())
	files {
		"win32/cd_win.c", "client/cl_cin.c", "client/cl_ents.c",
		"client/cl_fx.c", "client/cl_input.c", "client/cl_inv.c",
		"client/cl_main.c", "client/cl_newfx.c", "client/cl_parse.c",
		"client/cl_pred.c", "client/cl_scrn.c", "client/cl_tent.c",
		"client/cl_view.c", "qcommon/cmd.c", "qcommon/cmodel.c",
		"qcommon/common.c", "win32/conproc.c", "client/console.c",
		"qcommon/crc.c", "qcommon/cvar.c", "qcommon/files.c",
		"win32/in_win.c", "client/keys.c", "game/m_flash.c",
		"qcommon/md4.c", "client/menu.c", "qcommon/net_chan.c",
		"win32/net_wins.c", "qcommon/pmove.c", "game/q_shared.c",
		"win32/q_shwin.c", "client/qmenu.c", "client/snd_dma.c",
		"client/snd_mem.c", "client/snd_mix.c", "win32/snd_win.c",
		"server/sv_ccmds.c", "server/sv_ents.c", "server/sv_game.c",
		"server/sv_init.c", "server/sv_main.c", "server/sv_send.c",
		"server/sv_user.c", "server/sv_world.c", "win32/sys_win.c",
		"win32/vid_dll.c", "win32/vid_menu.c", "client/x86.c",
		"client/anorms.h", "qcommon/bspfile.h", "client/cdaudio.h",
		"client/client.h", "win32/conproc.h", "client/console.h",
		"game/game.h", "client/input.h", "client/keys.h",
		"game/q_shared.h", "qcommon/qcommon.h", "qcommon/qfiles.h",
		"client/qmenu.h", "client/ref.h", "client/screen.h",
		"server/server.h", "client/snd_loc.h", "client/sound.h",
		"client/vid.h", "win32/winquake.h",
		"win32/q2.ico", "win32/q2.rc",
	}


project "ref_gl"
	kind "SharedLib"
	language "C"
	location "ref_gl"
	common()
	dllsubsystem()
	perconfig {
		["Release"] = {
			targetdir = "release", objdir = "ref_gl/release",
			buildoptions = { "/G5" },
			links = { "winmm" },
		},
		["Debug"] = {
			targetdir = "debug", objdir = "ref_gl/debug",
			buildoptions = { "/G5", "/FR" },
			minimalrebuild = true, mapfile = true,
			incrementallink = "Off",
			links = { "winmm" },
		},
		["Debug Alpha"] = {
			targetdir = "DebugAxp", objdir = "ref_gl/DebugAxp",
			buildoptions = { "/QA21164", "/Gt0", "/QAieee1" },
			defines = { "C_ONLY" },
			-- the original only links opengl32 here (hand drift)
			links = { "winmm", "opengl32" },
		},
		["Release Alpha"] = {
			targetdir = "ReleaseAXP", objdir = "ref_gl/ReleaseAXP",
			buildoptions = { "/QA21164", "/Gt0", "/QAieee1" },
			defines = { "C_ONLY" },
			links = { "winmm" },
		},
	}
	vpaths (filegroups())
	files {
		"ref_gl/gl_draw.c", "ref_gl/gl_image.c", "ref_gl/gl_light.c",
		"ref_gl/gl_mesh.c", "ref_gl/gl_model.c", "ref_gl/gl_rmain.c",
		"ref_gl/gl_rmisc.c", "ref_gl/gl_rsurf.c", "ref_gl/gl_warp.c",
		"win32/glw_imp.c", "game/q_shared.c", "win32/q_shwin.c",
		"win32/qgl_win.c",
		"ref_gl/anorms.h", "ref_gl/anormtab.h", "ref_gl/gl_local.h",
		"ref_gl/gl_model.h", "win32/glw_win.h", "game/q_shared.h",
		"qcommon/qcommon.h", "qcommon/qfiles.h", "ref_gl/qgl.h",
		"ref_gl/qmenu.h", "client/ref.h", "ref_gl/ref_gl.h",
		"ref_gl/warpsin.h", "win32/winquake.h",
		"ref_gl/ref_gl.def",
	}


project "ref_soft"
	kind "SharedLib"
	language "C"
	location "ref_soft"
	common()
	dllsubsystem()
	perconfig {
		["Release"] = {
			targetdir = "release", objdir = "ref_soft/release",
			buildoptions = { "/G5" },
			links = { "winmm" },
		},
		["Debug"] = {
			targetdir = "debug", objdir = "ref_soft/debug",
			buildoptions = { "/G5", "/FR" },
			minimalrebuild = true, mapfile = true,
			incrementallink = "Off",
			links = { "winmm" },
			ignoredefaultlibraries = { "libc" },
		},
		["Debug Alpha"] = {
			targetdir = "DebugAxp", objdir = "ref_soft/DebugAxp",
			buildoptions = { "/QA21164", "/Gt0", "/QAieee1" },
			defines = { "C_ONLY" },
			links = { "winmm" },
			ignoredefaultlibraries = { "libc" },
		},
		["Release Alpha"] = {
			targetdir = "ReleaseAXP", objdir = "ref_soft/ReleaseAXP",
			buildoptions = { "/QA21164", "/Gt0", "/QAieee1" },
			defines = { "C_ONLY" },
			links = { "winmm" },
		},
	}
	vpaths (filegroups())
	files {
		"game/q_shared.c", "win32/q_shwin.c", "ref_soft/r_aclip.c",
		"ref_soft/r_aclipa.asm", "ref_soft/r_alias.c", "ref_soft/r_bsp.c",
		"ref_soft/r_draw.c", "ref_soft/r_draw16.asm",
		"ref_soft/r_drawa.asm", "ref_soft/r_edge.c",
		"ref_soft/r_edgea.asm", "ref_soft/r_image.c",
		"ref_soft/r_light.c", "ref_soft/r_main.c", "ref_soft/r_misc.c",
		"ref_soft/r_model.c", "ref_soft/r_part.c", "ref_soft/r_poly.c",
		"ref_soft/r_polysa.asm", "ref_soft/r_polyse.c",
		"ref_soft/r_rast.c", "ref_soft/r_scan.c",
		"ref_soft/r_scana.asm", "ref_soft/r_spr8.asm",
		"ref_soft/r_sprite.c", "ref_soft/r_surf.c",
		"ref_soft/r_surf8.asm", "ref_soft/r_varsa.asm",
		"win32/rw_ddraw.c", "win32/rw_dib.c", "win32/rw_imp.c",
		"ref_soft/adivtab.h", "ref_soft/anorms.h", "game/q_shared.h",
		"qcommon/qcommon.h", "qcommon/qfiles.h", "ref_soft/r_local.h",
		"ref_soft/r_model.h", "ref_soft/rand1k.h", "client/ref.h",
		"win32/rw_win.h", "win32/winquake.h",
		"ref_soft/ref_soft.def",
	}

	-- the .asm files are assembled by ml.exe in the two x86 configurations
	-- and excluded from the ALPHA ones (the real file's per-file blocks are
	-- identical in Release and Debug, both carrying /Zi)
	filter { "configurations:not *Alpha", "files:**.asm" }
		buildcommands { [[ml /c /Cp /coff /Fo$(OUTDIR)\$(InputName).obj /Zm /Zi $(InputPath)]] }
		buildoutputs { [[$(OUTDIR)\$(InputName).obj]] }
	-- r_polysa.asm is the original's one inconsistency: its ALPHA branches
	-- are empty (no Exclude_From_Build), unlike every sibling
	filter { "configurations:*Alpha", "files:**.asm",
		"files:not **/r_polysa.asm" }
		excludefrombuild "On"
	filter {}
