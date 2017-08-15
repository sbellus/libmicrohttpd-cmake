cmake_minimum_required(VERSION 3.1)

include(CheckIncludeFiles)
include(CheckCSourceCompiles)

#
# Macro sets following variables for fork functionality
# - HAVE_FORK
# - HAVE_FORK_WAITPID
#
macro(determine_fork)
    check_include_files(sys/types.h HAVE_SYS_TYPES_H)
    check_include_files(unistd.h HAVE_UNISTD_H)
    set(old_determine_fork_CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS})
    if (HAVE_SYS_TYPES_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_SYS_TYPES_H)
    endif()
    if (HAVE_UNISTD_H)
        list(APPEND CMAKE_REQUIRED_DEFINITIONS -DHAVE_UNISTD_H)
    endif()

    check_c_source_compiles("
        #ifdef HAVE_SYS_TYPES_H
        #include <sys/types.h>
        #endif
        #ifdef HAVE_UNISTD_H
        #include <unistd.h>
        #endif

        int main(int argc, char** argv)
        {
          pid_t p = fork ();
          if (0 == p) return 1;

          return 0;
        }
        " HAVE_FORK
    )

    if (HAVE_FORK)
        check_c_source_compiles("
            #ifdef HAVE_SYS_TYPES_H
            #include <sys/types.h>
            #endif
            #ifdef HAVE_UNISTD_H
            #include <unistd.h>
            #endif
            #include <sys/wait.h>

            int main(int argc, char** argv)
            {
              pid_t p = fork ();
              if (0 == p) return 1;

              waitpid (p, (void*)0, 0);

              return 0;
            }
            " HAVE_FORK_WAITPID
        )
    endif()

    set(CMAKE_REQUIRED_DEFINITIONS ${old_determine_fork_CMAKE_REQUIRED_DEFINITIONS})
endmacro()