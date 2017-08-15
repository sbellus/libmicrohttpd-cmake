#
# Cmake instructions file
#
cmake_minimum_required(VERSION 3.1)

find_program(DOXYGEN_BINARY doxygen)

if ("doxygen-NOTFOUND" STREQUAL "${DOXYGEN_BINARY}")
    return()
endif()

set(HAVE_DOT yes)
configure_file(libmicrohttpd.doxy.in libmicrohttpd-full.doxy @ONLY)

add_custom_target(
    doc-doxygen-full
    COMMAND ${DOXYGEN_BINARY} ${CMAKE_CURRENT_BINARY_DIR}/libmicrohttpd-full.doxy
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

set(HAVE_DOT no)
configure_file(libmicrohttpd.doxy.in libmicrohttpd-fast.doxy @ONLY)

add_custom_target(
    doc-doxygen-fast
    COMMAND ${DOXYGEN_BINARY} ${CMAKE_CURRENT_BINARY_DIR}/libmicrohttpd-fast.doxy
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)