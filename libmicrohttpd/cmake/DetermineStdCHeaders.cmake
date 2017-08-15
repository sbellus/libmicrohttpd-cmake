cmake_minimum_required(VERSION 3.1)

include(CheckIncludeFiles)
include(CheckSymbolExists)
include(CheckCSourceRuns)

function(determine_std_c_headers result)
    check_include_files(stdlib.h HAVE_STDLIB_H)
    check_include_files(stdarg.h HAVE_STDARG_H)
    check_include_files(string.h HAVE_STRING_H)
    check_include_files(float.h HAVE_FLOAT_H)
    check_symbol_exists(memchr "string.h" HAVE_memchr)
    check_symbol_exists(free "stdlib.h" HAVE_free)


    if (HAVE_STDLIB_H AND HAVE_STDARG_H AND HAVE_STRING_H AND HAVE_FLOAT_H AND HAVE_memchr AND HAVE_free)
        if (NOT CMAKE_CROSSCOMPILING)
            check_c_source_runs("
                #include <ctype.h>
                #include <stdlib.h>
                #if ((' ' & 0x0FF) == 0x020)
                # define ISLOWER(c) ('a' <= (c) && (c) <= 'z')
                # define TOUPPER(c) (ISLOWER(c) ? 'A' + ((c) - 'a') : (c))
                #else
                # define ISLOWER(c) \
                           (('a' <= (c) && (c) <= 'i') \
                             || ('j' <= (c) && (c) <= 'r') \
                             || ('s' <= (c) && (c) <= 'z'))
                # define TOUPPER(c) (ISLOWER(c) ? ((c) | 0x40) : (c))
                #endif

                #define XOR(e, f) (((e) && !(f)) || (!(e) && (f)))
                int
                main ()
                {
                  int i;
                  for (i = 0; i < 256; i++)
                    if (XOR (islower (i), ISLOWER (i))
                    || toupper (i) != TOUPPER (i))
                      return 2;
                  return 0;
                } " STDC_SUPPORT_HIGH_BIT_CHARS)
            if (STDC_SUPPORT_HIGH_BIT_CHARS)
                set(${result} 1 PARENT_SCOPE)
            endif()
        else()
            set(${result} 1 PARENT_SCOPE)
        endif()
    endif()
endfunction()