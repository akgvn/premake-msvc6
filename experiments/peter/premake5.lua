--
-- experiments/peter/premake5.lua
-- Reproduce Peter.dsw + its 8 .dsp files (real-world-test-cases/peter)
-- with the vs6 module. Pair with tools/dspdiff.py via run.py.
--
-- Era-accurate choices: characterset "ASCII" (these VC6-era projects
-- carry no _UNICODE/_MBCS charset define; premake5's Default would add
-- _UNICODE defines), locale "cs-CZ" (RSC /l 0x405), explicit _DEBUG/
-- NDEBUG marker defines (VC6 wizards put them on the CPP line), /G4 and
-- /Zp4 through buildoptions (no dedicated mapping yet — Step 4).
--

require "vs6"

workspace "Peter"
	-- each project declares its own configurations below (they differ
	-- per project); the workspace level just needs something
	configurations { "Debug", "Release" }

--
-- Shared setting blocks. The "Peter family" projects share flag
-- conventions; Gener differs (W3, PCH, _MBCS).
--

local function era()
	characterset "ASCII"
	locale "cs-CZ"
end

-- the Peter family carries no /GR or /GX; Gener is the exception (/GX)
local function peterfamily()
	rtti "Off"
	exceptionhandling "Off"
end

local function debugcfg()
	defines { "_DEBUG" }
	symbols "On"
	editandcontinue "Off"
	minimalrebuild "On"
	optimize "Off"
	incrementallink "Off"
	runtime "Debug"
end

local function releasecfg()
	defines { "NDEBUG" }
	optimize "Speed"
end

-- map of config name -> output dir, applied as per-config filters
local function outdirs(map)
	for cfgname, dir in pairs(map) do
		filter { "configurations:" .. cfgname }
			targetdir(dir)
			objdir(dir)
	end
	filter {}
end


--
-- DataInst (WindowedApp; builds Setup.exe, not DataInst.exe)
--

project "DataInst"
	kind "WindowedApp"
	language "C++"
	location "DataInst"
	targetname "Setup"
	configurations { "Debug", "Release" }
	era()
	peterfamily()
	warnings "Extra"
	defines { "WIN32", "_WINDOWS", "NDEMO" }
	buildoptions { "/G4", "/Zp4" }
	linkoptions { "/nodefaultlib" }
	links { "lib/tran.lib", "winmm", "comctl32" }

	vpaths {
		["Source Files/Header Files"] = {
			"DataInst/BufText.h", "DataInst/Compress.h", "DataInst/File.h",
			"DataInst/Main.h", "DataInst/Memory.h",
		},
		["Source Files"] = {
			"DataInst/BufText.cpp", "DataInst/Compress.cpp", "DataInst/File.cpp",
			"DataInst/Main.cpp", "DataInst/Memory.cpp", "DataInst/Stubs.c",
		},
		["Resource Files"] = { "DataInst/Res/*", "DataInst/Resource.rc" },
	}

	files {
		"DataInst/BufText.h", "DataInst/Compress.h", "DataInst/File.h",
		"DataInst/Main.h", "DataInst/Memory.h",
		"DataInst/BufText.cpp", "DataInst/Compress.cpp", "DataInst/File.cpp",
		"DataInst/Main.cpp", "DataInst/Memory.cpp", "DataInst/Stubs.c",
		"DataInst/Res/*.bmp", "DataInst/Res/*.BMP", "DataInst/Res/*.ico", "DataInst/Res/*.cur",
		"DataInst/Resource.rc",
	}

	filter "configurations:Debug"
		debugcfg()
	filter "configurations:Release"
		releasecfg()
		defines { "_OPTIM" }
	filter {}

	outdirs { Debug = "DataInst/Debug", Release = "DataInst/Release" }


--
-- DelExe (WindowedApp, single source file)
--

project "DelExe"
	kind "WindowedApp"
	language "C++"
	location "DelExe"
	configurations { "Debug", "Release" }
	era()
	peterfamily()
	warnings "Extra"
	defines { "WIN32", "_WINDOWS" }
	buildoptions { "/G4", "/Zp4" }
	linkoptions { "/nodefaultlib" }
	links { "lib/tran.lib", "winmm", "comctl32" }
	files { "DelExe/Main.cpp" }

	filter "configurations:Debug"
		debugcfg()
	filter "configurations:Release"
		releasecfg()
		defines { "_OPTIM" }
	filter {}

	outdirs { Debug = "DelExe/Debug", Release = "DelExe/Release" }


