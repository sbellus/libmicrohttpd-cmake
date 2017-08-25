#
# Cmake instructions file
#
cmake_minimum_required(VERSION 3.9)

if (NOT CURL_FOUND)
    return()
endif()
  
find_program(ZZUF zzuf)

if ("ZZUF-NOTFOUND" STREQUAL "${ZZUF}")
	return()
endif()

add_definitions(${LIBCURL_CPPFLAGS})
include_directories(${CURL_INCLUDE_DIRS} ${CMAKE_CURRENT_SOURCE_DIR} ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}/src/microhttpd ${PROJECT_SOURCE_DIR}/src/include)

add_executable(test_zzuf_get test_get.c)
target_link_libraries(test_zzuf_get microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_get COMMAND test_zzuf_get)

add_executable(test_zzuf_get_chunked test_get_chunked.c)
target_link_libraries(test_zzuf_get_chunked microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_get_chunked COMMAND test_zzuf_get_chunked)

add_executable(test_zzuf_post test_post.c)
target_link_libraries(test_zzuf_post microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_post COMMAND test_zzuf_post)

add_executable(test_zzuf_post_form test_post_form.c)
target_link_libraries(test_zzuf_post_form microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_post_form COMMAND test_zzuf_post_form)

add_executable(test_zzuf_put test_put.c)
target_link_libraries(test_zzuf_put microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_put COMMAND test_zzuf_put)

add_executable(test_zzuf_put_chunked test_put_chunked.c)
target_link_libraries(test_zzuf_put_chunked microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_put_chunked COMMAND test_zzuf_put_chunked)

add_executable(test_zzuf_put_large test_put_large.c)
target_link_libraries(test_zzuf_put_large microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_put_large COMMAND test_zzuf_put_large)

add_executable(test_zzuf_large_put test_put_large.c)
target_link_libraries(test_zzuf_large_put microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_large_put COMMAND test_zzuf_large_put)

add_executable(test_zzuf_get11 test_get.c)
target_link_libraries(test_zzuf_get11 microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_get11 COMMAND test_zzuf_get11)

add_executable(test_zzuf_post11 test_post.c)
target_link_libraries(test_zzuf_post11 microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_post11 COMMAND test_zzuf_post11)

add_executable(test_zzuf_put11 test_put.c)
target_link_libraries(test_zzuf_put11 microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_put11 COMMAND test_zzuf_put11)

add_executable(test_zzuf_large_put11 test_put_large.c)
target_link_libraries(test_zzuf_large_put11 microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_large_put11 COMMAND test_zzuf_large_put11)

add_executable(test_zzuf_post_form11 test_post_form.c)
target_link_libraries(test_zzuf_post_form11 microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_post_form11 COMMAND test_zzuf_post_form11)

add_executable(test_zzuf_long_header test_long_header.c)
target_link_libraries(test_zzuf_long_header microhttpd ${CURL_LIBRARIES})
add_test(NAME zzuf_long_header COMMAND test_zzuf_long_header)