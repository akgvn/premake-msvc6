-- Sample workspace for vs6 E2E validation (premake 3.x syntax).
-- Exercises: all 4 kinds, Debug/Release, sibling dependencies, defines,
-- includepaths, libpaths, links, resources, pre/post-build commands.
-- See PLAN.md Step 5; oracle output committed under tests/golden/.

project.name = "Sample"
project.configs = { "Debug", "Release" }

-- core: static library
package = newpackage()
package.name = "core"
package.kind = "lib"
package.language = "c++"
package.files = { "core/core.cpp", "core/core.h" }
package.defines = { "CORE_LIB" }
package.config["Release"].buildflags = { "optimize-speed" }

-- engine: shared library with resources + build commands
package = newpackage()
package.name = "engine"
package.kind = "dll"
package.language = "c++"
package.files = { "engine/engine.cpp", "engine/engine.rc" }
package.links = { "core" }
package.defines = { "ENGINE_EXPORTS" }
package.includepaths = { "engine/include" }
package.resdefines = { "ENGINE_RES" }
package.respaths = { "engine/res" }
package.resoptions = { "/x" }
package.prebuildcommands = { "echo prebuild" }  -- ignored by vs6 (3.x parity)
package.prelinkcommands = { "echo prelink" }
package.postbuildcommands = { "echo postbuild" }
package.config["Release"].buildflags = { "optimize-speed" }

-- app: console executable, depends on engine + core
package = newpackage()
package.name = "app"
package.kind = "exe"
package.language = "c++"
package.files = { "app/main.cpp" }
package.links = { "engine", "core" }
package.includepaths = { "engine/include" }
package.libpaths = { "libs" }
package.postbuildcommands = { "echo done" }
package.config["Release"].buildflags = { "optimize-speed" }

-- tool: windowed executable, depends on core
package = newpackage()
package.name = "tool"
package.kind = "winexe"
package.language = "c++"
package.files = { "tool/winmain.cpp" }
package.links = { "core" }
package.config["Release"].buildflags = { "optimize-speed" }
