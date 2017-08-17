#
# Cmake instructions file
#
cmake_minimum_required(VERSION 3.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR})

include(CheckSymbolExists)
include(CheckIncludeFiles)
include(CheckCSourceCompiles)
include(CheckStructHasMember)
include(CheckFunctionExists)
include(CheckCCompilerFlag)
include(CheckCSourceRuns)
include(cmake/DetermineSystemExtension)
include(cmake/FindLibGCrypt)
include(cmake/FindNSS)
include(cmake/DetermineTargetEndianess)
include(cmake/DetermineStdCHeaders)

set(major 0)
set(minor 9)
set(micro 55)

project(libmicrohttpd LANGUAGES C VERSION ${major}.${minor}.${micro})

set(ENABLE_BAUTH          yes     CACHE BOOL "Enable basic Auth support")
set(ENABLE_DAUTH          yes     CACHE BOOL "Enable digest Auth support")
set(ENABLE_EPOLL          yes     CACHE BOOL "Enable epoll")
set(ENABLE_POLL           yes     CACHE BOOL "Enable poll")
set(ENABLE_ERROR_MSGS     yes     CACHE BOOL "Enable support for error messages")
set(ENABLE_POSTPROCESSOR  yes     CACHE BOOL "Enable postprocessor support")
set(ENABLE_HTTPS          yes     CACHE BOOL "Enable HTTPS support")
set(DISABLE_THREAD_NAMES  no      CACHE BOOL "Disable setting name on generated threads")
set(ENABLE_UPGRADE        yes     CACHE BOOL "Enable Upgrade support")
set(MHD_ITC               auto    CACHE STRING "For inter process communication choose one of pipe, socketpair, eventfd, auto")
set(ENABLE_TESTS          yes     CACHE BOOL "Enable tests build")
set(ENABLE_EXAMPLES       yes     CACHE BOOL "Enable examples build")
set(ENABLE_DOC            yes     CACHE BOOL "Enable documentation build")

if ("FreeBSD" STREQUAL "${CMAKE_SYSTEM_NAME}")
    set(FREEBSD 1)
elseif ("Linux" STREQUAL "${CMAKE_SYSTEM_NAME}")
    list(APPEND CMAKE_REQUIRED_LIBRARIES -lrt)
    set(LINUX 1)
elseif ("NetBSD" STREQUAL "${CMAKE_SYSTEM_NAME}")
    set(NETBSD 1)
elseif ("OpenBSD" STREQUAL "${CMAKE_SYSTEM_NAME}")
    set(OPENBSD 1)
elseif ("Darwin" STREQUAL "${CMAKE_SYSTEM_NAME}")
    set(OSX 1)
elseif ("SunOS" STREQUAL "${CMAKE_SYSTEM_NAME}")
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -D_REENTRANT)
    set(SOLARIS 1)
elseif ("BSD/OS" STREQUAL "${CMAKE_SYSTEM_NAME}")
    set(SOMEBSD 1)
elseif ("Windows" STREQUAL "${CMAKE_SYSTEM_NAME}")
    set(WINDOWS 1)
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -D_CRT_SECURE_NO_DEPRECATE)
    list(APPEND CMAKE_REQUIRED_LIBRARIES Ws2_32.lib odbc32.lib odbccp32.lib)
else()
    set(OTHEROS 1)
endif()

determine_system_extension()
list(APPEND CMAKE_REQUIRED_DEFINITIONS ${SystemExtensionsDefines})
determine_target_endianness(endianness)

if ("big" STREQUAL "${endianness}")
    set(WORDS_BIGENDIAN 1)
endif()

if (ENABLE_BAUTH)
    set(BAUTH_SUPPORT 1)
endif()
if (ENABLE_DAUTH)
    set(DAUTH_SUPPORT 1)
endif()
if (ENABLE_ERROR_MSGS)
    set(HAVE_MESSAGES 1)
endif()
if (ENABLE_POSTPROCESSOR)
    set(HAVE_POSTPROCESSOR 1)
endif()
if (ENABLE_UPGRADE)
    set(UPGRADE_SUPPORT 1)
endif()

if (ENABLE_HTTPS)
    set(HTTPS_SUPPORT 1)
    set(MSG_HTTPS yes)
    FindLibGCrypt()
    include(FindGnuTLS)
    set(HttpsMissingLibraries "")
    if (NOT GNUTLS_FOUND)
        list(APPEND HttpsMissingLibraries libgnutls)
    endif()
    if (NOT LIBGCRYPT_FOUND)
        list(APPEND HttpsMissingLibraries libgcrypt)
    endif()

    if (NOT "" STREQUAL "${HttpsMissingLibraries}")
        set(HTTPS_SUPPORT 0)
        set(MSG_HTTPS "no (lacking ${HttpsMissingLibraries})")
    endif()
else()
    set(MSG_HTTPS "no (disabled)")
endif()