--
-- Gener (ConsoleApp; precompiled header stdafx.h)
--

project "Gener"
	kind "ConsoleApp"
	language "C++"
	location "Gener"
	configurations { "Release MINI", "Install", "Debug", "Release" }
	era()
	rtti "Off"
	defines { "WIN32", "_CONSOLE", "_MBCS" }
	pchheader "stdafx.h"
	pchsource "Gener/StdAfx.cpp"

	vpaths {
		["Source Files"] = { "Gener/*.cpp" },
		["Header Files"] = { "Gener/*.h" },
	}

	files {
		"Gener/BufText.cpp", "Gener/File.cpp", "Gener/Gener.cpp", "Gener/StdAfx.cpp",
		"Gener/BufText.h", "Gener/File.h", "Gener/StdAfx.h",
	}

	filter "configurations:Release"
		releasecfg()
		defines { "NDEMO", "NINSTAL" }
		resdefines { "NDEMO", "NINSTALL" }
	filter "configurations:Debug"
		defines { "_DEBUG", "NDEMO", "NINSTALL" }
		resdefines { "NDEMO", "NINSTALL" }
		symbols "On"
		editandcontinue "Off"
		optimize "Off"
		incrementallink "Off"
		runtime "Debug"
		exceptionhandling "Off"
		enablepch "Off"
	filter "configurations:Install"
		releasecfg()
		defines { "NDEMO", "_INSTALL" }
		resdefines { "_DEMO", "_INSTALL" }
	filter "configurations:Release MINI"
		releasecfg()
		defines { "MINI", "NDEMO", "NINSTAL" }
		resdefines { "NDEMO", "NINSTALL" }
	filter {}

	outdirs {
		Release = "Gener/Release", Debug = "Gener/Debug",
		Install = "Gener/Install", ["Release MINI"] = "Gener/Release_MINI",
	}


--
-- Loader (WindowedApp; .dsp file is named Peter.dsp, not Loader.dsp)
--

