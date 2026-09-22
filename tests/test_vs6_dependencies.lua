--
-- test_vs6_dependencies.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Dependencies.cs
--

	local p = premake
	local suite = test.declare("vs6_dependencies")
	local vs6 = p.modules.vs6


--
-- Setup: a workspace with two projects; MyPackage links PackageB.
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
		links { "PackageB" }
	end

	local function addPackageB(kindname)
		local prj2 = project("PackageB")
		language "C++"
		kind(kindname)
		files { "somefile.cpp" }
	end

	local function captureDsw()
		vs6.generateWorkspace(test.getWorkspace(wks))
	end


--
-- Executable depending on a shared library.
--

	function suite.exeAndDll()
		addPackageB("SharedLib")
		captureDsw()
		test.capture [[
Microsoft Developer Studio Workspace File, Format Version 6.00
# WARNING: DO NOT EDIT OR DELETE THIS WORKSPACE FILE!

###############################################################################

Project: "MyPackage"=.\MyPackage.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
    Begin Project Dependency
    Project_Dep_Name PackageB
    End Project Dependency
}}}

###############################################################################

Project: "PackageB"=.\PackageB.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

###############################################################################

Global:

Package=<5>
{{{
}}}

Package=<3>
{{{
}}}

###############################################################################

]]
	end


--
-- Executable depending on a static library.
--

	function suite.exeAndLib()
		addPackageB("StaticLib")
		captureDsw()
		test.capture [[
Microsoft Developer Studio Workspace File, Format Version 6.00
# WARNING: DO NOT EDIT OR DELETE THIS WORKSPACE FILE!

###############################################################################

Project: "MyPackage"=.\MyPackage.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
    Begin Project Dependency
    Project_Dep_Name PackageB
    End Project Dependency
}}}

###############################################################################

Project: "PackageB"=.\PackageB.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

###############################################################################

Global:

Package=<5>
{{{
}}}

Package=<3>
{{{
}}}

###############################################################################

]]
	end