if (ENABLE_EPOLL)
    set(MSG_EPOLL yes)
    check_symbol_exists(epoll_create "sys/epoll.h" EPOLL_SUPPORT)
    check_symbol_exists(epoll_create1 "sys/epoll.h" HAVE_EPOLL_CREATE1)
    if (NOT EPOLL_SUPPORT)
        set(MSG_EPOLL "no (platform does not support epoll)")
    endif()
else()
    set(MSG_EPOLL "no (disabled)")
endif()

if (ENABLE_POLL)
    set(MSG_POLL yes)
    if (WINDOWS)
        check_c_source_compiles("
            #include <winsock2.h>

            int main(int argc, char** argv)
            {
                WSAPOLLFD fda[2];
                WSAPoll(fda, 2, 0);

              return 0;
            }
            " HAVE_POLL
        )
    else()
        check_symbol_exists(poll "poll.h" HAVE_POLL)
        check_include_files(poll.h HAVE_POLL_H)
    endif()

    if (NOT HAVE_POLL)
        set(MSG_POLL "no (platform does not support poll)")
    endif()
else()
    set(MSG_POLL "no (disabled)")
endif()

if(APPLE AND CMAKE_OSX_ARCHITECTURES)
    # I am not sure if this mean AC_APPLE_UNIVERSAL_BUILD
    set (AC_APPLE_UNIVERSAL_BUILD 1)
endif()

check_include_files(stdio.h HAVE_STDIO_H)
check_include_files(stdlib.h HAVE_STDLIB_H)
check_include_files(string.h HAVE_STRING_H)
check_include_files(strings.h HAVE_STRINGS_H)
check_include_files(stdint.h HAVE_STDINT_H)
check_include_files(time.h HAVE_TIME_H)
check_include_files(sys/types.h HAVE_SYS_TYPES_H)
check_include_files(unistd.h HAVE_UNISTD_H)
check_include_files(wchar.h HAVE_WCHAR_H)
check_include_files(fcntl.h HAVE_FCNTL_H)

check_function_exists(accept4 HAVE_ACCEPT4)
check_include_files(arpa/inet.h HAVE_ARPA_INET_H)
if (WINDOWS)
    list(APPEND CMAKE_REQUIRED_FLAGS /WX)
endif()
check_c_source_compiles("
    #define __STDC_WANT_LIB_EXT1__ 1
    #include <time.h>
    int main(int argc, char** argv)
    {
      struct tm res;
      time_t t;
      gmtime_s (&t, &res);

      return 0;
    }
    " HAVE_C11_GMTIME_S
)
if (NOT HAVE_C11_GMTIME_S)
check_c_source_compiles("
    #include <time.h>
    int main(int argc, char** argv)
    {
      struct tm res;
      time_t t;
      gmtime_s (&res, &t);

      return 0;
    }
    " HAVE_W32_GMTIME_S
)
endif()
if (WINDOWS)
    list(REMOVE_ITEM CMAKE_REQUIRED_FLAGS /WX)
endif()
check_symbol_exists(calloc stdlib.h HAVE_CALLOC)
check_symbol_exists(clock_gettime time.h HAVE_CLOCK_GETTIME)
check_symbol_exists(clock_get_time mach/clock.h;mach/mach.h MACH_clock_get_time)
check_symbol_exists(mach_port_deallocate mach/clock.h;mach/mach.h MACH_mach_port_deallocate)
check_symbol_exists(host_get_clock_service mach/clock.h;mach/mach.h MACH_host_get_clock_service)
if (MACH_clock_get_time AND MACH_mach_port_deallocate AND MACH_host_get_clock_service)
    set(HAVE_CLOCK_GET_TIME 1)
endif()
check_symbol_exists(SOCK_NONBLOCK sys/socket.h HAVE_DECL_SOCK_NONBLOCK)
if (HAVE_DECL_SOCK_NONBLOCK)
    set(HAVE_SOCK_NONBLOCK 1)
