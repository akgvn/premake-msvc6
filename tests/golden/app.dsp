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
RSC=rc.exe

!IF  "$(CFG)" == "app - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Release"
# PROP BASE Intermediate_Dir "obj\Release\app"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Release"
# PROP Intermediate_Dir "obj\Release\app"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /O2 /I "engine\include" /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /O2 /I "engine\include" /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG" /i "engine\include"
# ADD RSC /l 0x409 /d "NDEBUG" /i "engine\include"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Release\app.exe" /libpath:"bin\Release" /libpath:"libs"
# ADD LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Release\app.exe" /libpath:"bin\Release" /libpath:"libs"
# Begin Special Build Tool
PostBuild_Cmds=echo done
# End Special Build Tool

!ELSEIF  "$(CFG)" == "app - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Debug"
# PROP BASE Intermediate_Dir "obj\Debug\app"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Debug"
# PROP Intermediate_Dir "obj\Debug\app"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /I "engine\include" /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /I "engine\include" /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG" /i "engine\include"
# ADD RSC /l 0x409 /d "NDEBUG" /i "engine\include"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Debug\app.exe" /libpath:"bin\Debug" /libpath:"libs"
# ADD LINK32 /nologo /subsystem:console /machine:I386 /out:"bin\Debug\app.exe" /libpath:"bin\Debug" /libpath:"libs"
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

SOURCE=app\main.cpp
# End Source File
# End Group
# End Target
# End Project