project "Loader"
	kind "WindowedApp"
	language "C++"
	location "Loader"
	filename "Peter"
	configurations { "Release Mini", "Debug Optim", "Debug", "Release" }
	era()
	peterfamily()
	warnings "Extra"
	defines { "WIN32", "_WINDOWS" }
	buildoptions { "/G4", "/Zp4" }
	linkoptions { "/nodefaultlib" }
	links { "lib/tran.lib", "msacm32", "winmm", "comctl32" }

	vpaths {
		["Buffery/Buffery H"] = {
			"Loader/BufD3D.h", "Loader/BufIcon.h", "Loader/BufInt.h",
			"Loader/BufList.h", "Loader/BufMap.h", "Loader/BufMus.h",
			"Loader/BufPic.h", "Loader/BufReal.h", "Loader/BufSnd.h",
			"Loader/BufSprt.h", "Loader/BufText.h", "Loader/BUFWIN.H",
			"Loader/BufXFile.h", "Loader/JPEG.h",
		},
		["Buffery"] = {
			"Loader/BufD3D.cpp", "Loader/BufIcon.cpp", "Loader/BufInt.cpp",
			"Loader/BufList.cpp", "Loader/BufMap.cpp", "Loader/BufMus.cpp",
			"Loader/BufPic.cpp", "Loader/BufReal.cpp", "Loader/BufSnd.cpp",
			"Loader/BufSprt.cpp", "Loader/BufText.cpp", "Loader/BUFWIN.CPP",
			"Loader/BufXFile.cpp", "Loader/JPEG.cpp",
		},
		["Main/Main H"] = {
			"Loader/Bitmap.h", "Loader/Compress.h", "Loader/D3DX4.h",
			"Loader/D3DX5.h", "Loader/D3DX6.h", "Loader/D3DX7.h", "Loader/D3DX8.h",
			"Loader/D3GL0.h", "Loader/D3GL1.h", "Loader/D3GL2.h", "Loader/D3NO.h",
			"Loader/File.h", "Loader/Main.h", "Loader/MainFrm.h", "Loader/Memory.h",
		},
		["Main"] = {
			"Loader/Bitmap.cpp", "Loader/Compress.cpp", "Loader/D3DX4.cpp",
			"Loader/D3DX5.cpp", "Loader/D3DX6.cpp", "Loader/D3DX7.cpp",
			"Loader/D3DX8.cpp", "Loader/D3GL0.cpp", "Loader/D3GL1.cpp",
			"Loader/D3GL2.cpp", "Loader/D3NO.cpp", "Loader/File.cpp",
			"Loader/Main.cpp", "Loader/MainFrm.cpp", "Loader/Memory.cpp",
			"Loader/Stubs.c",
		},
		["Comp/Comp H"] = {
			"Loader/Comp.h", "Loader/CompCom.h", "Loader/CompIco.h",
			"Loader/CompLog.h", "Loader/CompMap.h", "Loader/CompMus.h",
			"Loader/CompNum.h", "Loader/CompPic.h", "Loader/CompSnd.h",
			"Loader/CompSpr.h", "Loader/CompTxt.h",
		},
		["Comp"] = {
			"Loader/Comp.cpp", "Loader/CompCom.cpp", "Loader/CompIco.cpp",
			"Loader/CompLog.cpp", "Loader/CompMap.cpp", "Loader/CompMus.cpp",
			"Loader/CompNum.cpp", "Loader/CompPic.cpp", "Loader/CompSnd.cpp",
			"Loader/CompSpr.cpp", "Loader/CompTxt.cpp",
		},
		["Resource"] = {
			"Res/cursor1.cur", "PalImp.dat", "Res/Peter.ico",
			"Loader/Resource.h", "Loader/Resource.rc",
		},
		["Load/Load H"] = { "Loader/Load.h" },
		["Load"] = { "Loader/Load.cpp" },
		["Exec/Exec H"] = {
			"Loader/Exec.h", "Loader/ExecCom.h", "Loader/ExecIco.h",
			"Loader/ExecLog.h", "Loader/ExecMap.h", "Loader/ExecMus.h",
			"Loader/ExecNum.h", "Loader/ExecPic.h", "Loader/ExecSnd.h",
			"Loader/ExecSpr.h", "Loader/ExecTxt.h",
		},
		["Exec"] = {
			"Loader/Exec.cpp", "Loader/ExecCom.cpp", "Loader/ExecIco.cpp",
			"Loader/ExecLog.cpp", "Loader/ExecMap.cpp", "Loader/ExecMus.cpp",
			"Loader/ExecNum.cpp", "Loader/ExecPic.cpp", "Loader/ExecSnd.cpp",
			"Loader/ExecSpr.cpp", "Loader/ExecTxt.cpp",
		},
	}

	files {
		"Loader/BufD3D.h", "Loader/BufIcon.h", "Loader/BufInt.h",
		"Loader/BufList.h", "Loader/BufMap.h", "Loader/BufMus.h",
		"Loader/BufPic.h", "Loader/BufReal.h", "Loader/BufSnd.h",
		"Loader/BufSprt.h", "Loader/BufText.h", "Loader/BUFWIN.H",
		"Loader/BufXFile.h", "Loader/JPEG.h",
		"Loader/BufD3D.cpp", "Loader/BufIcon.cpp", "Loader/BufInt.cpp",
		"Loader/BufList.cpp", "Loader/BufMap.cpp", "Loader/BufMus.cpp",
		"Loader/BufPic.cpp", "Loader/BufReal.cpp", "Loader/BufSnd.cpp",
		"Loader/BufSprt.cpp", "Loader/BufText.cpp", "Loader/BUFWIN.CPP",
		"Loader/BufXFile.cpp", "Loader/JPEG.cpp",
		"Loader/Bitmap.h", "Loader/Compress.h", "Loader/D3DX4.h",
		"Loader/D3DX5.h", "Loader/D3DX6.h", "Loader/D3DX7.h", "Loader/D3DX8.h",
		"Loader/D3GL0.h", "Loader/D3GL1.h", "Loader/D3GL2.h", "Loader/D3NO.h",
		"Loader/File.h", "Loader/Main.h", "Loader/MainFrm.h", "Loader/Memory.h",
		"Loader/Bitmap.cpp", "Loader/Compress.cpp", "Loader/D3DX4.cpp",
		"Loader/D3DX5.cpp", "Loader/D3DX6.cpp", "Loader/D3DX7.cpp",
		"Loader/D3DX8.cpp", "Loader/D3GL0.cpp", "Loader/D3GL1.cpp",
		"Loader/D3GL2.cpp", "Loader/D3NO.cpp", "Loader/File.cpp",
		"Loader/Main.cpp", "Loader/MainFrm.cpp", "Loader/Memory.cpp",
		"Loader/Stubs.c",
		"Loader/Comp.h", "Loader/CompCom.h", "Loader/CompIco.h",
		"Loader/CompLog.h", "Loader/CompMap.h", "Loader/CompMus.h",
		"Loader/CompNum.h", "Loader/CompPic.h", "Loader/CompSnd.h",
		"Loader/CompSpr.h", "Loader/CompTxt.h",
		"Loader/Comp.cpp", "Loader/CompCom.cpp", "Loader/CompIco.cpp",
		"Loader/CompLog.cpp", "Loader/CompMap.cpp", "Loader/CompMus.cpp",
		"Loader/CompNum.cpp", "Loader/CompPic.cpp", "Loader/CompSnd.cpp",
		"Loader/CompSpr.cpp", "Loader/CompTxt.cpp",
		"Res/cursor1.cur", "PalImp.dat", "Res/Peter.ico",
		"Loader/Resource.h", "Loader/Resource.rc",
		"Loader/Load.h", "Loader/Load.cpp",
		"Loader/Exec.h", "Loader/ExecCom.h", "Loader/ExecIco.h",
		"Loader/ExecLog.h", "Loader/ExecMap.h", "Loader/ExecMus.h",
		"Loader/ExecNum.h", "Loader/ExecPic.h", "Loader/ExecSnd.h",
		"Loader/ExecSpr.h", "Loader/ExecTxt.h",
		"Loader/Exec.cpp", "Loader/ExecCom.cpp", "Loader/ExecIco.cpp",
		"Loader/ExecLog.cpp", "Loader/ExecMap.cpp", "Loader/ExecMus.cpp",
		"Loader/ExecNum.cpp", "Loader/ExecPic.cpp", "Loader/ExecSnd.cpp",
		"Loader/ExecSpr.cpp", "Loader/ExecTxt.cpp",
	}

	filter "configurations:Release"
		releasecfg()
		defines { "_OPTIM" }
	filter "configurations:Debug"
		debugcfg()
	filter "configurations:Debug Optim"
		defines { "_DEBUG", "_OPTIM" }
		symbols "On"
		editandcontinue "Off"
		optimize "Speed"
		minimalrebuild "On"
		incrementallink "Off"
		runtime "Debug"
	filter "configurations:Release Mini"
		releasecfg()
		defines { "_MINI", "_OPTIM" }
	filter {}

	outdirs {
		Release = "Loader/Release", Debug = "Loader/Debug",
		["Debug Optim"] = "Loader/DebugO", ["Release Mini"] = "Loader/ReleaseM",
	}