endif()
check_include_files(stddef.h HAVE_STDDEF_H)
check_include_files(dlfcn.h HAVE_DLFCN_H)
check_include_files(endian.h HAVE_ENDIAN_H)
check_include_files(errno.h HAVE_ERRNO_H)
check_symbol_exists(fork "unistd.h" HAVE_FORK)
check_symbol_exists(fseeko "stdio.h" HAVE_FSEEKO)
check_include_files(gcrypt.h HAVE_GCRYPT_H)
check_symbol_exists(gethrtime "sys/time.h" HAVE_GETHRTIME)
check_symbol_exists(gettimeofday "sys/time.h" HAVE_GETTIMEOFDAY)
check_symbol_exists(gmtime_r "time.h" HAVE_GMTIME_R)
check_include_files(gnutls/gnutls.h HAVE_GNUTLS_GNUTLS_H)
check_include_files(inetLib.h HAVE_INETLIB_H)
check_include_files(inttypes.h HAVE_INTTYPES_H)
check_include_files(limits.h HAVE_LIMITS_H)
check_include_files(locale.h HAVE_LOCALE_H)
check_symbol_exists(lseek64 "sys/types.h;unistd.h" HAVE_LSEEK64)
check_include_files(machine/endian.h HAVE_MACHINE_ENDIAN_H)
check_include_files(machine/param.h HAVE_MACHINE_PARAM_H)
check_include_files(magic.h HAVE_MAGIC_H)
check_include_files(math.h HAVE_MATH_H)
check_symbol_exists(memmem "string.h" HAVE_MEMMEM)
check_include_files(memory.h HAVE_MEMORY_H)
check_symbol_exists(nanosleep "time.h" HAVE_NANOSLEEP)
check_include_files(netdb.h HAVE_NETDB_H)
check_include_files(netinet/in.h HAVE_NETINET_IN_H)
check_include_files(netinet/ip.h HAVE_NETINET_IP_H)
check_include_files(netinet/tcp.h HAVE_NETINET_TCP_H)
check_include_files(net/if.h HAVE_NET_IF_H)
set(old_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
if(HAVE_FCNTL_H)
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_FCNTL_H)
endif()
if(HAVE_UNISTD_H)
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_UNISTD_H)
endif()
check_c_source_compiles("
    #ifdef HAVE_FCNTL_H
    #include <fcntl.h>
    #endif
    #ifdef HAVE_UNISTD_H
    #include <unistd.h>
    #endif

    int main(int argc, char** argv)
    {
        int arr[2];
        int res;
        res = pipe2(arr, O_CLOEXEC | O_NONBLOCK);

        return 0;
    }
    " HAVE_PIPE2_FUNC
)
set(CMAKE_REQUIRED_DEFINITIONS ${old_CMAKE_REQUIRED_DEFINITIONS})
check_symbol_exists(pipe "unistd.h" HAVE_PIPE_FUNC)
check_symbol_exists(socketpair "sys/socket.h" HAVE_SOCKETPAIR_FUNC)
check_symbol_exists(pread "unistd.h" HAVE_PREAD)
check_symbol_exists(pread64 "unistd.h" HAVE_PREAD64)
check_include_files(pthread.h HAVE_PTHREAD_H)
check_include_files(pthread_np.h HAVE_PTHREAD_NP_H)
set(USE_THREADS "unknown threads")
if (HAVE_PTHREAD_H)
    set(MHD_USE_POSIX_THREADS 1)
    set(USE_THREADS posix)
else()
    check_symbol_exists(CreateThread "Windows.h" MHD_USE_W32_THREADS)
    if (MHD_USE_W32_THREADS)
        set(USE_THREADS w32)
    endif()
endif()

if (DISABLE_THREAD_NAMES)
    set(MHD_NO_THREAD_NAMES 1)
    set(MSG_THREAD_NAMES "no (disbaled)")
else()
    set(MSG_THREAD_NAMES "yes")
endif()
if (NOT HAVE_PTHREAD_H AND NOT DISABLE_THREAD_NAMES)
    set(MHD_NO_THREAD_NAMES 1)
    set(MSG_THREAD_NAMES "no (not supported by platform)")
