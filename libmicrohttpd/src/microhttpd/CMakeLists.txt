#
# Cmake instructions file
#
cmake_minimum_required(VERSION 3.1)

include(ProcessorCount)

include_directories(${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}/src/microhttpd ${PROJECT_SOURCE_DIR}/src/include)

get_property(isSharedLibSupported GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS)

if(isSharedLibSupported)
    set(libraryType SHARED)
else()
    set(libraryType STATIC)
endif()

add_library(microhttpd ${libraryType}
        connection.c
        reason_phrase.c
        daemon.c
        internal.c
        memorypool.c
        mhd_mono_clock.c
        sysfdsetsize.c
        mhd_str.c
        mhd_threads.c
        mhd_sockets.c
        mhd_itc.c
        mhd_compat.c
        response.c
)

if(NOT HAVE_SEARCH_H)
    target_sources(microhttpd PRIVATE tsearch.c)
endif()

if(HAVE_POSTPROCESSOR)
    target_sources(microhttpd PRIVATE postprocessor.c)
endif()

if(DAUTH_SUPPORT)
    target_sources(microhttpd PRIVATE digestauth.c md5.c)
endif()

if(BAUTH_SUPPORT)
    target_sources(microhttpd PRIVATE basicauth.c base64.c)
endif()

if(HTTPS_SUPPORT)
    target_sources(microhttpd PRIVATE connection_https.c)
endif()

set_target_properties(microhttpd
    PROPERTIES
        # create *nix style library versions + symbolic links
        VERSION ${major}.${minor}.${micro}
        SOVERSION ${major}
        INSTALL_RPATH ""
)
target_include_directories(microhttpd PRIVATE ${PROJECT_SOURCE_DIR}/src/microhttpd ${PROJECT_SOURCE_DIR}/src/include ${PROJECT_BINARY_DIR})
target_compile_definitions(microhttpd PRIVATE ${CMAKE_REQUIRED_DEFINITIONS})
target_link_libraries(microhttpd PRIVATE ${CMAKE_REQUIRED_LIBRARIES})

if (NSS_FOUND)
    target_link_libraries(microhttpd PRIVATE ${NSS_LDFLAGS})
    target_compile_definitions(microhttpd PRIVATE ${NSS_CFLAGS_OTHER})
endif()
if (LIBGCRYPT_FOUND)
    target_link_libraries(microhttpd PRIVATE ${LIBGCRYPT_LIBRARIES})
endif()
if (GNUTLS_FOUND)
    target_link_libraries(microhttpd PRIVATE ${GNUTLS_LIBRARIES})
    target_compile_definitions(microhttpd PRIVATE ${GNUTLS_DEFINITIONS})
endif()
if (HAVE_OPTION_VISIBILITY)
    target_compile_options(microhttpd PRIVATE -fvisibility=hidden)
endif()

install(TARGETS microhttpd
    EXPORT ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib NAMELINK_SKIP
    ARCHIVE DESTINATION lib)
install(EXPORT ${PROJECT_NAME} NAMESPACE microhttpd DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY ${PROJECT_SOURCE_DIR}/src/include/ DESTINATION include/microhttpd FILES_MATCHING PATTERN *.h PATTERN .svn EXCLUDE PERMISSIONS OWNER_READ GROUP_READ)

