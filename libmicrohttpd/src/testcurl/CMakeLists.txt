#
# Cmake instructions file
#
cmake_minimum_required(VERSION 3.9)

include(ProcessorCount)
include(cmake/DetermineFork)

if (NOT CURL_FOUND)
    return()
endif()

if (HTTPS_SUPPORT)
    add_subdirectory(https)
endif()

ProcessorCount(CPU_COUNT)
add_definitions(-DCPU_COUNT=${CPU_COUNT} ${LIBCURL_CPPFLAGS})
include_directories(${CURL_INCLUDE_DIRS} ${CMAKE_CURRENT_SOURCE_DIR} ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}/src/microhttpd ${PROJECT_SOURCE_DIR}/src/include)

add_executable(test_start_stop test_start_stop.c)
target_link_libraries(test_start_stop microhttpd)
add_test(NAME start_stop COMMAND test_start_stop)

add_executable(test_get test_get.c)
target_link_libraries(test_get microhttpd ${CURL_LIBRARIES})
add_test(NAME get COMMAND test_get)

add_executable(test_get_sendfile test_get_sendfile.c)
target_link_libraries(test_get_sendfile microhttpd ${CURL_LIBRARIES})
add_test(NAME get_sendfile COMMAND test_get_sendfile)

add_executable(test_urlparse test_urlparse.c)
target_link_libraries(test_urlparse microhttpd ${CURL_LIBRARIES})
add_test(NAME urlparse COMMAND test_urlparse)

add_executable(test_delete test_delete.c)
target_link_libraries(test_delete microhttpd ${CURL_LIBRARIES})
add_test(NAME delete COMMAND test_delete)

add_executable(test_put test_put.c)
target_link_libraries(test_put microhttpd ${CURL_LIBRARIES})
add_test(NAME put COMMAND test_put)

add_executable(test_process_headers test_process_headers.c)
target_link_libraries(test_process_headers microhttpd ${CURL_LIBRARIES})
add_test(NAME process_headers COMMAND test_process_headers)

add_executable(test_process_arguments test_process_arguments.c)
target_link_libraries(test_process_arguments microhttpd ${CURL_LIBRARIES})
add_test(NAME process_arguments COMMAND test_process_arguments)

add_executable(test_parse_cookies test_parse_cookies.c)
target_link_libraries(test_parse_cookies microhttpd ${CURL_LIBRARIES})
add_test(NAME parse_cookies COMMAND test_parse_cookies)

add_executable(test_large_put test_large_put.c)
target_link_libraries(test_large_put microhttpd ${CURL_LIBRARIES})
add_test(NAME large_put COMMAND test_large_put)

add_executable(test_get11 test_get.c)
target_link_libraries(test_get11 microhttpd ${CURL_LIBRARIES})
add_test(NAME get11 COMMAND test_get11)

add_executable(test_get_sendfile11 test_get_sendfile.c)
target_link_libraries(test_get_sendfile11 microhttpd ${CURL_LIBRARIES})
add_test(NAME get_sendfile11 COMMAND test_get_sendfile11)

add_executable(test_put11 test_put.c)
target_link_libraries(test_put11 microhttpd ${CURL_LIBRARIES})
add_test(NAME put11 COMMAND test_put11)

add_executable(test_large_put11 test_large_put.c)
target_link_libraries(test_large_put11 microhttpd ${CURL_LIBRARIES})
add_test(NAME large_put11 COMMAND test_large_put11)

add_executable(test_large_put_inc11 test_large_put.c)
target_link_libraries(test_large_put_inc11 microhttpd ${CURL_LIBRARIES})
add_test(NAME large_put_inc11 COMMAND test_large_put_inc11)

add_executable(test_long_header test_long_header.c)
target_link_libraries(test_long_header microhttpd ${CURL_LIBRARIES})
add_test(NAME long_header COMMAND test_long_header)

add_executable(test_long_header11 test_long_header.c)
target_link_libraries(test_long_header11 microhttpd ${CURL_LIBRARIES})
add_test(NAME long_header11 COMMAND test_long_header11)

add_executable(test_get_chunked test_get_chunked.c)
target_link_libraries(test_get_chunked microhttpd ${CURL_LIBRARIES})
add_test(NAME get_chunked COMMAND test_get_chunked)

add_executable(test_put_chunked test_put_chunked.c)
target_link_libraries(test_put_chunked microhttpd ${CURL_LIBRARIES})
add_test(NAME test_put_chunked COMMAND test_put_chunked)