elseif (HAVE_PTHREAD_H AND NOT DISABLE_THREAD_NAMES)
    set(old_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
    if(HAVE_PTHREAD_NP_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_PTHREAD_NP_H)
    endif()
    check_c_source_compiles("
        #include <pthread.h>
        #ifdef HAVE_PTHREAD_NP_H
        #include <pthread_np.h>
        #endif

        int main(int argc, char** argv)
        {
            pthread_attr_t thr_attr;
            pthread_attr_init(&thr_attr);
            pthread_attr_setname_np(&thr_attr, \"name\", 0);
            pthread_attr_destroy(&thr_attr);

            return 0;
        }
        " HAVE_PTHREAD_ATTR_SETNAME_NP_NETBSD
    )
    check_c_source_compiles("
        #include <pthread.h>
        #ifdef HAVE_PTHREAD_NP_H
        #include <pthread_np.h>
        #endif

        int main(int argc, char** argv)
        {
            pthread_attr_t thr_attr;
            pthread_attr_init(&thr_attr);
            pthread_attr_setname_np(&thr_attr, \"name\");
            pthread_attr_destroy(&thr_attr);

            return 0;
        }
        " HAVE_PTHREAD_ATTR_SETNAME_NP_IBMI
    )

    check_c_source_compiles("
        #include <pthread.h>
        #ifdef HAVE_PTHREAD_NP_H
        #include <pthread_np.h>
        #endif

        int main(int argc, char** argv)
        {
            int res = pthread_setname_np(pthread_self(), \"name\", 0);

            return 0;
        }
        " HAVE_PTHREAD_SETNAME_NP_NETBSD
    )
    check_c_source_compiles("
        #include <pthread.h>
        #ifdef HAVE_PTHREAD_NP_H
        #include <pthread_np.h>
        #endif

        int main(int argc, char** argv)
        {
            int res = pthread_setname_np(pthread_self(), \"name\");

            return 0;
        }
        " HAVE_PTHREAD_SETNAME_NP_GNU
    )
    check_c_source_compiles("
        #include <pthread.h>
        #ifdef HAVE_PTHREAD_NP_H
        #include <pthread_np.h>
        #endif

        int main(int argc, char** argv)
        {
            int res = pthread_setname_np(\"name\");

            return 0;
        }
        " HAVE_PTHREAD_SETNAME_NP_DARWIN
    )
    check_c_source_compiles("
        #include <pthread.h>
        #ifdef HAVE_PTHREAD_NP_H
        #include <pthread_np.h>
        #endif

        int main(int argc, char** argv)
        {
            pthread_set_name_np(pthread_self(), \"name\");

            return 0;
        }
        " HAVE_PTHREAD_SET_NAME_NP_FREEBSD
    )

    if (NOT (HAVE_PTHREAD_ATTR_SETNAME_NP_NETBSD OR HAVE_PTHREAD_ATTR_SETNAME_NP_IBMI OR HAVE_PTHREAD_SETNAME_NP_GNU OR HAVE_PTHREAD_SET_NAME_NP_FREEBSD OR HAVE_PTHREAD_SETNAME_NP_DARWIN OR HAVE_PTHREAD_SETNAME_NP_NETBSD))
        # thread names not supported by platform
        set(MHD_NO_THREAD_NAMES 1)
        set(MSG_THREAD_NAMES "no (not supported by platform)")
    else()
        set(MSG_THREAD_NAMES "yes")
    endif()

    set(CMAKE_REQUIRED_DEFINITIONS ${old_CMAKE_REQUIRED_DEFINITIONS})
endif()

check_c_source_compiles("
#include <pthread.h>
int main(int argc, char** argv)
{
  static int i = PTHREAD_PRIO_INHERIT;
  return 0;
}
" HAVE_PTHREAD_PRIO_INHERIT)

check_symbol_exists(rand "stdlib.h" HAVE_RAND)
check_function_exists(random HAVE_RANDOM)
check_symbol_exists(tsearch "search.h" HAVE_TSEARCH)
check_symbol_exists(tfind "search.h" HAVE_tfind)
check_symbol_exists(tdelete "search.h" HAVE_tdelete)
if (HAVE_TSEARCH AND HAVE_tfind AND HAVE_tdelete)
    set(HAVE_SEARCH_H 1)
endif()

check_symbol_exists(sendfile64 "sys/sendfile.h" HAVE_SENDFILE64)
check_symbol_exists(snprintf "stdio.h" HAVE_SNPRINTF)
check_struct_has_member("struct sockaddr_in" sin_len netinet/in.h HAVE_SOCKADDR_IN_SIN_LEN)
check_include_files(sockLib.h HAVE_SOCKLIB_H)
check_c_source_compiles("
#include <stdbool.h>
int main(int argc, char** argv)
{
  static bool b;
  return 0;
}
" HAVE_STDBOOL_H)
if (NOT HAVE_STDBOOL_H)
    set(bool "int")
    set(false "(0)")
    set(true "(!0)")
else()
    set(HAVE_REAL_BOOL 1)
endif()

check_include_files(sys/byteorder.h HAVE_SYS_BYTEORDER_H)
check_include_files(sys/endian.h HAVE_SYS_ENDIAN_H)
check_include_files(sys/eventfd.h HAVE_SYS_EVENTFD_H)
check_symbol_exists(eventfd "sys/eventfd.h" HAVE_EVENTFD_FUNCTION)
check_include_files(sys/ioctl.h HAVE_SYS_IOCTL_H)
check_include_files(sys/isa_defs.h HAVE_SYS_ISA_DEFS_H)
check_include_files(sys/machine.h HAVE_SYS_MACHINE_H)
check_include_files(sys/mman.h HAVE_SYS_MMAN_H)
check_include_files(sys/msg.h HAVE_SYS_MSG_H)
check_include_files(sys/param.h HAVE_SYS_PARAM_H)
check_include_files(sys/select.h HAVE_SYS_SELECT_H)
check_include_files(sys/socket.h HAVE_SYS_SOCKET_H)
check_include_files(sys/stat.h HAVE_SYS_STAT_H)
check_include_files(sys/time.h HAVE_SYS_TIME_H)
check_symbol_exists(usleep "unistd.h" HAVE_USLEEP)
check_symbol_exists(waitpid "sys/wait.h" HAVE_WAITPID)
check_include_files(winsock2.h HAVE_WINSOCK2_H)
check_include_files(ws2tcpip.h HAVE_WS2TCPIP_H)

check_c_compiler_flag(-Werror=attributes HAVE_OPTION_ERROR_ON_ATTRIBUTES)
set(PossibleInlines "")
if (HAVE_OPTION_ERROR_ON_ATTRIBUTES)
    list(APPEND PossibleInlines "inline __attribute__((always_inline))")
endif()
list(APPEND PossibleInlines __forceinline inline __inline__ __inline _inline _Inline)
foreach(PossibleInline ${PossibleInlines})
    check_c_source_compiles("
        static ${PossibleInline} int sumfn(int x, int y)
            { return x + y; }

        int main(int argc, char** argv)
            {
            int i = sumfn(1,2);
            return 0;
            }"
        HAVE_INLINE)
    if (HAVE_INLINE)
        set(INLINE_FUNC 1)
        set(_MHD_inline "static ${PossibleInline}")
        break()
    endif()
endforeach()
if (CMAKE_COMPILER_IS_GNUCC AND CMAKE_C_COMPILER_VERSION VERSION_GREATER "4.2")
    check_c_compiler_flag(-fvisibility=hidden HAVE_OPTION_VISIBILITY)
endif()
if(HAVE_OPTION_VISIBILITY)
    set(_MHD_EXTERN "__attribute__((visibility(\"default\"))) extern")
elseif(WINDOWS)
    set(_MHD_EXTERN "__declspec(dllexport) extern")
endif()

include(FindCURL)
if (CURL_FOUND)
    set(MSG_CURL "yes")
    set(MHD_REQ_CURL_VERSION "${CURL_VERSION_STRING}")
    include(FindOpenSSL)
    set(MHD_REQ_CURL_OPENSSL_VERSION "${OPENSSL_VERSION}")
    include(FindGnuTLS)
    set(MHD_REQ_CURL_GNUTLS_VERSION "${GNUTLS_VERSION_STRING}")
    FindNSS()
    set(MHD_REQ_CURL_NSS_VERSION "${NSS_VERSION}")

    set(MHD_REQ_CURL_VERSION "7.16.4") # required cURL version to run tests
    set(MHD_REQ_CURL_OPENSSL_VERSION "0.9.8") # required cURL SSL version to run tests
    set(MHD_REQ_CURL_GNUTLS_VERSION "2.8.6") # gnuTLS lib version - used in conjunction with cURL
    set(MHD_REQ_CURL_NSS_VERSION "3.12.0") # NSS lib version - used in conjunction with cURL

    set(HAVE_LIBCURL 1)
    find_program(CURL_CONFIG curl-config)
    if (CURL_CONFIG)
        execute_process(COMMAND ${CURL_CONFIG} --features OUTPUT_VARIABLE  cfs OUTPUT_STRIP_TRAILING_WHITESPACE)
        string(REGEX  REPLACE "\n\r?" ";" cfs "${cfs}")
        foreach(cf ${cfs})
            string(TOUPPER "${cf}" cf)
            set(LIBCURL_FEATURE_${cf} 1)
        endforeach()
        execute_process(COMMAND ${CURL_CONFIG} --protocols OUTPUT_VARIABLE  ps OUTPUT_STRIP_TRAILING_WHITESPACE)
        string(REGEX  REPLACE "\n\r?" ";" ps "${ps}")
        foreach(p ${ps})
            string(TOUPPER "${p}" p)
            set(LIBCURL_PROTOCOL_${p} 1)
        endforeach()
    endif()
else()
    set(MSG_CURL "no, many unit tests will not run")
endif()

set(PACKAGE "${PROJECT_NAME}")
set(PACKAGE_BUGREPORT "libmicrohttpd@gnu.org")
set(PACKAGE_NAME "GNU Libmicrohttpd")
set(PACKAGE_STRING "GNU Libmicrohttpd ${PROJECT_VERSION}")
set(PACKAGE_TARNAME "libmicrohttpd")
set(PACKAGE_URL "http://www.gnu.org/software/libmicrohttpd/")
set(PACKAGE_VERSION "${PROJECT_VERSION}")
set(PACKAGE_VERSION_MAJOR ${major})
set(PACKAGE_VERSION_MINOR ${minor})
set(PACKAGE_VERSION_SUBMINOR ${micro})
set(VERSION "${PROJECT_VERSION}")

determine_std_c_headers(STDC_HEADERS)

set(AvailableInterPorcessCommunication "")
if (WINDOWS)
    list(APPEND AvailableInterPorcessCommunication socketpair)
else()
    if (HAVE_SYS_EVENTFD_H AND HAVE_EVENTFD_FUNCTION)
        list(APPEND AvailableInterPorcessCommunication eventfd)
    endif()
    if (HAVE_PIPE2_FUNC OR HAVE_PIPE_FUNC)
        list(APPEND AvailableInterPorcessCommunication pipe)
    endif()
    if (HAVE_SOCKETPAIR_FUNC)
        list(APPEND AvailableInterPorcessCommunication socketpair)
    endif()
endif()
if ("" STREQUAL "${AvailableInterPorcessCommunication}")
    message(FATAL_ERROR "cannot find useable type of inter-thread communication")
endif()

if ("auto" STREQUAL "${MHD_ITC}")
    list(GET AvailableInterPorcessCommunication 0 MHD_ITC)
else()
    list(FIND AvailableInterPorcessCommunication "${MHD_ITC}" ITC_INDEX)
    if (ITC_INDEX GREATER -1)
        # it is already correctly set
    else()
        message(FATAL_ERROR "Requested ${MHD_ITC} inter-thread communication is not available (try auto). Available are [${AvailableInterPorcessCommunication}].")
    endif()
endif()

if("pipe" STREQUAL "${MHD_ITC}")
    set(_MHD_ITC_PIPE 1)
elseif("eventfd" STREQUAL "${MHD_ITC}")
    set(_MHD_ITC_EVENTFD 1)
elseif("socketpair" STREQUAL "${MHD_ITC}")
    set(_MHD_ITC_SOCKETPAIR 1)
else()
    message(FATAL_ERROR "Cannot find useable type of inter-thread communication. Available are [${AvailableInterPorcessCommunication}].")
endif()

if (LINUX)
    set(HAVE_LISTEN_SHUTDOWN 1)
elseif(CYGWIN OR MINGW OR WINDOWS)
    set(HAVE_LISTEN_SHUTDOWN 0)
else()
    # we must check it
    set(old_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
    if(HAVE_UNISTD_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_UNISTD_H)
    endif()
    if(HAVE_TIME_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_TIME_H)
    endif()
    if(HAVE_STRING_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_STRING_H)
    endif()
    if(HAVE_SYS_TYPES_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_SYS_TYPES_H)
    endif()
    if(HAVE_SYS_SOCKET_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_SYS_SOCKET_H)
    endif()
    if(HAVE_NETINET_IN_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_NETINET_IN_H)
    endif()
    if(HAVE_SYS_SELECT_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_SYS_SELECT_H)
    endif()
    if(HAVE_NETINET_TCP_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_NETINET_TCP_H)
    endif()
    if(HAVE_GETTIMEOFDAY)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_GETTIMEOFDAY)
    endif()
    if(HAVE_NANOSLEEP)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_NANOSLEEP)
    endif()
    if(HAVE_USLEEP)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_USLEEP)
    endif()

    check_c_source_runs([=[
        #include <stdlib.h>

        #ifdef HAVE_UNISTD_H
        #  include <unistd.h>
        #endif
        #ifdef HAVE_TIME_H
        #  include <time.h>
        #endif
        #ifdef HAVE_STRING_H
        #  include <string.h>
        #endif

        #if !defined(_WIN32) || defined(__CYGWIN__)
        #  ifdef HAVE_SYS_TYPES_H
        #    include <sys/types.h>
        #  endif
        #  ifdef HAVE_SYS_SOCKET_H
        #    include <sys/socket.h>
        #  endif
        #  ifdef HAVE_NETINET_IN_H
        #    include <netinet/in.h>
        #  endif
        #  ifdef HAVE_SYS_TIME_H
        #    include <sys/time.h>
        #  endif
        #  ifdef HAVE_SYS_SELECT_H
        #    include <sys/select.h>
        #  endif
        #  ifdef HAVE_NETINET_TCP_H
        #    include <netinet/tcp.h>
        #  endif
           typedef int MHD_socket;
        #  define MHD_INVALID_SOCKET (-1)
        #  define MHD_POSIX_SOCKETS 1
        #else
        #  include <winsock2.h>
        #  include <ws2tcpip.h>
        #  include <windows.h>
           typedef SOCKET MHD_socket;
        #  define MHD_INVALID_SOCKET (INVALID_SOCKET)
        #  define MHD_WINSOCK_SOCKETS 1
        #endif

        #include <pthread.h>

           #ifndef SHUT_RD
        #  define SHUT_RD 0
        #endif
        #ifndef SHUT_WR
        #  define SHUT_WR 1
        #endif
        #ifndef SHUT_RDWR
        #  define SHUT_RDWR 2
        #endif

        #ifndef NULL
        #  define NULL ((void*)0)
        #endif

        #ifdef HAVE_GETTIMEOFDAY
        #  if defined(_WIN32) && !defined(__CYGWIN__)
        #    undef HAVE_GETTIMEOFDAY
        #  endif
        #endif


        #ifdef HAVE_NANOSLEEP
        static const struct timespec sm_tmout = {0, 1000};
        #  define short_sleep() nanosleep(&sm_tmout, NULL)
        #elif defined(HAVE_USLEEP)
        #  define short_sleep() usleep(1)
        #else
        #  define short_sleep() (void)0
        #endif

        static volatile int going_select = 0;
        static volatile int select_ends = 0;
        static volatile int gerror = 0;
        static int timeout_mils;

        #ifndef HAVE_GETTIMEOFDAY
        static volatile long long select_elapsed_time = 0;

        static long long time_chk(void)
        {
          long long ret = time(NULL);
          if (-1 == ret)
            gerror = 4;
          return ret;
        }
        #endif


        static void* select_thrd_func(void* param)
        {
        #ifndef HAVE_GETTIMEOFDAY
          long long start, stop;
        #endif
          fd_set rs;
          struct timeval tmot = {0, 0};
          MHD_socket fd = *((MHD_socket*)param);

          FD_ZERO(&rs);
          FD_SET(fd, &rs);
          tmot.tv_usec = timeout_mils * 1000;
        #ifndef HAVE_GETTIMEOFDAY
          start = time_chk();
        #endif
          going_select = 1;
          if (0 > select ((int)(fd) + 1, &rs, NULL, NULL, &tmot))
            gerror = 5;
        #ifndef HAVE_GETTIMEOFDAY
          stop = time_chk();
          select_elapsed_time = stop - start;
        #endif
          select_ends = 1;
          return NULL;
        }


        static MHD_socket create_socket(void)
        { return socket (AF_INET, SOCK_STREAM, 0); }

        static void close_socket(MHD_socket fd)
        {
        #ifdef MHD_POSIX_SOCKETS
          close(fd);
        #else
          closesocket(fd);
        #endif
        }

        static MHD_socket
        create_socket_listen(int port)
        {
          MHD_socket fd;
          struct sockaddr_in sock_addr;
          fd = create_socket();
          if (MHD_INVALID_SOCKET == fd)
            return fd;

          memset (&sock_addr, 0, sizeof (struct sockaddr_in));
          sock_addr.sin_family = AF_INET;
          sock_addr.sin_port = htons(port);
          sock_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

          if (bind (fd, (const struct sockaddr*) &sock_addr, sizeof(sock_addr)) < 0 ||
              listen(fd, SOMAXCONN) < 0)
            {
              close_socket(fd);
              return MHD_INVALID_SOCKET;
            }
          return fd;
        }

        #ifdef HAVE_GETTIMEOFDAY
        #define diff_time(tv1, tv2) ((long long)(tv1.tv_sec-tv2.tv_sec)*10000 + (long long)(tv1.tv_usec-tv2.tv_usec)/100)
        #else
        #define diff_time(tv1, tv2) ((long long)(tv1-tv2))
        #endif

        static long long test_run_select(int timeout_millsec, int use_shutdown, long long delay_before_shutdown)
        {
          pthread_t select_thrd;
          MHD_socket fd;
        #ifdef HAVE_GETTIMEOFDAY
          struct timeval start, stop;
        #else
          long long start;
        #endif

          fd = create_socket_listen(0);
          if (MHD_INVALID_SOCKET == fd)
            return -7;
          going_select = 0;
          select_ends = 0;
          gerror = 0;
          timeout_mils = timeout_millsec;
          if (0 != pthread_create (&select_thrd, NULL, select_thrd_func, (void*)&fd))
            return -8;
          while (!going_select) {short_sleep();}
        #ifdef HAVE_GETTIMEOFDAY
          gettimeofday (&start, NULL);
        #else
          start = time_chk();
        #endif
          if (use_shutdown)
            {
        #ifdef HAVE_GETTIMEOFDAY
              struct timeval current;
              do {short_sleep(); gettimeofday(&current, NULL); } while (delay_before_shutdown > diff_time(current, start));
        #else
              while (delay_before_shutdown > time_chk() - start) {short_sleep();}
        #endif
              shutdown(fd, SHUT_RDWR);
            }
        #ifdef HAVE_GETTIMEOFDAY
          while (!select_ends) {short_sleep();}
          gettimeofday (&stop, NULL);
        #endif
          if (0 != pthread_join(select_thrd, NULL))
            return -9;
          close_socket(fd);
          if (gerror)
            return -10;
        #ifdef HAVE_GETTIMEOFDAY
          return (long long)diff_time(stop, start);
        #else
          return select_elapsed_time;
        #endif
        }

        static int test_it(void)
        {
          long long duration2;
        #ifdef HAVE_GETTIMEOFDAY
          long long duration0, duration1;
          duration0 = test_run_select(0, 0, 0);
          if (0 > duration0)
            return -duration0;

          duration1 = test_run_select(50, 0, 0);
          if (0 > duration1)
            return -duration1 + 20;

          duration2 = test_run_select(500, 1, (duration0 + duration1) / 2);
          if (0 > duration2)
            return -duration2 + 40;

          if (duration1 * 2 > duration2)
            { /* Check second time to be sure. */
              duration2 = test_run_select(500, 1, (duration0 + duration1) / 2);
              if (0 > duration2)
                return -duration2 + 60;
              if (duration1 * 2 > duration2)
                return 0;
            }
        #else
          duration2 = test_run_select(5000, 1, 2);
          if (0 > duration2)
            return -duration2 + 80;

          if (4 > duration2)
            { /* Check second time to be sure. */
              duration2 = test_run_select(5000, 1, 2);
              if (0 > duration2)
              return -duration2 + 100;
              if (4 > duration2)
                return 0;
            }
        #endif
          return 1;
        }


        static int init(void)
        {
        #ifdef MHD_WINSOCK_SOCKETS
          WSADATA wsa_data;

          if (0 != WSAStartup(MAKEWORD(2, 2), &wsa_data) || MAKEWORD(2, 2) != wsa_data.wVersion)
            {
              WSACleanup();
              return 0;
            }
        #endif /* MHD_WINSOCK_SOCKETS */
          return 1;
        }

        static void cleanup(void)
        {
        #ifdef MHD_WINSOCK_SOCKETS
          WSACleanup();
        #endif /* MHD_WINSOCK_SOCKETS */
        }

        int main(void)
        {
          int res;
          if (!init())
            return 19;

          res = test_it();

          cleanup();
          if (gerror)
            return gerror;

          return res;
        }
        ]=] HAVE_LISTEN_SHUTDOWN)

        set(CMAKE_REQUIRED_DEFINITIONS ${old_CMAKE_REQUIRED_DEFINITIONS})
endif()
if (HAVE_LISTEN_SHUTDOWN)
    set(MSG_LISTEN_SHUTDOWN yes)
else()
    set(MSG_LISTEN_SHUTDOWN no)
endif()

set(old_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
if(HAVE_NETINET_IN_H)
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_NETINET_IN_H)
endif()
if(HAVE_SYS_SOCKET_H)
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_SYS_SOCKET_H)
endif()
if(HAVE_WINSOCK2_H)
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_WINSOCK2_H)
endif()
if(HAVE_WS2TCPIP_H)
    list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_WS2TCPIP_H)
endif()
check_c_source_compiles("
    #include <stdio.h>
    #if HAVE_NETINET_IN_H
    #include <netinet/in.h>
    #endif
    #if HAVE_SYS_SOCKET_H
    #include <sys/socket.h>
    #endif
    #if HAVE_WINSOCK2_H
    #include <winsock2.h>
    #endif
    #if HAVE_WS2TCPIP_H
    #include <ws2tcpip.h>
    #endif

    int main(int argc, char** argv)
    {
        int af=AF_INET6;
        int pf=PF_INET6;
        struct sockaddr_in6 sa;
        printf(\"%d %d %p\\\\n\", af, pf, &sa);

        return 0;
    }
    " HAVE_INET6
)

if (WINDOWS)
    macro(get_WIN32_WINNT version)
        if (CMAKE_SYSTEM_VERSION)
            set(ver ${CMAKE_SYSTEM_VERSION})
            string(REGEX MATCH "^([0-9]+).([0-9])" ver ${ver})
            string(REGEX MATCH "^([0-9]+)" verMajor ${ver})
            # Check for Windows 10, b/c we'll need to convert to hex 'A'.
            if ("${verMajor}" MATCHES "10")
                set(verMajor "A")
                string(REGEX REPLACE "^([0-9]+)" ${verMajor} ver ${ver})
            endif ("${verMajor}" MATCHES "10")
            # Remove all remaining '.' characters.
            string(REPLACE "." "" ver ${ver})
            # Prepend each digit with a zero.
            string(REGEX REPLACE "([0-9A-Z])" "0\\1" ver ${ver})
            set(${version} "0x${ver}")
        endif(CMAKE_SYSTEM_VERSION)
    endmacro(get_WIN32_WINNT)

    get_WIN32_WINNT(_WIN32_WINNT)
    # fixing wrong conditionals in code that check system version instead of compiler version.
    # E.g. It is not possible to compile with MSVC 2005 on Windows 7.
    if (${MSVC_VERSION} LESS 1500)
        set(_WIN32_WINNT 0x501)
    endif()
endif()

set(CMAKE_REQUIRED_DEFINITIONS ${old_CMAKE_REQUIRED_DEFINITIONS})

configure_file(MHD_config_cmake.h.in MHD_config.h)
install(FILES MHD_config.h DESTINATION include/microhttpd PERMISSIONS OWNER_READ GROUP_READ)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib)

if (ENABLE_TESTS)
    enable_testing()
endif()

add_subdirectory(src/microhttpd)

if (ENABLE_TESTS)
    add_subdirectory(src/testcurl)
endif()
if (ENABLE_EXAMPLES)
    add_subdirectory(src/examples)
endif()
if (ENABLE_DOC)
    add_subdirectory(doc/doxygen)
endif()

if (CMAKE_CROSSCOMPILING)
    set(MSG_CROSSCOMPILING yes)
else()
    set(MSG_CROSSCOMPILING no)
endif()

message(
"\nlibmicrohttpd ${PACKAGE_VERSION} Configuration Summary:
  Cross-compiling:   ${MSG_CROSSCOMPILING}
  Operating System:  ${CMAKE_SYSTEM_NAME}
  Threading lib:     ${USE_THREADS}
  Use thread names:  ${MSG_THREAD_NAMES}
  Inter-thread comm: ${MHD_ITC}
  libcurl (testing): ${MSG_CURL}
  Target directory:  ${CMAKE_INSTALL_PREFIX}
  Shutdown of listening socket
  trigger select:    ${MSG_LISTEN_SHUTDOWN}
  Messages:          ${ENABLE_ERROR_MSGS}
  Basic auth.:       ${ENABLE_BAUTH}
  Digest auth.:      ${ENABLE_DAUTH}
  HTTP \"Upgrade\":    ${ENABLE_UPGRADE}
  Postproc:          ${ENABLE_POSTPROCESSOR}
  HTTPS support:     ${MSG_HTTPS}
  poll support:      ${MSG_POLL}
  epoll support:     ${MSG_EPOLL}
  build docs:        ${ENABLE_DOC}
  build examples:    ${ENABLE_EXAMPLES}
  build tests:       ${ENABLE_TESTS}"
 )

