# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 2.8

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list

# Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /media/share/share/Projekte/todo

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /media/share/share/Projekte/todo/cmake

# Include any dependencies generated for this target.
include CMakeFiles/todo.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/todo.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/todo.dir/flags.make

CMakeFiles/todo.dir/src/main.c.o: CMakeFiles/todo.dir/flags.make
CMakeFiles/todo.dir/src/main.c.o: src/main.c
	$(CMAKE_COMMAND) -E cmake_progress_report /media/share/share/Projekte/todo/cmake/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building C object CMakeFiles/todo.dir/src/main.c.o"
	/usr/bin/gcc  $(C_DEFINES) $(C_FLAGS) -o CMakeFiles/todo.dir/src/main.c.o   -c /media/share/share/Projekte/todo/cmake/src/main.c

CMakeFiles/todo.dir/src/main.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/todo.dir/src/main.c.i"
	/usr/bin/gcc  $(C_DEFINES) $(C_FLAGS) -E /media/share/share/Projekte/todo/cmake/src/main.c > CMakeFiles/todo.dir/src/main.c.i

CMakeFiles/todo.dir/src/main.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/todo.dir/src/main.c.s"
	/usr/bin/gcc  $(C_DEFINES) $(C_FLAGS) -S /media/share/share/Projekte/todo/cmake/src/main.c -o CMakeFiles/todo.dir/src/main.c.s

CMakeFiles/todo.dir/src/main.c.o.requires:
.PHONY : CMakeFiles/todo.dir/src/main.c.o.requires

CMakeFiles/todo.dir/src/main.c.o.provides: CMakeFiles/todo.dir/src/main.c.o.requires
	$(MAKE) -f CMakeFiles/todo.dir/build.make CMakeFiles/todo.dir/src/main.c.o.provides.build
.PHONY : CMakeFiles/todo.dir/src/main.c.o.provides

CMakeFiles/todo.dir/src/main.c.o.provides.build: CMakeFiles/todo.dir/src/main.c.o

CMakeFiles/todo.dir/src/todo.c.o: CMakeFiles/todo.dir/flags.make
CMakeFiles/todo.dir/src/todo.c.o: src/todo.c
	$(CMAKE_COMMAND) -E cmake_progress_report /media/share/share/Projekte/todo/cmake/CMakeFiles $(CMAKE_PROGRESS_2)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building C object CMakeFiles/todo.dir/src/todo.c.o"
	/usr/bin/gcc  $(C_DEFINES) $(C_FLAGS) -o CMakeFiles/todo.dir/src/todo.c.o   -c /media/share/share/Projekte/todo/cmake/src/todo.c

CMakeFiles/todo.dir/src/todo.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/todo.dir/src/todo.c.i"
	/usr/bin/gcc  $(C_DEFINES) $(C_FLAGS) -E /media/share/share/Projekte/todo/cmake/src/todo.c > CMakeFiles/todo.dir/src/todo.c.i

CMakeFiles/todo.dir/src/todo.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/todo.dir/src/todo.c.s"
	/usr/bin/gcc  $(C_DEFINES) $(C_FLAGS) -S /media/share/share/Projekte/todo/cmake/src/todo.c -o CMakeFiles/todo.dir/src/todo.c.s

CMakeFiles/todo.dir/src/todo.c.o.requires:
.PHONY : CMakeFiles/todo.dir/src/todo.c.o.requires

CMakeFiles/todo.dir/src/todo.c.o.provides: CMakeFiles/todo.dir/src/todo.c.o.requires
	$(MAKE) -f CMakeFiles/todo.dir/build.make CMakeFiles/todo.dir/src/todo.c.o.provides.build
.PHONY : CMakeFiles/todo.dir/src/todo.c.o.provides

CMakeFiles/todo.dir/src/todo.c.o.provides.build: CMakeFiles/todo.dir/src/todo.c.o

CMakeFiles/todo.dir/src/task.c.o: CMakeFiles/todo.dir/flags.make
CMakeFiles/todo.dir/src/task.c.o: src/task.c
	$(CMAKE_COMMAND) -E cmake_progress_report /media/share/share/Projekte/todo/cmake/CMakeFiles $(CMAKE_PROGRESS_3)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building C object CMakeFiles/todo.dir/src/task.c.o"
	/usr/bin/gcc  $(C_DEFINES) $(C_FLAGS) -o CMakeFiles/todo.dir/src/task.c.o   -c /media/share/share/Projekte/todo/cmake/src/task.c

