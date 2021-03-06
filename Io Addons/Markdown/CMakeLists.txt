# Base Io build system
#
# Builds the Markdown addon

# Create the _build bundle hierarchy if needed.
make_build_bundle(_build)

# Output our dynamic library to the top-level _build hierarchy
set(LIBRARY_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR}/_build/dll)

# Additional include directories
include_directories(${READLINE_INCLUDE_DIR})

# Generate the IoMarkdownInit.c file.
# Argument SHOULD ALWAYS be the exact name of the addon, case is
# important.
generate_ioinit(Markdown)

# Our library sources.
set(SRCS
	"${CMAKE_CURRENT_SOURCE_DIR}/source/IoMarkdown.c"
	"${CMAKE_CURRENT_SOURCE_DIR}/source/IoMarkdownInit.c"
)

# Now build the shared library
add_library(IoMarkdown SHARED ${SRCS})
add_dependencies(IoMarkdown iovmall)
target_link_libraries(IoMarkdown iovmall markdown)

# Install the addon to our global addons hierarchy.
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/io/addons)
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/_build DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/io/addons/Markdown)
