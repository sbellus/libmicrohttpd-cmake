# Based on the boost endian.hpp

set(endiandetect_c_code "
// GNU libc offers the helpful header <endian.h> which defines
// __BYTE_ORDER

#if defined (__GLIBC__)
# include <endian.h>
# if (__BYTE_ORDER == __LITTLE_ENDIAN)
#  error cmake_ENDIANNESS little
# elif (__BYTE_ORDER == __BIG_ENDIAN)
#  error cmake_ENDIANNESS big
# elif (__BYTE_ORDER == __PDP_ENDIAN)
#  error cmake_ENDIANNESS pdp
# else
#  error cmake_ENDIANNESS unknown
# endif
#elif defined(_BIG_ENDIAN) && !defined(_LITTLE_ENDIAN)
#  error cmake_ENDIANNESS big
#elif defined(_LITTLE_ENDIAN) && !defined(_BIG_ENDIAN)
#  error cmake_ENDIANNESS little
#elif defined(__sparc) || defined(__sparc__) \
   || defined(_POWER) || defined(__powerpc__) \
   || defined(__ppc__) || defined(__hpux) || defined(__hppa) \
   || defined(_MIPSEB) || defined(_POWER) \
   || defined(__s390__) || defined(__ARMEB__)
#  error cmake_ENDIANNESS big
#elif defined(__i386__) || defined(__alpha__) \
   || defined(__ia64) || defined(__ia64__) \
   || defined(_M_IX86) || defined(_M_IA64) \
   || defined(_M_ALPHA) || defined(__amd64) \
   || defined(__amd64__) || defined(_M_AMD64) \
   || defined(__x86_64) || defined(__x86_64__) \
   || defined(_M_X64) || defined(__bfin__) || defined(__ARMEL__)
#  error cmake_ENDIANNESS little
#else
#error cmake_ENDIANNESS unknown
#endif
#error cmake_ENDIANNESS unknown
")

function(determine_target_endianness output_var)
   file(WRITE "${CMAKE_BINARY_DIR}/endianess.c" "${endiandetect_c_code}")

    enable_language(C)

    # Detect the architecture in a rather creative way...
    # This compiles a small C program which is a series of ifdefs that selects a
    # particular #error preprocessor directive whose message string contains the
    # target architecture. The program will always fail to compile (both because
    # file is not a valid C program, and obviously because of the presence of the
    # #error preprocessor directives... but by exploiting the preprocessor in this
    # way, we can detect the correct target architecture even when cross-compiling,
    # since the program itself never needs to be run (only the compiler/preprocessor)
    list(APPEND configurationArgs "-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}")
    if(DEFINED CMAKE_BUILD_TYPE)
        list(APPEND configurationArgs "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
    endif()
    if(DEFINED CMAKE_TOOLCHAIN_FILE)
        list(APPEND configurationArgs "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}")
    endif()
    if(RULE_LAUNCH_COMPILE)
        list(APPEND configurationArgs "-DRULE_LAUNCH_COMPILE=${RULE_LAUNCH_COMPILE}")
    endif()
    if(RULE_LAUNCH_LINK)
        list(APPEND configurationArgs "-DRULE_LAUNCH_LINK=${RULE_LAUNCH_LINK}")
    endif()
    if(DEFINED CMAKE_MODULE_PATH)
        list(APPEND configurationArgs "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")
    endif()
    if(DEFINED CMAKE_REQUIRED_DEFINITIONS)
        string(REPLACE ";" " " crd ${CMAKE_REQUIRED_DEFINITIONS})
        list(APPEND configurationArgs "-DCMAKE_REQUIRED_DEFINITIONS=${crd}")
    endif()

    try_compile(
        run_result_unused
        "${CMAKE_BINARY_DIR}"
        "${CMAKE_BINARY_DIR}/endianess.c"
        OUTPUT_VARIABLE  ENDIANNESS
        CMAKE_FLAGS ${configurationArgs}
    )

    # Parse the architecture name from the compiler output
    string(REGEX MATCH "cmake_ENDIANNESS ([a-zA-Z0-9_]+)" ENDIANNESS "${ENDIANNESS}")

    # Get rid of the value marker leaving just the architecture name
    string(REPLACE "cmake_ENDIANNESS " "" ENDIANNESS "${ENDIANNESS}")

    # If we are compiling with an unknown endianess this variable should
    # already be set to "unknown" but in the case that it's empty (i.e. due
    # to a typo in the code), then set it to unknown
    if (NOT ENDIANNESS)
        set(ENDIANNESS unknown)
    endif()

    set(${output_var} "${ENDIANNESS}" PARENT_SCOPE)
endfunction()