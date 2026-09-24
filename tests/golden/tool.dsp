# Microsoft Developer Studio Project File - Name="tool" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=tool - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "tool.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "tool.mak" CFG="tool - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "tool - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "tool - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "tool - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Release"
# PROP BASE Intermediate_Dir "obj\Release\tool"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Release"
# PROP Intermediate_Dir "obj\Release\tool"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /O2 /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /O2 /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:windows /machine:I386 /out:"bin\Release\tool.exe" /libpath:"bin\Release"
# ADD LINK32 /nologo /subsystem:windows /machine:I386 /out:"bin\Release\tool.exe" /libpath:"bin\Release"

!ELSEIF  "$(CFG)" == "tool - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "bin\Debug"
# PROP BASE Intermediate_Dir "obj\Debug\tool"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "bin\Debug"
# PROP Intermediate_Dir "obj\Debug\tool"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD CPP /nologo /MD /W3 /GR /GX /D "_UNICODE" /D "UNICODE" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:windows /machine:I386 /out:"bin\Debug\tool.exe" /libpath:"bin\Debug"
# ADD LINK32 /nologo /subsystem:windows /machine:I386 /out:"bin\Debug\tool.exe" /libpath:"bin\Debug"

!ENDIF

# Begin Target

# Name "tool - Win32 Release"
# Name "tool - Win32 Debug"
# Begin Group "tool"

# PROP Default_Filter ""
# Begin Source File

SOURCE=tool\winmain.cpp
# End Source File
# End Group
# End Target
# End Project