if (ENABLE_TESTS)
    ProcessorCount(CPU_COUNT)

    if (MSVC)
        set(SOCKET_LIBS Ws2_32)
    endif()

    if (NOT MSVC)
        # it is not possible to compile test_str.c witn MSVC
        add_executable(test_str_compare test_str.c mhd_str.c)
        add_test(NAME str_compare COMMAND test_str_compare)

        add_executable(test_str_to_value test_str.c mhd_str.c)
        add_test(NAME str_to_value COMMAND test_str_to_value)
    endif()

    add_executable(test_str_token test_str_token.c mhd_str.c)
    add_test(NAME str_token COMMAND test_str_token)

    add_executable(test_http_reasons test_http_reasons.c reason_phrase.c mhd_str.c)
    add_test(NAME http_reasons COMMAND test_http_reasons)

    set(THREADS_HAVE_PTHREAD_ARG yes)
    include(FindThreads)

    add_executable(test_shutdown_select test_shutdown_select.c)
    target_link_libraries(test_shutdown_select Threads::Threads ${SOCKET_LIBS})
    target_compile_options(test_shutdown_select PRIVATE -DCPU_COUNT=${CPU_COUNT})
    add_test(NAME shutdown_select COMMAND test_shutdown_select)
    if (NOT HAVE_LISTEN_SHUTDOWN)
        set_tests_properties(shutdown_select PROPERTIES WILL_FAIL yes)
    endif()

    add_executable(test_shutdown_poll test_shutdown_select.c mhd_threads.h)
    target_link_libraries(test_shutdown_poll Threads::Threads ${SOCKET_LIBS})
    target_compile_options(test_shutdown_poll PRIVATE -DCPU_COUNT=${CPU_COUNT})
    add_test(NAME shutdown_poll COMMAND test_shutdown_poll)
    if (NOT HAVE_LISTEN_SHUTDOWN)
        set_tests_properties(shutdown_poll PROPERTIES WILL_FAIL yes)
    endif()

    add_executable(test_daemon test_daemon.c)
    target_link_libraries(test_daemon microhttpd)
    target_compile_options(test_daemon PRIVATE -DCPU_COUNT=${CPU_COUNT})
    add_test(NAME daemon COMMAND test_daemon)

    if (CMAKE_USE_PTHREADS_INIT)
        if (ENABLE_UPGRADE)
            add_executable(test_upgrade test_upgrade.c)
            target_link_libraries(test_upgrade microhttpd)
            target_compile_options(test_upgrade PRIVATE -std=c99 -DCPU_COUNT=${CPU_COUNT} ${GNUTLS_DEFINITIONS})
            add_test(NAME upgrade COMMAND test_upgrade)

            if (HTTPS_SUPPORT)
                add_executable(test_upgrade_tls test_upgrade.c test_helpers.h mhd_sockets.h)
                target_link_libraries(test_upgrade_tls microhttpd)
                target_compile_options(test_upgrade_tls PRIVATE -std=c99 -DCPU_COUNT=${CPU_COUNT} ${GNUTLS_DEFINITIONS})
                add_test(NAME upgrade_tls COMMAND test_upgrade_tls)
            endif()
        endif()
    endif()

    if (HAVE_POSTPROCESSOR)
        if (NOT MSVC)
            # it is not possible to compile test_postprocessor.c witn MSVC
            
            add_executable(test_postprocessor test_postprocessor.c)
            target_link_libraries(test_postprocessor microhttpd)
            target_compile_options(test_postprocessor PRIVATE -DCPU_COUNT=${CPU_COUNT} ${GNUTLS_DEFINITIONS})
            add_test(NAME postprocessor COMMAND test_postprocessor)
        endif()
        
        add_executable(test_postprocessor_large test_postprocessor_large.c)
        target_link_libraries(test_postprocessor_large microhttpd)
        target_compile_options(test_postprocessor_large PRIVATE -DCPU_COUNT=${CPU_COUNT} ${GNUTLS_DEFINITIONS})
        add_test(NAME postprocessor_large COMMAND test_postprocessor_large)    
        
        add_executable(test_postprocessor_amp test_postprocessor_amp.c)
        target_link_libraries(test_postprocessor_amp microhttpd)
        target_compile_options(test_postprocessor_amp PRIVATE -DCPU_COUNT=${CPU_COUNT} ${GNUTLS_DEFINITIONS})
        add_test(NAME postprocessor_amp COMMAND test_postprocessor_amp)    
    endif()
endif() 
