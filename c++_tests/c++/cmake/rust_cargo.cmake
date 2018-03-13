function (find_target_directory CACHEVAR)
  if (DEFINED ${CACHEVAR})
    message(STATUS "Cashed target path: ${${CACHEVAR}}")
    return ()
  endif ()
  set(CUR_DIR ${CMAKE_SOURCE_DIR})
  while (True)
    get_filename_component(NEW_DIR ${CUR_DIR}  DIRECTORY)
    set(TARGET_PATH "${NEW_DIR}/target")
    if (EXISTS "${TARGET_PATH}" AND IS_DIRECTORY "${TARGET_PATH}")
      message(STATUS "Found cargo's target directory: ${TARGET_PATH}")
      set(${CACHEVAR} "${TARGET_PATH}" CACHE PATH "Path to cargo's target directory with build artifacts" FORCE)
      break()
    endif ()

    if ("${NEW_DIR}" STREQUAL "${CUR_DIR}")
      message(FATAL_ERROR "Can not find cargo's target directory")
    endif ()

    set(CUR_DIR "${NEW_DIR}")
  endwhile()
endfunction()

function (required_libs_by_rust_library CACHEVAR)
  if (DEFINED ${CACHEVAR})
    message(STATUS "Cashed rust libraries: ${${CACHEVAR}}")
    return ()
  endif ()

  set(TEST_CRATE_ROOT "${CMAKE_BINARY_DIR}/rust_static_lib_cfg")
  file(MAKE_DIRECTORY "${TEST_CRATE_ROOT}")
  file(MAKE_DIRECTORY "${TEST_CRATE_ROOT}/src")
  file(WRITE "${TEST_CRATE_ROOT}/src/lib.rs" " ")
  file(WRITE "${TEST_CRATE_ROOT}/Cargo.toml" "[package]\nname = \"static_lib\"\nversion = \"0.0.1\"\nauthors = [\"\"]\n[lib]\nname = \"static_lib\"\ncrate-type = [\"staticlib\"]\n")

  execute_process(
    COMMAND ${RUSTC} ${RUST_TARGET} --crate-name static_lib src/lib.rs --crate-type staticlib  --print=native-static-libs
    OUTPUT_VARIABLE RUST_LINK_LIBRARIES_OUT
    ERROR_VARIABLE RUST_LINK_LIBRARIES_ERR
    RESULT_VARIABLE CARGO_RET
    WORKING_DIRECTORY "${TEST_CRATE_ROOT}"
    )
  if (NOT "${CARGO_RET}" STREQUAL "0")
    message(FATAL_ERROR "cargo build failed: ${RUST_LINK_LIBRARIES_ERR}")
  endif()
  set(RUST_LINK_LIBRARIES "${RUST_LINK_LIBRARIES_OUT} ${RUST_LINK_LIBRARIES_ERR}")
  string(REGEX MATCHALL "note: native-static-libs: ([\-a-zA-Z_0-9 \.]+)" RUST_LINK_LIBRARIES "${RUST_LINK_LIBRARIES}")
  string(REPLACE "note: native-static-libs: " "" RUST_LINK_LIBRARIES "${RUST_LINK_LIBRARIES}")
  if (WIN32)
    message(STATUS "Removing ms vcrt library from list")
    string(REPLACE "msvcrt.lib" "" RUST_LINK_LIBRARIES "${RUST_LINK_LIBRARIES}")
  endif ()
  separate_arguments(RUST_LINK_LIBRARIES)
  message(STATUS "rust libraries: ${RUST_LINK_LIBRARIES}")
  set(${CACHEVAR} "${RUST_LINK_LIBRARIES}" CACHE STRING "Required link libraries by rust" FORCE)
  file(REMOVE_RECURSE "${TEST_CRATE_ROOT}")
endfunction ()
