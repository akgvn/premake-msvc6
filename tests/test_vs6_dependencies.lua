--
-- test_vs6_dependencies.lua
-- Port of premake 3.x Tests/Vs6/Cpp/Test_Dependencies.cs, extended for
-- premake5-native semantics (docs/3x-to-native.md): linked siblings are
-- collected across all configurations.
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


--
-- Links set on a single configuration still produce dependencies
-- (they are unioned across all configurations).
--

	function suite.linksFromSingleConfig()
		filter "configurations:Debug"
		links { "PackageC" }
		addPackageB("StaticLib")
		local prj3 = project("PackageC")
		language "C++"
		kind "StaticLib"
		files { "other.cpp" }
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
    Begin Project Dependency
    Project_Dep_Name PackageC
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

Project: "PackageC"=.\PackageC.dsp - Package Owner=<4>

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