--
-- Loader0 (WindowedApp; .dsp file is Peter.dsp too)
--

project "Loader0"
	kind "WindowedApp"
	language "C++"
	location "Loader0"
	filename "Peter"
	configurations { "Debug", "Release" }
	era()
	peterfamily()
	warnings "Extra"
	defines { "WIN32", "_WINDOWS" }
	buildoptions { "/G4", "/Zp4" }
	linkoptions { "/nodefaultlib" }
	links { "lib/tran.lib", "winmm", "comctl32" }

	vpaths { [""] = { "Res/Peter.ico" } }

	files {
		"Loader0/Main.cpp", "Res/Peter.ico",
		"Loader0/Resource.h", "Loader0/Resource.RC",
	}

	filter "configurations:Debug"
		debugcfg()
	filter "configurations:Release"
		releasecfg()
		defines { "_OPTIM" }
	filter {}

	outdirs { Debug = "Loader0/Debug", Release = "Loader0/Release" }


--
-- Peter (the main editor, WindowedApp)
--

project "Peter"
	kind "WindowedApp"
	language "C++"
	configurations { "Debug Optim", "Debug", "Release" }
	era()
	peterfamily()
	warnings "Extra"
	defines { "WIN32", "_WINDOWS" }
	resdefines { "NDEMO", "NDEMONLITE" }
	buildoptions { "/G4", "/Zp4" }
	linkoptions { "/nodefaultlib" }
	links { "lib/tran.lib", "winmm", "comctl32" }

	vpaths {
		["Buffery/Buffery H"] = {
			"Buffer.h", "BufIcon.h", "BufInt.h", "BufInx.h", "BufMap.h",
			"BufMus.h", "BufPic.h", "BufProg.h", "BufReal.h", "BufSnd.h",
			"BufSprt.h", "BufText.h", "BufUndo.h", "JPEG.h",
		},
		["Buffery"] = {
			"BufIcon.cpp", "BufInt.cpp", "BufInx.cpp", "BufMap.cpp",
			"BufMus.cpp", "BufPic.cpp", "BufProg.cpp", "BufReal.cpp",
			"BufSnd.cpp", "BufSprt.cpp", "BufText.cpp", "BufUndo.cpp", "JPEG.cpp",
		},
		["Editory/Editory H"] = {
			"EditIcon.h", "EditLog.h", "EditMap.h", "EditMus.h",
			"EditNum.h", "EditSnd.h", "EditSprt.h", "EditText.h",
		},
		["Editory"] = {
			"EditIcon.cpp", "EditLog.cpp", "EditMap.cpp", "EditMus.cpp",
			"EditNum.cpp", "EditSnd.cpp", "EditSprt.cpp", "EditText.cpp",
		},
		["Main/Main H"] = {
			"Bitmap.h", "Compress.h", "File.h", "Main.h", "MainFrm.h", "Memory.h",
		},
		["Main"] = {
			"Bitmap.cpp", "Compress.cpp", "File.cpp", "Main.cpp", "MainFrm.cpp",
			"Memory.cpp", "Stubs.c",
		},
		["Select/Select H"] = { "Select.h" },
		["Select"] = { "Select.cpp" },
		["Prog/Prog H INC"] = {
			"Prog.h", "ProgClip.h", "PROGCOL.H", "ProgDrag.h", "ProgExp.h",
			"ProgFile.h", "ProgHist.h", "ProgInit.inc", "ProgLib.h",
		},
		["Prog"] = {
			"Prog.cpp", "ProgClip.cpp", "PROGCOL.CPP", "ProgDrag.cpp",
			"ProgExp.cpp", "ProgFile.cpp", "ProgHist.cpp", "ProgLib.cpp",
		},
		["Resource/cur"] = { "Res/*.cur" },
		["Resource/ico"] = { "Res/*.ico" },
		["Resource/bmp"] = { "Res/*.bmp" },
		["Resource/dat"] = { "Pal*.dat" },
		["Resource/exe"] = { "Loader*/**/Peter.exe" },
		["Resource/txt"] = { "Text*.inc" },
		["Resource"] = { "Resource.h", "Resource.rc" },
	}

	files {
		"Buffer.h", "BufIcon.h", "BufInt.h", "BufInx.h", "BufMap.h",
		"BufMus.h", "BufPic.h", "BufProg.h", "BufReal.h", "BufSnd.h",
		"BufSprt.h", "BufText.h", "BufUndo.h", "JPEG.h",
		"BufIcon.cpp", "BufInt.cpp", "BufInx.cpp", "BufMap.cpp",
		"BufMus.cpp", "BufPic.cpp", "BufProg.cpp", "BufReal.cpp",
		"BufSnd.cpp", "BufSprt.cpp", "BufText.cpp", "BufUndo.cpp", "JPEG.cpp",
		"EditIcon.h", "EditLog.h", "EditMap.h", "EditMus.h",
		"EditNum.h", "EditSnd.h", "EditSprt.h", "EditText.h",
		"EditIcon.cpp", "EditLog.cpp", "EditMap.cpp", "EditMus.cpp",
		"EditNum.cpp", "EditSnd.cpp", "EditSprt.cpp", "EditText.cpp",
		"Bitmap.h", "Compress.h", "File.h", "Main.h", "MainFrm.h", "Memory.h",
		"Bitmap.cpp", "Compress.cpp", "File.cpp", "Main.cpp", "MainFrm.cpp",
		"Memory.cpp", "Stubs.c",
		"Select.h", "Select.cpp",
		"Prog.h", "ProgClip.h", "PROGCOL.H", "ProgDrag.h", "ProgExp.h",
		"ProgFile.h", "ProgHist.h", "ProgInit.inc", "ProgLib.h",
		"Prog.cpp", "ProgClip.cpp", "PROGCOL.CPP", "ProgDrag.cpp",
		"ProgExp.cpp", "ProgFile.cpp", "ProgHist.cpp", "ProgLib.cpp",
		"Res/Cil.cur", "Res/Copy.cur", "Res/Delete.cur", "Res/Elip.cur",
		"Res/Fill.cur", "Res/FillElip.cur", "Res/FillRect.cur",
		"Res/FillRoun.cur", "Res/Kapatko.cur", "Res/Koule.cur", "Res/Line.cur",
		"Res/Move.cur", "Res/NoDrag.cur", "Res/Paint.cur", "Res/Pen.cur",
		"Res/Rect.cur", "Res/Round.cur", "Res/Ruka.cur", "Res/Select.cur",
		"Res/SelMove.cur", "Res/SplitH.cur", "Res/SplitV.cur", "Res/Spray.cur",
		"Res/Lucka 2.ico", "Res/Lucka 3.ico", "Res/Lucka.ico",
		"Res/Peter.ico", "Res/Peter4.ico", "Res/Petr 2.ico", "Res/Petr 3.ico",
		"Res/Cz1.bmp", "Res/Cz2.bmp", "Res/Dotaz.bmp", "Res/Eng1.bmp",
		"Res/Eng2.bmp", "Res/Fra1.bmp", "Res/Fra2.bmp", "Res/Ger1.bmp",
		"Res/Ger2.bmp", "Res/Icon.bmp", "Res/ita1.bmp", "Res/ita2.bmp",
		"Res/MainFram.bmp", "Res/MapSwc.bmp", "Res/MapSwcNm.bmp",
		"Res/Modi.bmp", "Res/pol1.bmp", "Res/pol2.bmp", "Res/rus1.bmp",
		"Res/rus2.bmp", "Res/Select.bmp", "Res/Slo1.bmp", "Res/Slo2.bmp",
		"Res/Spa1.bmp", "Res/Spa2.bmp", "Res/Sprite.bmp", "Res/State.bmp",
		"Res/stdfonty.bmp", "Res/ToolBar.bmp", "Res/wizard_256.bmp",
		"PalImp.dat", "PalImpD.dat",
		"Loader0/Release/Peter.exe", "Loader/Debug/Peter.exe",
		"Loader/DebugO/Peter.exe", "Loader/Lite/Peter.exe",
		"Loader/LiteM/Peter.exe", "Loader/Release/Peter.exe",
		"Loader/ReleaseM/Peter.exe", "Loader/Unicode/Peter.exe",
		"TextAlb.inc", "TextAra.inc", "TextBul.inc", "TextCz.inc",
		"TextDan.inc", "TextEng.inc", "TextFin.inc", "TextFra.inc",
		"TextGer.inc", "TextHeb.inc", "TextHol.inc", "TextIsl.inc",
		"TextIta.inc", "TextMad.inc", "TextNor.inc", "TextPol.inc",
		"TextPor.inc", "TextRec.inc", "TextRum.inc", "TextRus.inc",
		"TextSlo.inc", "TextSpa.inc", "TextSrb.inc", "TextSwe.inc",
		"TextTur.inc", "TextVie.inc",
		"Resource.h", "Resource.rc",
	}

	filter "files:ProgInit.inc"
		excludefrombuild "On"
	filter "configurations:Release"
		releasecfg()
		defines { "_OPTIM" }
		resdefines { "_LOADER" }
	filter "configurations:Debug"
		debugcfg()
		resdefines { "_LOADER" }
	filter "configurations:Debug Optim"
		defines { "_DEBUG", "_OPTIM" }
		symbols "On"
		editandcontinue "Off"
		optimize "Speed"
		minimalrebuild "On"
		incrementallink "Off"
		runtime "Debug"
		resdefines { "LOADERD" }
	filter {}

	outdirs { Release = "Release", Debug = "Debug", ["Debug Optim"] = "DebugO" }


