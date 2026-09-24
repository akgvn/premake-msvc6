# Microsoft Developer Studio Project File - Name="core" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

CFG=core - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "core.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "core.mak" CFG="core - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "core - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "core - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "core - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Release"
# PROP BASE Intermediate_Dir "obj\Release\core"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Release"
# PROP Intermediate_Dir "obj\Release\core"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /O2 /D "_UNICODE" /D "UNICODE" /D "CORE_LIB" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /O2 /D "_UNICODE" /D "UNICODE" /D "CORE_LIB" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG" /d "CORE_LIB"
# ADD RSC /l 0x409 /d "NDEBUG" /d "CORE_LIB"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"bin\Release\core.lib"

!ELSEIF  "$(CFG)" == "core - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Debug"
# PROP BASE Intermediate_Dir "obj\Debug\core"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Debug"
# PROP Intermediate_Dir "obj\Debug\core"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /D "CORE_LIB" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /D "CORE_LIB" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG" /d "CORE_LIB"
# ADD RSC /l 0x409 /d "NDEBUG" /d "CORE_LIB"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"bin\Debug\core.lib"

!ENDIF

# Begin Target

# Name "core - Win32 Release"
# Name "core - Win32 Debug"
# Begin Group "core"

# PROP Default_Filter ""
# Begin Source File

SOURCE=core\core.cpp
# End Source File
# Begin Source File

SOURCE=core\core.h
# End Source File
# End Group
# End Target
# End Project