CMakeFiles/todo.dir/src/task.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/todo.dir/src/task.c.i"
	/usr/bin/gcc  $(C_DEFINES) $(C_FLAGS) -E /media/share/share/Projekte/todo/cmake/src/task.c > CMakeFiles/todo.dir/src/task.c.i

CMakeFiles/todo.dir/src/task.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/todo.dir/src/task.c.s"
	/usr/bin/gcc  $(C_DEFINES) $(C_FLAGS) -S /media/share/share/Projekte/todo/cmake/src/task.c -o CMakeFiles/todo.dir/src/task.c.s

CMakeFiles/todo.dir/src/task.c.o.requires:
.PHONY : CMakeFiles/todo.dir/src/task.c.o.requires

CMakeFiles/todo.dir/src/task.c.o.provides: CMakeFiles/todo.dir/src/task.c.o.requires
	$(MAKE) -f CMakeFiles/todo.dir/build.make CMakeFiles/todo.dir/src/task.c.o.provides.build
.PHONY : CMakeFiles/todo.dir/src/task.c.o.provides

CMakeFiles/todo.dir/src/task.c.o.provides.build: CMakeFiles/todo.dir/src/task.c.o

src/main.c: todo_valac.stamp

src/todo.c: src/main.c

src/task.c: src/main.c

todo_valac.stamp: ../src/main.vala
todo_valac.stamp: ../src/todo.vala
todo_valac.stamp: ../src/task.vala
	$(CMAKE_COMMAND) -E cmake_progress_report /media/share/share/Projekte/todo/cmake/CMakeFiles $(CMAKE_PROGRESS_4)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold "Generating src/main.c;src/todo.c;src/task.c"
	/usr/bin/valac -C -b /media/share/share/Projekte/todo -d /media/share/share/Projekte/todo/cmake --pkg=gtk+-3.0 /media/share/share/Projekte/todo/src/main.vala /media/share/share/Projekte/todo/src/todo.vala /media/share/share/Projekte/todo/src/task.vala
	touch /media/share/share/Projekte/todo/cmake/todo_valac.stamp

# Object files for target todo
todo_OBJECTS = \
"CMakeFiles/todo.dir/src/main.c.o" \
"CMakeFiles/todo.dir/src/todo.c.o" \
"CMakeFiles/todo.dir/src/task.c.o"

# External object files for target todo
todo_EXTERNAL_OBJECTS =

todo: CMakeFiles/todo.dir/src/main.c.o
todo: CMakeFiles/todo.dir/src/todo.c.o
todo: CMakeFiles/todo.dir/src/task.c.o
todo: CMakeFiles/todo.dir/build.make
todo: CMakeFiles/todo.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking C executable todo"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/todo.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/todo.dir/build: todo
.PHONY : CMakeFiles/todo.dir/build

CMakeFiles/todo.dir/requires: CMakeFiles/todo.dir/src/main.c.o.requires
CMakeFiles/todo.dir/requires: CMakeFiles/todo.dir/src/todo.c.o.requires
CMakeFiles/todo.dir/requires: CMakeFiles/todo.dir/src/task.c.o.requires
.PHONY : CMakeFiles/todo.dir/requires

CMakeFiles/todo.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/todo.dir/cmake_clean.cmake
.PHONY : CMakeFiles/todo.dir/clean

CMakeFiles/todo.dir/depend: src/main.c
CMakeFiles/todo.dir/depend: src/todo.c
CMakeFiles/todo.dir/depend: src/task.c
CMakeFiles/todo.dir/depend: todo_valac.stamp
	cd /media/share/share/Projekte/todo/cmake && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /media/share/share/Projekte/todo /media/share/share/Projekte/todo /media/share/share/Projekte/todo/cmake /media/share/share/Projekte/todo/cmake /media/share/share/Projekte/todo/cmake/CMakeFiles/todo.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/todo.dir/depend