--
-- Pov2Spr (ConsoleApp)
--

project "Pov2Spr"
	kind "ConsoleApp"
	language "C++"
	location "Pov2Spr"
	configurations { "Debug", "Release" }
	era()
	peterfamily()
	warnings "Extra"
	defines { "WIN32", "_CONSOLE" }
	buildoptions { "/G4", "/Zp4" }
	linkoptions { "/nodefaultlib" }
	links { "lib/tran.lib" }

	files {
		"Pov2Spr/Bitmap.cpp", "Pov2Spr/Bitmap.h",
		"Pov2Spr/BufPic.cpp", "Pov2Spr/BufPic.h",
		"Pov2Spr/BufSprt.cpp", "Pov2Spr/BufSprt.h",
		"Pov2Spr/BufText.cpp", "Pov2Spr/BufText.h",
		"Compress.cpp", "Compress.h",
		"Pov2Spr/File.cpp", "Pov2Spr/File.h",
		"Pov2Spr/Main.cpp", "Pov2Spr/Main.h",
		"Pov2Spr/Memory.cpp", "Pov2Spr/Memory.h",
		"PalImp.dat", "PalImpD.dat",
		"Pov2Spr/Pov2Spr.ico", "Pov2Spr/Resource.rc", "Pov2Spr/Stubs.c",
	}

	filter "configurations:Debug"
		debugcfg()
	filter "configurations:Release"
		releasecfg()
		defines { "_OPTIM" }
	filter {}

	outdirs { Debug = "Pov2Spr/Debug", Release = "Pov2Spr/Release" }


