# Microsoft Developer Studio Project File - Name="app" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=app - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "app.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "app.mak" CFG="app - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "app - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "app - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "app - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "."
# PROP BASE Intermediate_Dir "obj/Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "."
# PROP Intermediate_Dir "obj/Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /ZI /O2 /I "engine/include" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /ZI /O2 /I "engine/include" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "_DEBUG" /i "engine/include"
# ADD RSC /l 0x409 /d "_DEBUG" /i "engine/include"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /entry:"mainCRTStartup" /subsystem:console /incremental:yes /debug /machine:I386 /out:"app.exe" /pdbtype:sept /libpath:"." /libpath:"libs"
# ADD LINK32 /nologo /entry:"mainCRTStartup" /subsystem:console /incremental:yes /debug /machine:I386 /out:"app.exe" /pdbtype:sept /libpath:"." /libpath:"libs"
# Begin Special Build Tool
PostBuild_Cmds=echo done
# End Special Build Tool

!ELSEIF  "$(CFG)" == "app - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "."
# PROP BASE Intermediate_Dir "obj/Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "."
# PROP Intermediate_Dir "obj/Debug"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MDd /W3 /Gm /GR /GX /ZI /Od /I "engine/include" /YX /FD /GZ /c
# ADD CPP /nologo /MDd /W3 /Gm /GR /GX /ZI /Od /I "engine/include" /YX /FD /GZ /c
# ADD BASE RSC /l 0x409 /d "_DEBUG" /i "engine/include"
# ADD RSC /l 0x409 /d "_DEBUG" /i "engine/include"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /entry:"mainCRTStartup" /subsystem:console /incremental:yes /debug /machine:I386 /out:"app.exe" /pdbtype:sept /libpath:"." /libpath:"libs"
# ADD LINK32 /nologo /entry:"mainCRTStartup" /subsystem:console /incremental:yes /debug /machine:I386 /out:"app.exe" /pdbtype:sept /libpath:"." /libpath:"libs"
# Begin Special Build Tool
PostBuild_Cmds=echo done
# End Special Build Tool

!ENDIF

# Begin Target

# Name "app - Win32 Release"
# Name "app - Win32 Debug"
# Begin Group "app"

# PROP Default_Filter ""
# Begin Source File

SOURCE=app/main.cpp
# End Source File
# End Group
# End Target
# End Project
