#
# Cmake instructions file
#
cmake_minimum_required(VERSION 3.9)

include(ProcessorCount)
include(CheckLibraryExists)
include(cmake/DetermineFork)

if (NOT CURL_FOUND)
    return()
endif()

if (GNUTLS_FOUND)
    check_library_exists(${GNUTLS_LIBRARIES} gnutls_load_file "" HAVE_gnutls_load_file)
    check_library_exists(${GNUTLS_LIBRARIES} gnutls_privkey_import_x509_raw "" HAVE_gnutls_privkey_import_x509_raw)
    if (HAVE_gnutls_load_file AND gnutls_privkey_import_x509_raw)
        set(HAVE_GNUTLS_SNI yes)
    endif()
endif() 

ProcessorCount(CPU_COUNT)
add_definitions(-DCPU_COUNT=${CPU_COUNT} ${LIBCURL_CPPFLAGS} ${GNUTLS_DEFINITIONS} -DABS_SRCDIR="${CMAKE_CURRENT_SOURCE_DIR}")
include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}/src/microhttpd ${PROJECT_SOURCE_DIR}/src/include)

if (HAVE_GNUTLS_SNI)
    add_executable(test_https_sni test_https_sni.c tls_test_common.c)
    target_link_libraries(test_https_sni microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
    add_test(NAME https_sni COMMAND test_https_sni)
endif()

set(THREADS_HAVE_PTHREAD_ARG yes)
include(FindThreads)

if (CMAKE_USE_PTHREADS_INIT)
    add_executable(test_https_get_parallel test_https_get_parallel.c tls_test_common.c)
    target_link_libraries(test_https_get_parallel microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
    add_test(NAME https_get_parallel COMMAND test_https_get_parallel)
    
    add_executable(test_https_get_parallel_threads test_https_get_parallel_threads.c tls_test_common.c)
    target_link_libraries(test_https_get_parallel_threads microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES} Threads::Threads)
    add_test(NAME https_get_parallel_threads COMMAND test_https_get_parallel_threads)
endif()

add_executable(test_tls_options test_tls_options.c tls_test_common.c)
target_link_libraries(test_tls_options microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
add_test(NAME tls_options COMMAND test_tls_options)

add_executable(test_tls_authentication test_tls_authentication.c tls_test_common.c)
target_link_libraries(test_tls_authentication microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
add_test(NAME tls_authentication COMMAND test_tls_authentication)

add_executable(test_https_multi_daemon test_https_multi_daemon.c tls_test_common.c)
target_link_libraries(test_https_multi_daemon microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
add_test(NAME https_multi_daemon COMMAND test_https_multi_daemon)

add_executable(test_https_get test_https_get.c tls_test_common.c)
target_link_libraries(test_https_get microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
add_test(NAME https_get COMMAND test_https_get)

add_executable(test_https_get_select test_https_get_select.c tls_test_common.c)
target_link_libraries(test_https_get_select microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
add_test(NAME https_get_select COMMAND test_https_get_select)

add_executable(test_https_session_info test_https_session_info.c tls_test_common.c)
target_link_libraries(test_https_session_info microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
add_test(NAME https_session_info COMMAND test_https_session_info)

add_executable(test_https_time_out test_https_time_out.c tls_test_common.c)
target_link_libraries(test_https_time_out microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
add_test(NAME https_time_out COMMAND test_https_time_out)

add_executable(test_empty_response test_empty_response.c tls_test_common.c)
target_link_libraries(test_empty_response microhttpd libcurl_version_check ${GNUTLS_LIBRARIES} ${CURL_LIBRARIES})
add_test(NAME empty_response COMMAND test_empty_response)

