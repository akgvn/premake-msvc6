--
-- test_vs6_paths.lua
-- Port of premake 3.x Tests/Vs6/Test_Paths.cs
--
-- Checks the project paths written into the workspace file. 3.x had
-- project.path/package.path; premake5 has workspace/project location.
-- Locations are assigned on the baked objects directly (the premake5
-- `location` field is project-scoped; the workspace has no script-level
-- location field). The module emits Windows path separators (OQ-7).
--

	local p = premake
	local suite = test.declare("vs6_paths")
	local vs6 = p.modules.vs6


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

	-- returns the baked workspace and project
	local function prepare()
		local bwks = test.getWorkspace(wks)
		local bprj = p.workspace.getproject(bwks, 1)
		return bwks, bprj
	end

	-- captures just the Project: line of the generated workspace
	local function projectline()
		local bwks, bprj = prepare()
		vs6.dsw.projectEntry(bwks, bprj)
	end


--
-- Everything in the same directory.
--

	function suite.allInSameDirectory()
		projectline()
		test.capture [[
Project: "MyPackage"=.\MyPackage.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

###############################################################################

]]
	end


--
-- Package in a subdirectory of the project.
--

	function suite.packageInSubDir()
		local bwks, bprj = prepare()
		bprj.location = path.join(bwks.location, "MySubDir")
		vs6.dsw.projectEntry(bwks, bprj)
		test.capture [[
Project: "MyPackage"=MySubDir\MyPackage.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

###############################################################################

]]
	end


--
-- Project (workspace) in a subdirectory; package at the top.
--

	function suite.projectInSubDir()
		local bwks, bprj = prepare()
		bwks.location = path.join(bprj.location, "Build")
		vs6.dsw.projectEntry(bwks, bprj)
		test.capture [[
Project: "MyPackage"=..\MyPackage.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

###############################################################################

]]
	end


--
-- Project and package in different subdirectories.
--

	function suite.bothInSubDirs()
		local bwks, bprj = prepare()
		local base = bwks.location
		bwks.location = path.join(base, "BuildDir")
		bprj.location = path.join(base, "PkgDir")
		vs6.dsw.projectEntry(bwks, bprj)
		test.capture [[
Project: "MyPackage"=..\PkgDir\MyPackage.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

###############################################################################

]]
	end


--
-- Project and package in the same subdirectory.
--

	function suite.bothInSameSubDir()
		local bwks, bprj = prepare()
		local sub = path.join(bwks.location, "Build")
		bwks.location = sub
		bprj.location = sub
		vs6.dsw.projectEntry(bwks, bprj)
		test.capture [[
Project: "MyPackage"=.\MyPackage.dsp - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

###############################################################################

]]
	end