--
-- Setup (WindowedApp)
--

project "Setup"
	kind "WindowedApp"
	language "C++"
	location "Setup"
	configurations { "Release MINI", "Debug Demo", "Debug", "Release" }
	era()
	peterfamily()
	warnings "Extra"
	defines { "WIN32", "_WINDOWS" }
	buildoptions { "/G4", "/Zp4" }
	linkoptions { "/nodefaultlib" }
	links { "lib/tran.lib", "winmm", "comctl32" }

	vpaths { [""] = { "Setup/Res/DelExe.exe" } }

	vpaths {
		["Source Files/Header Files"] = {
			"Setup/Bitmap.h", "Setup/BufPic.h", "Setup/BufText.h",
			"Setup/Compress.h", "Setup/File.h", "Setup/Main.h", "Setup/Memory.h",
		},
		["Source Files"] = {
			"Setup/Bitmap.cpp", "Setup/BufPic.cpp", "Setup/BufText.cpp",
			"Setup/Compress.cpp", "Setup/File.cpp", "Setup/Main.cpp",
			"Setup/Memory.cpp", "Setup/Stubs.c",
		},
		["Resource Files"] = { "Setup/Res/*", "Setup/Resource.rc" },
	}

	files {
		"Setup/Bitmap.h", "Setup/BufPic.h", "Setup/BufText.h",
		"Setup/Compress.h", "Setup/File.h", "Setup/Main.h", "Setup/Memory.h",
		"Setup/Bitmap.cpp", "Setup/BufPic.cpp", "Setup/BufText.cpp",
		"Setup/Compress.cpp", "Setup/File.cpp", "Setup/Main.cpp",
		"Setup/Memory.cpp", "Setup/Stubs.c",
		"Setup/Res/*.bmp", "Setup/Res/*.BMP", "Setup/Res/*.ico", "Setup/Res/*.cur",
		"Setup/Resource.rc",
		"Setup/Res/DelExe.exe",
	}

	filter "configurations:Release"
		releasecfg()
		defines { "NDEMO", "_OPTIM" }
	filter "configurations:Debug"
		debugcfg()
		defines { "NDEMO" }
	filter "configurations:Debug Demo"
		defines { "_DEBUG", "_DEMO" }
		resdefines { "_DEMONLITE" }
		symbols "On"
		editandcontinue "Off"
		minimalrebuild "On"
		optimize "Off"
		incrementallink "Off"
		runtime "Debug"
		buildoptions { "/ML" }
	filter "configurations:Release MINI"
		releasecfg()
		defines { "MINI", "NDEMO", "_OPTIM" }
	filter {}

	outdirs {
		Release = "Setup/Release", Debug = "Setup/Debug",
		["Debug Demo"] = "Setup/DebugDem", ["Release MINI"] = "Setup/Release_MINI",
	}
