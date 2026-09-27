--
-- test_vs6_files.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Files.cs
--
-- Note: the module emits Windows path separators (OQ-7), so SOURCE= lines
-- use backslashes where the 3.x parser saw forward slashes.
--

	local p = premake
	local suite = test.declare("vs6_files")
	local vs6 = p.modules.vs6
	local dsp = vs6.dsp


--
-- Setup: mirrors Script.MakeBasic("exe", "c++") from the 3.x framework.
--

	local wks, prj

	function suite.setup()
		p.action.set("vs6")
		wks = workspace("MyProject")
		configurations { "Debug", "Release" }
		prj = project("MyPackage")
		language "C++"
		kind "ConsoleApp"
		files { "somefile.txt" }
	end

	local function prepare()
		dsp.sourceTree(test.getproject(wks, 1))
	end


--
-- Files in the root directory are listed without a group.
--

	function suite.filesInRoot()
		files { "file1.cpp", "file2.cpp" }
		prepare()
		test.capture [[
# Begin Source File

SOURCE=somefile.txt
# End Source File
# Begin Source File

SOURCE=file1.cpp
# End Source File
# Begin Source File

SOURCE=file2.cpp
# End Source File
		]]
	end


--
-- Nested directories become nested groups; groups precede the files of
-- their parent directory.
--

	function suite.filesInSubDirs()
		files { "Src/file1.cpp", "Src/Base/file2.cpp" }
		prepare()
		test.capture [[
# Begin Group "Src"

# PROP Default_Filter ""
# Begin Group "Base"

# PROP Default_Filter ""
# Begin Source File

SOURCE=Src\Base\file2.cpp
# End Source File
# End Group
# Begin Source File

SOURCE=Src\file1.cpp
# End Source File
# End Group
# Begin Source File

SOURCE=somefile.txt
# End Source File
		]]
	end


--
-- Files above the project directory: the ".." group root is skipped (3.x
-- behavior), but the "Help" group inside it is kept.
--

	function suite.filesAboveDir()
		files { "Src/file1.cpp", "../Help/file2.cpp" }
		prepare()
		test.capture [[
# Begin Group "Src"

# PROP Default_Filter ""
# Begin Source File

SOURCE=Src\file1.cpp
# End Source File
# End Group
# Begin Group "Help"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\Help\file2.cpp
# End Source File
# End Group
# Begin Source File

SOURCE=somefile.txt
# End Source File
		]]
	end


