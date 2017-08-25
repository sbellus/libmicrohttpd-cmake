#
# Cmake instructions file
#
cmake_minimum_required(VERSION 3.9)

include(ProcessorCount)
include(cmake/FindLibMagic)

ProcessorCount(CPU_COUNT)
add_definitions(-DCPU_COUNT=${CPU_COUNT} -DDATA_DIR="${PROJECT_SOURCE_DIR}/src/datadir")
include_directories(${PROJECT_SOURCE_DIR}/src/include ${PROJECT_BINARY_DIR})

add_executable(benchmark benchmark.c)
target_link_libraries(benchmark microhttpd)

add_executable(benchmark_https benchmark_https.c)
target_link_libraries(benchmark_https microhttpd)

add_executable(chunked_example chunked_example.c)
target_link_libraries(chunked_example microhttpd)

add_executable(minimal_example minimal_example.c)
target_link_libraries(minimal_example microhttpd)

add_executable(dual_stack_example dual_stack_example.c)
target_link_libraries(dual_stack_example microhttpd)

add_executable(minimal_example_comet minimal_example_comet.c)
target_link_libraries(minimal_example_comet microhttpd)

add_executable(querystring_example querystring_example.c)
target_link_libraries(querystring_example microhttpd)

add_executable(timeout timeout.c)
target_link_libraries(timeout microhttpd)

add_executable(fileserver_example fileserver_example.c)
target_link_libraries(fileserver_example microhttpd)

add_executable(fileserver_example_dirs fileserver_example_dirs.c)
target_link_libraries(fileserver_example_dirs microhttpd)

add_executable(fileserver_example_external_select fileserver_example_external_select.c)
target_link_libraries(fileserver_example_external_select microhttpd)

add_executable(refuse_post_example refuse_post_example.c)
target_link_libraries(refuse_post_example microhttpd)

if (HTTPS_SUPPORT)
    add_executable(https_fileserver_example https_fileserver_example.c)
    target_link_libraries(https_fileserver_example microhttpd)
    target_compile_definitions(https_fileserver_example PRIVATE ${GNUTLS_DEFINITIONS})
endif()

if (HAVE_POSTPROCESSOR)
    add_executable(post_example post_example.c)
    target_link_libraries(post_example microhttpd)

    FindLibMagic()
    if (LIBMAGIC_FOUND)
        add_executable(demo demo.c)
        target_link_libraries(demo microhttpd  ${LibMagic_LIBRARY})

        add_executable(demo_https demo_https.c)
        target_link_libraries(demo_https microhttpd ${LibMagic_LIBRARY})
    endif()
endif()

if (ENABLE_DAUTH)
    add_executable(digest_auth_example digest_auth_example.c)
    target_link_libraries(digest_auth_example microhttpd)
endif()

if (ENABLE_BAUTH)
    add_executable(authorization_example authorization_example.c)
    target_link_libraries(authorization_example microhttpd)
endif()

if (ENABLE_UPGRADE)
    add_executable(upgrade_example upgrade_example.c)
    target_link_libraries(upgrade_example microhttpd)
endif()