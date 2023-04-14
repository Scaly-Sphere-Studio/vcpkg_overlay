# --- BUILD ---

# Find path to solution
file(GLOB solution_path "${CMAKE_CURRENT_LIST_DIR}/*.sln")
get_filename_component(solution_name ${solution_path} NAME)

set(options "")
if ("lua" IN_LIST FEATURES)
    list(APPEND options "/p:SSS_LUA=1")
endif()

# Build solution
vcpkg_clean_msbuild()
vcpkg_install_msbuild(
    SOURCE_PATH ${CMAKE_CURRENT_LIST_DIR}
    PROJECT_SUBPATH ${solution_name}
    INCLUDES_SUBPATH inc
    PLATFORM ${VCPKG_TARGET_ARCHITECTURE}
    USE_VCPKG_INTEGRATION
    ALLOW_ROOT_INCLUDES
    OPTIONS
        ${options}
)
vcpkg_copy_pdbs()

# Move includes to SSS subdirectory
file(RENAME "${CURRENT_PACKAGES_DIR}/include" "${CURRENT_PACKAGES_DIR}/include_tmp")
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/include")
file(RENAME "${CURRENT_PACKAGES_DIR}/include_tmp" "${CURRENT_PACKAGES_DIR}/include/SSS")

# --- COPYRIGHT ---


message(STATUS "Writing copyright")
# Create share folder
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/share/${PORT}")
# Write copyright file
file(WRITE "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright" "SSS use only")