--
-- SOURCE= paths containing spaces are quoted (VC6 won't parse them
-- unquoted; Peter's "Lucka 2.ico").
--

	function suite.pathWithSpacesIsQuoted()
		files { "Res/Lucka 2.ico", "Res/Lucka.ico" }
		prepare()
		test.capture [[
# Begin Group "Res"

# PROP Default_Filter ""
# Begin Source File

SOURCE="Res\Lucka 2.ico"
# End Source File
# Begin Source File

SOURCE=Res\Lucka.ico
# End Source File
# End Group
# Begin Source File

SOURCE=somefile.txt
# End Source File
		]]
	end


--
-- vpath rules drive logical groups; SOURCE= keeps the physical path
-- (Peter's "Buffery"/"Editory" groups).
--

	function suite.vpathGroups()
		vpaths { ["Buffers"] = "**.h" }
		files { "Src/file1.cpp", "Src/file1.h" }
		prepare()
		test.capture [[
# Begin Group "Src"

# PROP Default_Filter ""
# Begin Source File

SOURCE=Src\file1.cpp
# End Source File
# End Group
# Begin Group "Buffers"

# PROP Default_Filter ""
# Begin Source File

SOURCE=Src\file1.h
# End Source File
# End Group
# Begin Source File

SOURCE=somefile.txt
# End Source File
		]]
	end


--
-- excludefrombuild (files: filter): per-config Exclude_From_Build blocks
-- for the excluded configurations only, in reversed config order
-- (quake2's ref_soft, Peter's ProgInit.inc).
--

	function suite.excludeFromAllConfigs()
		filter "files:somefile.txt"
		excludefrombuild "On"
		filter {}
		prepare()
		test.capture [[
# Begin Source File

SOURCE=somefile.txt

!IF  "$(CFG)" == "MyPackage - Win32 Release"

# PROP Exclude_From_Build 1

!ELSEIF  "$(CFG)" == "MyPackage - Win32 Debug"

# PROP Exclude_From_Build 1

!ENDIF 

# End Source File
		]]
	end


	function suite.excludeFromOneConfig()
		filter { "configurations:Debug", "files:somefile.txt" }
		excludefrombuild "On"
		filter {}
		prepare()
		test.capture [[
# Begin Source File

SOURCE=somefile.txt

!IF  "$(CFG)" == "MyPackage - Win32 Debug"

# PROP Exclude_From_Build 1

!ENDIF 

# End Source File
		]]
	end


--
-- Per-file custom build rules (buildcommands/buildoutputs on a files:
-- filter); zlib's ml.exe steps. Mixes freely with excludefrombuild.
--

	function suite.customBuildAllConfigs()
		filter "files:somefile.txt"
		buildcommands { "ml.exe /nologo /c /coff /Cx /Fo\"$(IntDir)\\$(InputName).obj\" \"$(InputPath)\"" }
		buildoutputs { "$(IntDir)\\$(InputName).obj" }
		filter {}
		prepare()
		test.capture [[
# Begin Source File

SOURCE=somefile.txt

!IF  "$(CFG)" == "MyPackage - Win32 Release"

# Begin Custom Build
IntDir=obj\Release
InputPath=somefile.txt
InputName=somefile

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml.exe /nologo /c /coff /Cx /Fo"$(IntDir)\$(InputName).obj" "$(InputPath)"

# End Custom Build

!ELSEIF  "$(CFG)" == "MyPackage - Win32 Debug"

# Begin Custom Build
IntDir=obj\Debug
InputPath=somefile.txt
InputName=somefile

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml.exe /nologo /c /coff /Cx /Fo"$(IntDir)\$(InputName).obj" "$(InputPath)"

# End Custom Build

!ENDIF 

# End Source File
		]]
	end


	function suite.customBuildMixedWithExclude()
		filter { "configurations:Debug", "files:somefile.txt" }
		excludefrombuild "On"
		filter { "configurations:Release", "files:somefile.txt" }
		buildcommands { "ml.exe /c \"$(InputPath)\"" }
		buildoutputs { "$(IntDir)\\$(InputName).obj" }
		filter {}
		prepare()
		test.capture [[
# Begin Source File

SOURCE=somefile.txt

!IF  "$(CFG)" == "MyPackage - Win32 Release"

# Begin Custom Build
IntDir=obj\Release
InputPath=somefile.txt
InputName=somefile

"$(IntDir)\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml.exe /c "$(InputPath)"

# End Custom Build

!ELSEIF  "$(CFG)" == "MyPackage - Win32 Debug"

# PROP Exclude_From_Build 1

!ENDIF 

# End Source File
		]]
	end


--
-- PCH: pchheader replaces the fixed /YX with /Yu"hdr"; the pchsource
-- file gets per-config /Yc"hdr" (Gener's StdAfx.cpp)
--

	function suite.pchHeader()
		pchheader "stdafx.h"
		pchsource "somefile.txt"
		prepare()
		test.capture [[
# Begin Source File

SOURCE=somefile.txt

# ADD CPP /Yc"stdafx.h"
# End Source File
		]]
	end


	function suite.pchDisabled()
		pchheader "stdafx.h"
		pchsource "somefile.txt"
		enablepch "Off"
		prepare()
		test.capture [[
# Begin Source File

SOURCE=somefile.txt
# End Source File
		]]
	end

--
-- Per-file compiler additions (zlib's per-file /I)
--

	function suite.perFileCppFlags()
		filter "files:somefile.txt"
		includedirs { "../.." }
		filter {}
		prepare()
		test.capture [[
# Begin Source File

SOURCE=somefile.txt

# ADD CPP /I "..\.."
# End Source File
		]]
	end


--
-- Per-file CPP flags that differ per configuration (or mix with
-- excludes/custom builds) are chained per configuration
--

	function suite.perFileCppFlagsPerConfig()
		filter { "configurations:Debug", "files:somefile.txt" }
		includedirs { "../.." }
		filter {}
		prepare()
		test.capture [[
# Begin Source File

SOURCE=somefile.txt

!IF  "$(CFG)" == "MyPackage - Win32 Debug"

# ADD CPP /I "..\.."

!ENDIF 

# End Source File
		]]
	end
