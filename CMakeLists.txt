# project name
project (todo)

# the oldest stable cmake version we support
cmake_minimum_required (VERSION 2.6)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

# what to call that directory where we install data too
set (PKGDATADIR "${DATADIR}/todo")
set (EXEC_NAME "todo")
set (RELEASE_NAME "A todo.txt client")
set (VERSION "0.1")
set (VERSION_INFO "Initial version")
set (GETTEXT_PACKAGE "todo")

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED gtk+-3.0 granite gee-1.0)
add_definitions(${DEPS_CFLAGS})
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)

# make sure we use vala
include(ValaVersion)

# make sure it's the desired version of vala
ensure_vala_version("0.16" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
	src/main.vala
	src/todo.vala
	src/task.vala
	src/todo_window.vala
	src/todo_file.vala
	src/task_dialog.vala
PACKAGES
	gtk+-3.0
	granite
	gee-1.0
	posix
OPTIONS
	-X -DGETTEXT_PACKAGE="todo"
)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install our .desktop file so the Applications menu will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/todo.desktop DESTINATION ${DATADIR}/applications/)

# install translations
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/locale/de/LC_MESSAGES/todo.mo DESTINATION ${CMAKE_INSTALL_PREFIX}/share/locale/de/LC_MESSAGES)

#install icons
install(FILES icons/todo.png DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/128x218/apps)
install(FILES icons/todo.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/apps)

install (
	CODE
		"execute_process (COMMAND gtk-update-icon-cache -t -f ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)"
	CODE
		"message (STATUS \"Updated icon cache in ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor\")"
)

#install schema
include(GSettings)
add_schema("schemas/org.pantheon.todo.gschema.xml")