add_executable(test_iplimit11 test_iplimit.c)
target_link_libraries(test_iplimit11 microhttpd ${CURL_LIBRARIES})
add_test(NAME iplimit11 COMMAND test_iplimit11)

add_executable(test_termination test_termination.c)
target_link_libraries(test_termination microhttpd ${CURL_LIBRARIES})
add_test(NAME termination COMMAND test_termination)

add_executable(test_timeout test_timeout.c)
target_link_libraries(test_timeout microhttpd ${CURL_LIBRARIES})
add_test(NAME timeout COMMAND test_timeout)

add_executable(test_callback test_callback.c)
target_link_libraries(test_callback microhttpd ${CURL_LIBRARIES})
add_test(NAME callback COMMAND test_callback)

add_executable(perf_get perf_get.c)
target_link_libraries(perf_get microhttpd ${CURL_LIBRARIES})
add_test(NAME perf_get COMMAND perf_get)

find_program(HAVE_CURL_BINARY curl)
determine_fork()
if (HAVE_FORK_WAITPID AND HAVE_CURL_BINARY)
    add_executable(test_get_response_cleanup test_get_response_cleanup.c)
    target_link_libraries(test_get_response_cleanup microhttpd)
    add_test(NAME get_response_cleanup COMMAND test_get_response_cleanup)
endif()

set(THREADS_HAVE_PTHREAD_ARG yes)
include(FindThreads)

if (CMAKE_USE_PTHREADS_INIT)
    add_executable(test_quiesce test_quiesce.c)
    target_link_libraries(test_quiesce microhttpd Threads::Threads ${CURL_LIBRARIES})
    add_test(NAME quiesce COMMAND test_quiesce)

    add_executable(test_concurrent_stop test_concurrent_stop.c)
    target_link_libraries(test_concurrent_stop microhttpd Threads::Threads ${CURL_LIBRARIES})
    add_test(NAME concurrent_stop COMMAND test_concurrent_stop)

    add_executable(perf_get_concurrent perf_get_concurrent.c)
    target_link_libraries(perf_get_concurrent microhttpd Threads::Threads ${CURL_LIBRARIES})
    add_test(NAME perf_get_concurrent COMMAND perf_get_concurrent)
endif()

if (HAVE_CURL_BINARY)
    add_executable(test_quiesce_stream test_quiesce_stream.c)
    target_link_libraries(test_quiesce_stream microhttpd)
    add_test(NAME quiesce_stream COMMAND test_quiesce_stream)
endif()

if (HAVE_POSTPROCESSOR)
    add_executable(test_post test_post.c)
    target_link_libraries(test_post microhttpd ${CURL_LIBRARIES})
    add_test(NAME post COMMAND test_post)

    add_executable(test_postform test_postform.c)
    target_link_libraries(test_postform microhttpd ${CURL_LIBRARIES})
    add_test(NAME postform COMMAND test_postform)

    add_executable(test_post_loop test_post_loop.c)
    target_link_libraries(test_post_loop microhttpd ${CURL_LIBRARIES})
    add_test(NAME post_loop COMMAND test_post_loop)

    add_executable(test_post11 test_post.c)
    target_link_libraries(test_post11 microhttpd ${CURL_LIBRARIES})
    add_test(NAME post11 COMMAND test_post11)

    add_executable(test_postform11 test_postform.c)
    target_link_libraries(test_postform11 microhttpd ${CURL_LIBRARIES})
    add_test(NAME postform11 COMMAND test_postform11)

    add_executable(test_post_loop11 test_post_loop.c)
    target_link_libraries(test_post_loop11 microhttpd ${CURL_LIBRARIES})
    add_test(NAME post_loop11 COMMAND test_post_loop11)
endif()

add_executable(test_options test_options.c)
target_link_libraries(test_options microhttpd)
add_test(NAME options COMMAND test_options)

if (ENABLE_DAUTH)
    add_executable(test_digestauth test_digestauth.c)
    target_link_libraries(test_digestauth microhttpd ${CURL_LIBRARIES})
    add_test(NAME digestauth COMMAND test_digestauth)
    
    add_executable(test_digestauth_with_arguments test_digestauth_with_arguments.c)
    target_link_libraries(test_digestauth_with_arguments microhttpd ${CURL_LIBRARIES})
    add_test(NAME digestauth_with_arguments COMMAND test_digestauth_with_arguments)
endif()

add_library(libcurl_version_check STATIC curl_version_check.c)