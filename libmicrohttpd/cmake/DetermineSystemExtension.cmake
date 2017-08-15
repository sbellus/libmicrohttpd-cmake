cmake_minimum_required(VERSION 3.1)

include(CheckIncludeFiles)
include(CheckCSourceCompiles)
include(CheckSymbolExists)

function(determine_x_open_source BasicIncludes XOpenSource)
        set(old_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
    set(CMAKE_REQUIRED_DEFINITIONS -D_XOPEN_SOURCE=700)

    # Check if _XOPEN_SOURCE version 700 is supported
    check_c_source_compiles("
        ${BasicIncludes}

        /* Check will be passed if ALL features are avalable
         * and failed if ANY feature is not avalable. */
        int main()
        {

        #ifndef stpncpy
          (void) stpncpy;
        #endif
        #ifndef strnlen
          (void) strnlen;
        #endif

        #if !defined(__NetBSD__) && !defined(__OpenBSD__)
        /* NetBSD and OpenBSD didn't implement wcsnlen() for some reason. */
        #ifndef wcsnlen
          (void) wcsnlen;
        #endif
        #endif

        #ifdef __CYGWIN__
        /* The only depend function on Cygwin, but missing on some other platforms */
        #ifndef strndup
          (void) strndup;
        #endif
        #endif

        #ifndef __sun
        /* illumos forget to uncomment some _XPG7 macros. */
        #ifndef renameat
          (void) renameat;
        #endif

        #ifndef getline
          (void) getline;
        #endif
        #endif /* ! __sun */

        /* gmtime_r() becomes mandatory only in POSIX.1-2008. */
        #ifndef gmtime_r
          (void) gmtime_r;
        #endif

        /* unsetenv() actually defined in POSIX.1-2001 so it
         * must be present with _XOPEN_SOURCE == 700 too. */
        #ifndef unsetenv
          (void) unsetenv;
        #endif

          return 0;
        }

        " SUPPORT_XOPEN_SOURCE_700
    )

    set(CMAKE_REQUIRED_DEFINITIONS ${old_CMAKE_REQUIRED_DEFINITIONS})

    if (SUPPORT_XOPEN_SOURCE_700)
        set(${XOpenSource} 700 PARENT_SCOPE)
        return()
    endif()

    # Check if _XOPEN_SOURCE version 600 is supported
    set(old_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
    set(CMAKE_REQUIRED_DEFINITIONS -D_XOPEN_SOURCE=600)

    check_c_source_compiles("
        ${BasicIncludes}

        /* Check will be passed if ALL features are available
         * and failed if ANY feature is not available. */
        int main()
        {

        #ifndef setenv
          (void) setenv;
        #endif

        #ifndef __NetBSD__
        #ifndef vsscanf
          (void) vsscanf;
        #endif
        #endif

        /* Availability of next features varies, but they all must be present
         * on platform with support for _XOPEN_SOURCE = 600. */

        /* vsnprintf() should be available with _XOPEN_SOURCE >= 500, but some platforms
         * provide it only with _POSIX_C_SOURCE >= 200112 (autodefined when
         * _XOPEN_SOURCE >= 600) where specification of vsnprintf() is aligned with
         * ISO C99 while others platforms defined it with even earlier standards. */
        #ifndef vsnprintf
          (void) vsnprintf;
        #endif

        /* On platforms that prefer POSIX over X/Open, fseeko() is available
         * with _POSIX_C_SOURCE >= 200112 (autodefined when _XOPEN_SOURCE >= 600).
         * On other platforms it should be available with _XOPEN_SOURCE >= 500. */
        #ifndef fseeko
          (void) fseeko;
        #endif

        /* F_GETOWN must be defined with _XOPEN_SOURCE >= 600, but some platforms
         * define it with _XOPEN_SOURCE >= 500. */
        #ifndef F_GETOWN
        #error F_GETOWN is not defined
        #endif
          return 0;
        }

        " SUPPORT_XOPEN_SOURCE_600
    )

    set(CMAKE_REQUIRED_DEFINITIONS ${old_CMAKE_REQUIRED_DEFINITIONS})

    if (SUPPORT_XOPEN_SOURCE_600)
        set(${XOpenSource} 600 PARENT_SCOPE)
        return()
    endif()

    # Check if _XOPEN_SOURCE version 500 is supported
    set(old_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
    set(CMAKE_REQUIRED_DEFINITIONS -D_XOPEN_SOURCE=500)


    check_c_source_compiles("
        ${BasicIncludes}

        /* Check will be passed if ALL features are available
         * and failed if ANY feature is not available. */
        int main()
        {
        /* It's not easy to write reliable test for _XOPEN_SOURCE = 500 as
         * platforms not always precisely follow this standard and some
         * functions are already deprecated in later standards. */

        /* Availability of next features varies, but they all must be present
         * on platform with correct support for _XOPEN_SOURCE = 500. */

        /* Mandatory with _XOPEN_SOURCE >= 500 but as XSI extension available
         * with much older standards. */
        #ifndef ftruncate
          (void) ftruncate;
        #endif

        /* Added with _XOPEN_SOURCE >= 500 but was available in some standards
         * before. XSI extension. */
        #ifndef pread
          (void) pread;
        #endif

        #ifndef __APPLE__
        /* Actually comes from XPG4v2 and must be available
         * with _XOPEN_SOURCE >= 500 as well. */
        #ifndef symlink
          (void) symlink;
        #endif

        /* Actually comes from XPG4v2 and must be available
         * with _XOPEN_SOURCE >= 500 as well. XSI extension. */
        #ifndef strdup
          (void) strdup;
        #endif
        #endif /* ! __APPLE__ */
          return 0;
        }


        " SUPPORT_XOPEN_SOURCE_500
    )

    if (SUPPORT_XOPEN_SOURCE_500)
        set(${XOpenSource} 500 PARENT_SCOPE)
        return()
    endif()

    # Check if _XOPEN_SOURCE version 1 is supported
    set(old_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
    set(CMAKE_REQUIRED_DEFINITIONS -D_XOPEN_SOURCE=1)


    check_c_source_compiles("
        ${BasicIncludes}

        int main()
        {
          return 0;
        }


        " SUPPORT_XOPEN_SOURCE_1
    )

    if (SUPPORT_XOPEN_SOURCE_1)
        set(${XOpenSource} 1 PARENT_SCOPE)
        return()
    endif()
endfunction()

#
# Macro sets following variables if headers supports them
# - _XOPEN_SOURCE             - Possible values
#                               - 700 - enable POSIX.1-2008/SUSv4 features
#                               - 600 - enable POSIX.1-2001/SUSv3 features
#                               - 500 - enable SUSv2/XPG5 features
#                               - 1 - Earlier standards are widely supported, so just define macros to maximum value which do not break headers
# - _GNU_SOURCE               - used if headers allow
# - _DARWIN_C_SOURCE          - enables additional functionality on Darwin
# - __EXTENSIONS__            - unlocks almost all interfaces on Solaris
# - _NETBSD_SOURCE            - switch on almost all headers definitions on NetBSD
# - _BSD_SOURCE               - currently used only on OpenBSD to unhide functions.
# - _TANDEM_SOURCE            - unhides most functions on NonStop OS
# - _ALL_SOURCE               - makes visible POSIX and non-POSIX symbols on z/OS, AIX and Interix
# - BasicIncludes             - basic includes supported by system
# - SystemExtensionsDefines   - variables above as defines options for compiler
#
macro(determine_system_extension)
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

    set(BasicIncludes "")
    if (HAVE_STDIO_H)
        string(APPEND BasicIncludes "#include<stdio.h>\n")
    endif()
    if (HAVE_STDLIB_H)
        string(APPEND BasicIncludes "#include<stdlib.h>\n")
    endif()
    if (HAVE_STRING_H)
        string(APPEND BasicIncludes "#include<string.h>\n")
    endif()
    if (HAVE_STRINGS_H)
        string(APPEND BasicIncludes "#include<strings.h>\n")
    endif()
    if (HAVE_STDINT_H)
        string(APPEND BasicIncludes "#include<stdint.h>\n")
    endif()
    if (HAVE_TIME_H)
        string(APPEND BasicIncludes "#include<time.h>\n")
    endif()
    if (HAVE_SYS_TYPES_H)
        string(APPEND BasicIncludes "#include<sys/types.h>\n")
    endif()
    if (HAVE_UNISTD_H)
        string(APPEND BasicIncludes "#include<unistd.h>\n")
    endif()
    if (HAVE_WCHAR_H)
        string(APPEND BasicIncludes "#include<wchar.h>\n")
    endif()
    if (HAVE_FCNTL_H)
        string(APPEND BasicIncludes "#include<fcntl.h>\n")
    endif()

    set(old_DetermineSystemExtension_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
    set(SystemExtensionsDefines "")
    set(CMAKE_REQUIRED_DEFINITIONS "")

    determine_x_open_source("${BasicIncludes}" _XOPEN_SOURCE)
    if (_XOPEN_SOURCE)
        list(APPEND SystemExtensionsDefines -D_XOPEN_SOURCE=${_XOPEN_SOURCE})
    endif()

    # check if basic includes supports _GNU_SOURCE
    set(CMAKE_REQUIRED_DEFINITIONS ${SystemExtensionsDefines} -D_GNU_SOURCE)
    check_c_source_compiles("
        ${BasicIncludes}

        int main()
        {
          return 0;
        }

        " _GNU_SOURCE
    )
    if (_GNU_SOURCE)
        list(APPEND SystemExtensionsDefines -D_GNU_SOURCE)
    endif()

    # check if basic includes supports _DARWIN_C_SOURCE for Apple
    check_symbol_exists(__APPLE__ "" IS_APPLE)
    if (IS_APPLE)
        set(CMAKE_REQUIRED_DEFINITIONS ${SystemExtensionsDefines} -D_DARWIN_C_SOURCE)
        check_c_source_compiles("
            ${BasicIncludes}

            int main()
            {
              return 0;
            }

            " _DARWIN_C_SOURCE
        )
        if (_DARWIN_C_SOURCE)
            list(APPEND SystemExtensionsDefines -D_DARWIN_C_SOURCE)
        endif()
    endif()

    # check if basic includes supports __EXTENSIONS__ for Sun
    check_symbol_exists(__sun "" IS_SUN)
    if (IS_SUN)
        set(CMAKE_REQUIRED_DEFINITIONS ${SystemExtensionsDefines} -D__EXTENSIONS__)
        check_c_source_compiles("
            ${BasicIncludes}

            int main()
            {
              return 0;
            }

            " __EXTENSIONS__
        )
        if (__EXTENSIONS__)
            list(APPEND SystemExtensionsDefines -D__EXTENSIONS__)
        endif()
    endif()

    # check if basic includes supports _NETBSD_SOURCE for NetBSD
    check_symbol_exists(__NetBSD__ "" IS_NetBSD)
    if (IS_NetBSD)
        set(CMAKE_REQUIRED_DEFINITIONS ${SystemExtensionsDefines} -D_NETBSD_SOURCE)
        check_c_source_compiles("
            ${BasicIncludes}

            int main()
            {
              return 0;
            }

            " _NETBSD_SOURCE
        )
        if (_NETBSD_SOURCE)
            list(APPEND SystemExtensionsDefines -D_NETBSD_SOURCE)
        endif()
    endif()

    # check if basic includes supports _BSD_SOURCE for OpenBSD
    check_symbol_exists(__OpenBSD__ "" IS_OpenBSD)
    if (IS_OpenBSD)
        set(CMAKE_REQUIRED_DEFINITIONS ${SystemExtensionsDefines} -D_BSD_SOURCE)
        check_c_source_compiles("
            ${BasicIncludes}

            int main()
            {
              return 0;
            }

            " _BSD_SOURCE
        )
        if (_BSD_SOURCE)
            list(APPEND SystemExtensionsDefines -D_BSD_SOURCE)
        endif()
    endif()

    # check if basic includes supports _TANDEM_SOURCE for NonStop OS
    check_symbol_exists(__TANDEM "" IS_TANDEM)
    if (IS_TANDEM)
        set(CMAKE_REQUIRED_DEFINITIONS ${SystemExtensionsDefines} -D_TANDEM_SOURCE)
        check_c_source_compiles("
            ${BasicIncludes}

            int main()
            {
              return 0;
            }

            " _TANDEM_SOURCE
        )
        if (_TANDEM_SOURCE)
            list(APPEND SystemExtensionsDefines -D_TANDEM_SOURCE)
        endif()
    endif()

    # check if basic includes supports _ALL_SOURCE for z/OS, AIX and Interix
    check_symbol_exists(__TOS_MVS__ "" IS_TOS_MVS)
    check_symbol_exists(__INTERIX "" IS_INTERIX)
    if (__INTERIX OR __TOS_MVS__)
        set(CMAKE_REQUIRED_DEFINITIONS ${SystemExtensionsDefines} -D_ALL_SOURCE)
        check_c_source_compiles("
            ${BasicIncludes}

            int main()
            {
              return 0;
            }

            " _ALL_SOURCE
        )
        if (_ALL_SOURCE)
            list(APPEND SystemExtensionsDefines -D_ALL_SOURCE)
        endif()
    endif()

    set(CMAKE_REQUIRED_DEFINITIONS ${old_DetermineSystemExtension_CMAKE_REQUIRED_DEFINITIONS})
endmacro()