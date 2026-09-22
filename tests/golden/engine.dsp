# Microsoft Developer Studio Project File - Name="engine" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

CFG=engine - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "engine.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "engine.mak" CFG="engine - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "engine - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "engine - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "engine - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Release"
# PROP BASE Intermediate_Dir "obj\Release\engine"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Release"
# PROP Intermediate_Dir "obj\Release\engine"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /O2 /I "engine\include" /D "ENGINE_EXPORTS" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /O2 /I "engine\include" /D "ENGINE_EXPORTS" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG" /d "ENGINE_EXPORTS" /d "ENGINE_RES" /i "engine\include" /i "engine\res" /x
# ADD RSC /l 0x409 /d "NDEBUG" /d "ENGINE_EXPORTS" /d "ENGINE_RES" /i "engine\include" /i "engine\res" /x
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /dll /machine:I386 /implib:"bin\Release\engine.lib" /out:"bin\Release\engine.dll" /libpath:"bin\Release"
# ADD LINK32 /nologo /dll /machine:I386 /implib:"bin\Release\engine.lib" /out:"bin\Release\engine.dll" /libpath:"bin\Release"
# Begin Special Build Tool
PreLink_Cmds=echo prebuild	echo prelink
PostBuild_Cmds=echo postbuild
# End Special Build Tool

!ELSEIF  "$(CFG)" == "engine - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Debug"
# PROP BASE Intermediate_Dir "obj\Debug\engine"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Debug"
# PROP Intermediate_Dir "obj\Debug\engine"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /I "engine\include" /D "ENGINE_EXPORTS" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /I "engine\include" /D "ENGINE_EXPORTS" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG" /d "ENGINE_EXPORTS" /d "ENGINE_RES" /i "engine\include" /i "engine\res" /x
# ADD RSC /l 0x409 /d "NDEBUG" /d "ENGINE_EXPORTS" /d "ENGINE_RES" /i "engine\include" /i "engine\res" /x
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /dll /machine:I386 /implib:"bin\Debug\engine.lib" /out:"bin\Debug\engine.dll" /libpath:"bin\Debug"
# ADD LINK32 /nologo /dll /machine:I386 /implib:"bin\Debug\engine.lib" /out:"bin\Debug\engine.dll" /libpath:"bin\Debug"
# Begin Special Build Tool
PreLink_Cmds=echo prebuild	echo prelink
PostBuild_Cmds=echo postbuild
# End Special Build Tool

!ENDIF

# Begin Target

# Name "engine - Win32 Release"
# Name "engine - Win32 Debug"
# Begin Group "engine"

# PROP Default_Filter ""
# Begin Source File

SOURCE=engine\engine.cpp
# End Source File
# Begin Source File

SOURCE=engine\engine.rc
# End Source File
# End Group
# End Target
# End Project
