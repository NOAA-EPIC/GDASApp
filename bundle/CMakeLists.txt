# ------------------------------------------------------------------------- #
# JEDI GDAS Bundle             #
# ------------------------------------------------------------------------- #

# Check for minimim cmake requirement
cmake_minimum_required( VERSION 3.20 FATAL_ERROR )

find_package(ecbuild 3.5 REQUIRED HINTS ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/../ecbuild)


option(BUILD_INLINE "Build Inline ufs-bundle" OFF)
#find_package(FMS 2022.04 REQUIRED COMPONENTS R4 R8)

if(BUILD_GDASBUNDLE)
project(GDAS-bundle VERSION 1.0.0 LANGUAGES C CXX Fortran )
include(GNUInstallDirs)
enable_testing()


# Build type.
if(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release|RelWithDebInfo|MinSizeRel)$")
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE
      "Release"
      CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
                                               "MinSizeRel" "RelWithDebInfo")
endif()

# Find dependencies.
find_package(Python3 REQUIRED COMPONENTS Interpreter)

# Include ecbuild_bundle macro
include( ecbuild_bundle )

# Enable MPI
set( ENABLE_MPI ON CACHE BOOL "Compile with MPI" )

# Handle user options.
option(BUILD_GDASBUNDLE "Build GDAS Bundle" ON)
option(CLONE_JCSDADATA "Clone JCSDA test data repositories" OFF)
option(WORKFLOW_TESTS "Include global-workflow dependent tests" OFF)

# Depend path for non-ecbuild packages
set(DEPEND_LIB_ROOT ${CMAKE_CURRENT_BINARY_DIR}/Depends)
list(APPEND CMAKE_PREFIX_PATH ${DEPEND_LIB_ROOT})

# Library path for non-ecbuild packages
link_directories(${CMAKE_CURRENT_BINARY_DIR}/lib)

include( GNUInstallDirs )
if(APPLE)
  list( APPEND CMAKE_INSTALL_RPATH $ENV{llvm_openmp_ROOT}/lib )
endif()
list( APPEND CMAKE_INSTALL_RPATH ${CMAKE_CURRENT_BINARY_DIR}/fv3 )

# Initialize bundle
# -----------------
ecbuild_bundle_initialize()

# Build bundle source code.
  message("starting on GDASBUNDLE")
# jedi-cmake
  ecbuild_bundle( PROJECT jedicmake SOURCE "../sorc/jedicmake" )
  include( jedicmake/cmake/Functions/git_functions.cmake )

# ECMWF libraries
  option("BUNDLE_SKIP_ECKIT" "Don't build eckit" "ON" ) # Skip eckit build unless user passes -DBUNDLE_SKIP_ECKIT=OFF
  option("BUNDLE_SKIP_FCKIT" "Don't build fckit" "ON") # Skip fckit build unless user passes -DBUNDLE_SKIP_FCKIT=OFF
  option("BUNDLE_SKIP_ATLAS" "Don't build atlas" "ON") # Skip atlas build unless user passes -DBUNDLE_SKIP_ATLAS=OFF

# turn off optional OOPS toy models
  option( ENABLE_LORENZ95_MODEL "Build LORENZ95 toy model" OFF )
  option( ENABLE_QG_MODEL "Build QG toy model" OFF )

  ecbuild_bundle( PROJECT eckit GIT "https://github.com/ecmwf/eckit.git" TAG 1.16.0 )
  ecbuild_bundle( PROJECT fckit GIT "https://github.com/ecmwf/fckit.git" TAG 0.9.2 )
  ecbuild_bundle( PROJECT atlas GIT "https://github.com/ecmwf/atlas.git" TAG 0.35.0 )

# External (required) observation operators
  # TODO remove the CRTM from here and use it as a library
  #option("BUNDLE_SKIP_CRTM" "Don't build CRTM" "OFF") # Don't build crtm unless user passes -DBUNDLE_SKIP_CRTM=OFF
  #ecbuild_bundle( PROJECT crtm GIT "https://github.com/JCSDA/crtm.git"   TAG v2.4.1-jedi.1 )
  ecbuild_bundle( PROJECT crtm SOURCE "../sorc/crtm" )

# Build GSI-B
  option(BUILD_GSIBEC "Build GSI-B" OFF)
  if(BUILD_GSIBEC)
    ecbuild_bundle( PROJECT gsibec SOURCE "../sorc/gsibec" )
  endif()

# Gibbs seawater
  ecbuild_bundle( PROJECT gsw SOURCE "../sorc/gsw" )

# EMC BUFR-query library
  ecbuild_bundle( PROJECT bufr-query SOURCE "../sorc/bufr-query" )

# Core JEDI repositories
  ecbuild_bundle( PROJECT oops SOURCE "../sorc/oops" )
  ecbuild_bundle( PROJECT vader SOURCE "../sorc/vader" )
  ecbuild_bundle( PROJECT saber SOURCE "../sorc/saber" )
  option(ENABLE_IODA_DATA "Obtain ioda test data from ioda-data repository (vs tarball)" ON)
  ecbuild_bundle( PROJECT ioda SOURCE "../sorc/ioda" )
  option(ENABLE_UFO_DATA "Obtain ufo test data from ufo-data repository (vs tarball)" ON)
  ecbuild_bundle( PROJECT ufo SOURCE "../sorc/ufo" )

# FV3 dynamical core
  include(fv3-interface.cmake)
  ecbuild_bundle( PROJECT fv3 SOURCE "../sorc/fv3" )

# fv3-jedi and associated repositories
  ecbuild_bundle( PROJECT femps SOURCE "../sorc/femps" )
  ecbuild_bundle( PROJECT fv3-jedi-lm SOURCE "../sorc/fv3-jedi-lm" )
  option(ENABLE_FV3_JEDI_DATA "Obtain fv3-jedi test data from fv3-jedi-data repository (vs tarball)" ON)
  ecbuild_bundle( PROJECT fv3-jedi SOURCE "../sorc/fv3-jedi" )

# SOCA associated repositories
# TODO: Move the Icepack fork to EMC github
  set(BUILD_ICEPACK "ON" CACHE STRING "Build the icepack library")
  if ( BUILD_ICEPACK )
    ecbuild_bundle( PROJECT icepack SOURCE "../sorc/icepack" )
  endif()
  ecbuild_bundle( PROJECT soca SOURCE "../sorc/soca" )

  # Build JEDI/DA or other peripherals
  ecbuild_bundle( PROJECT gdas-utils SOURCE "../utils" )
  ecbuild_bundle( PROJECT da-utils SOURCE "../sorc/da-utils" )

# Build IODA converters
  option(BUILD_IODA_CONVERTERS "Build IODA Converters" ON)
  if(BUILD_IODA_CONVERTERS)
    ecbuild_bundle( PROJECT iodaconv SOURCE "../sorc/iodaconv" )
  endif()

# Land associated repositories
  ecbuild_bundle( PROJECT land-imsproc SOURCE "../sorc/land-imsproc" )
  ecbuild_bundle( PROJECT land-jediincr SOURCE "../sorc/land-jediincr" )

# GDASApp
  ecbuild_bundle( PROJECT gdas SOURCE "../")

# ioda, ufo, fv3-jedi, and saber test data
#---------------------------------
  if(CLONE_JCSDADATA)

   set(JCSDA_DATA_ROOT "$ENV{GDASAPP_TESTDATA}/jcsda")
   ecbuild_bundle( PROJECT ioda-data SOURCE "${JCSDA_DATA_ROOT}/ioda-data" )
   ecbuild_bundle( PROJECT ufo-data SOURCE "${JCSDA_DATA_ROOT}/ufo-data" )
   ecbuild_bundle( PROJECT fv3-jedi-data SOURCE "${JCSDA_DATA_ROOT}/fv3-jedi-data" )

  endif(CLONE_JCSDADATA)

elseif(BUILD_INLINE)
include( ExternalProject )

find_package( ecbuild 3.5 REQUIRED HINTS ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/../ecbuild)

project( ufs-bundle VERSION 1.1.0 LANGUAGES C CXX Fortran )
set(UWTOOLS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../sorc/uwtools/src)
set(UWTOOLS_REPO https://github.com/ufs-community/uwtools.git)
set(UWTOOLS_TAG "2.5.1" )
if(NOT EXISTS "${CMAKE_SOURCE_DIR}/venv/uwtools")
    # Create the activation script
    message("creating venv")
    execute_process(
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/script.sh ${CMAKE_CURRENT_SOURCE_DIR}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error)
    message(STATUS "Output of the command:\n${output}|${error}|${result}")
endif()
# Execute the activation script
message("activating venv")
execute_process(
    COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/script2.sh ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/../sorc/uwtools
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error)
message(STATUS "Output of the command:\n${output}|${error}|${result}")

#execute_process(COMMAND "pip install ." WORKING_DIRECTORY ${UWTOOLS_SOURCE_DIR} OUTPUT_VARIABLE output)
#message(STATUS "Output of the command:\n${output}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include( ecbuild_bundle )
include( GNUInstallDirs )
set(CMAKE_INSTALL_LIBDIR "lib")

set(DEPEND_LIB_ROOT ${CMAKE_CURRENT_BINARY_DIR}/Depends)
list(APPEND CMAKE_PREFIX_PATH ${DEPEND_LIB_ROOT})
message("prefix path is ${CMAKE_PREFIX_PATH}")

# Default release mode
set( ECBUILD_DEFAULT_BUILD_TYPE Release )

# Enable MPI
set( ENABLE_MPI ON CACHE BOOL "Compile with MPI")
set( ENABLE_OMP ON CACHE BOOL "Compile with OpenMP")

# Use external jedi-cmake or build in bundle
include( $ENV{jedi_cmake_ROOT}/share/jedicmake/Functions/git_functions.cmake )

# ECMWF libs
# ----------
# ecbuild_bundle( PROJECT eckit GIT "https://github.com/ecmwf/eckit.git" TAG 1.23.0 )
# ecbuild_bundle( PROJECT fckit GIT "https://github.com/ecmwf/fckit.git" TAG 0.10.1 )
# ecbuild_bundle( PROJECT atlas GIT "https://github.com/ecmwf/atlas.git" TAG 0.33.0 )

# External FMS
message("looking for fms")
find_package(FMS 2022.04 REQUIRED COMPONENTS R4 R8)
message("found fms")

# Core JEDI repositories
# ----------------------
ecbuild_bundle( PROJECT oops  GIT "https://github.com/jcsda/oops.git"  BRANCH develop)
#ecbuild_bundle( PROJECT oops  GIT "https://github.com/jcsda/oops.git"  BRANCH develop UPDATE )
ecbuild_bundle( PROJECT vader GIT "https://github.com/jcsda/vader.git" BRANCH develop UPDATE )
ecbuild_bundle( PROJECT saber GIT "https://github.com/jcsda/saber.git" BRANCH develop UPDATE )


if(UFS_APP MATCHES "^(ATMAERO)$" OR UFS_APP MATCHES "^(S2S)$" OR UFS_APP MATCHES "^(NG-GODAS)$")
  ecbuild_bundle( PROJECT gsw GIT "https://github.com/jcsda/GSW-Fortran.git" BRANCH develop UPDATE )
endif()

# Use last known working tag until issues with new pure cmake build are resolved
ecbuild_bundle( PROJECT crtm GIT "https://github.com/JCSDA/CRTMv3.git" TAG v3.1.0-skylabv7 ) # BRANCH develop UPDATE )

option(ENABLE_IODA_DATA "Obtain ioda test data from ioda-data repository (vs tarball)" ON)
ecbuild_bundle( PROJECT ioda-data GIT "https://github.com/JCSDA-internal/ioda-data.git" BRANCH develop UPDATE )
ecbuild_bundle( PROJECT ioda      GIT "https://github.com/jcsda/ioda.git"      BRANCH develop UPDATE )

option(ENABLE_UFO_DATA "Obtain ufo test data from ufo-data repository (vs tarball)" ON)
ecbuild_bundle( PROJECT ufo-data GIT "https://github.com/jcsda-internal/ufo-data.git" BRANCH develop UPDATE )
ecbuild_bundle( PROJECT ufo      GIT "https://github.com/jcsda/ufo.git"      BRANCH develop UPDATE )

# Options for building with certain models
# ----------------------------------------
set(UFS_APP "ATM" CACHE STRING "Choose the UFS Application")
set_property(CACHE UFS_APP PROPERTY STRINGS "ATM" "ATMAERO" "NG-GODAS" "S2S")
if(NOT UFS_APP MATCHES "^(ATM|ATMAERO|NG-GODAS|S2S)$")
  ecbuild_error("Valid options for -DUFS_APP are ATM|ATMAERO|NG-GODAS|S2S")
endif()
ecbuild_info("Building with UFS application: ${UFS_APP}")
set(FV3_FORECAST_MODEL "UFS")
# Warning! The ufs-weather-model configuration below compiles the
# FV3 dycore in double precision. Set FV3_PRECISION accordingly.
# If the ufs-weather-model FV3 dycore precision is changed to
# something else (e.g. via -D32BIT=ON), remember to adjust
# FV3_PRECISION and check if this configuration exists in
# fv3-jedi and fv3-jedi-linearmodel.
set(FV3_PRECISION DOUBLE CACHE STRING "Precision of FV3 core (SINGLE, DOUBLE)")

# fv3-jedi linear model
# ---------------------
ecbuild_bundle( PROJECT fv3-jedi-lm GIT "https://github.com/jcsda/fv3-jedi-linearmodel.git" BRANCH develop UPDATE )
message(INFO "CMAKE_INSTALL_LIBDIR: ${CMAKE_INSTALL_LIBDIR}")
include_directories(${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_INCLUDEDIR})
include_directories(${DEPEND_LIB_ROOT}/include_r8)
link_directories(${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR})


# Set variables for UFS clone and build
# Needed to get correct OpenMP link libraries on macOS
set(UFS_CMAKE_EXE_LINKER_FLAGS "-L${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")
find_package(FMS 2023.04 REQUIRED COMPONENTS R4 R8)
if (FV3_PRECISION MATCHES DOUBLE)
  add_library(fms ALIAS FMS::fms_r8)
elseif (FV3_PRECISION MATCHES SINGLE)
  add_library(fms ALIAS FMS::fms_r4)
endif()
find_package(OpenMP REQUIRED COMPONENTS C Fortran)
if(APPLE)
  set(UFS_CMAKE_EXE_LINKER_FLAGS "${UFS_CMAKE_EXE_LINKER_FLAGS} ${OpenMP_libomp_LIBRARY} ${OpenMP_libomp_LIBRARY}")
endif()
message (STATUS "UFS_CMAKE_EXE_LINKER_FLAGS: ${UFS_CMAKE_EXE_LINKER_FLAGS}")

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(UFS_CMAKE_BUILD_TYPE_FLAG "-DDEBUG=ON")
else()
  # MAYBE THIS SHOULD BE EMPTY SO THAT RELEASE IS USED, REPRO ISN'T REALLY SUPPORTED ANYMORE
  set(UFS_CMAKE_BUILD_TYPE_FLAG "-DREPRO=ON")
endif()

set(UFS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ufs-weather-model)
set(UFS_REPO https://github.com/ufs-community/ufs-weather-model)
set(UFS_TAG "develop" )
if(UFS_APP MATCHES "^(NG-GODAS)$")
   set(patch_command ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/patches/ng-godas.patch <SOURCE_DIR> && cd <SOURCE_DIR> && git apply ng-godas.patch)
else()
   set(patch_command ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/patches/ufs-wm.patch <SOURCE_DIR> && cd <SOURCE_DIR> && git apply ufs-wm.patch)
endif()

ExternalProject_Add(ufs-weather-model
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/ufs-weather-model
  GIT_REPOSITORY ${UFS_REPO}
  GIT_SUBMODULES_RECURSE TRUE
  GIT_TAG ${UFS_TAG}
  PATCH_COMMAND ${patch_command}
  SOURCE_DIR ${UFS_SOURCE_DIR}
  UPDATE_DISCONNECTED ON
  INSTALL_DIR ${DEPEND_LIB_ROOT}
  # DH* 20230316 turn off OpenMP for now ...
  CMAKE_ARGS -DCMAKE_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR} -DCMAKE_C_FLAGS=-fPIC -DCMAKE_Fortran_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DCCPP_SUITES=FV3_GFS_v16,FV3_GFS_v17_coupled_p8,FV3_GFS_v15p2,FV3_GFS_v17_p8 -DCMAKE_EXE_LINKER_FLAGS=${UFS_CMAKE_EXE_LINKER_FLAGS} -DCMAKE_C_COMPILER=${MPI_C_COMPILER} -DCMAKE_CXX_COMPILER=${MPI_CXX_COMPILER} -DCMAKE_Fortran_COMPILER=${MPI_Fortran_COMPILER} -DJEDI_DRIVER=ON -DCMAKE_PREFIX_PATH=${CMAKE_CURRENT_BINARY_DIR}/gsw ${UFS_CMAKE_BUILD_TYPE_FLAG} -DOPENMP=ON -DINLINE_POST=OFF -DMULTI_GASES=OFF -DMPI=ON -DAPP=${UFS_APP} -DCMAKE_INSTALL_PREFIX=${DEPEND_LIB_ROOT}
  # *DH
  INSTALL_COMMAND make install
  BUILD_ALWAYS TRUE
  )

if(UFS_APP MATCHES "^(ATMAERO)$" OR UFS_APP MATCHES "^(S2S)$" OR UFS_APP MATCHES "^(NG-GODAS)$")
  add_dependencies(ufs-weather-model gsw)
endif()
add_library( ufs IMPORTED STATIC)
add_library( ufs_aerosols IMPORTED STATIC)
add_library( aerosols_gridcomp IMPORTED STATIC)
add_library( gocart_gridcomp IMPORTED STATIC)
add_library( ca2g_gridcomp IMPORTED STATIC)
add_library( chem_shared IMPORTED STATIC)
add_library( gocart_process IMPORTED STATIC)
add_library( du2g_gridcomp IMPORTED STATIC)
add_library( ni2g_gridcomp IMPORTED STATIC)
add_library( ss2g_gridcomp IMPORTED STATIC)
add_library( su2g_gridcomp IMPORTED STATIC)
add_library( ga_environment IMPORTED STATIC)
add_library( cdeps IMPORTED STATIC)
add_library( cmeps IMPORTED STATIC)
add_library( ccpp IMPORTED STATIC)
add_library( stochastic_physics IMPORTED STATIC)
add_library( fv3atm IMPORTED STATIC)
add_library( ccppphys IMPORTED STATIC)
add_library( mom6 IMPORTED STATIC)
set_target_properties( ufs PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libufs.a )
set_target_properties( ufs_aerosols PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libUFS_Aerosols.a )
set_target_properties( aerosols_gridcomp PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libAerosol_GridComp.a )
set_target_properties( gocart_gridcomp PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libGOCART2G_GridComp.a )
set_target_properties( ca2g_gridcomp PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libCA2G_GridComp.a )
set_target_properties( chem_shared PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libChem_Shared2G.a )
set_target_properties( gocart_process PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libProcess_Library.a )
set_target_properties( du2g_gridcomp PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libDU2G_GridComp.a )
set_target_properties( ni2g_gridcomp PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libNI2G_GridComp.a )
set_target_properties( ss2g_gridcomp PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libSS2G_GridComp.a )
set_target_properties( su2g_gridcomp PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libSU2G_GridComp.a )
set_target_properties( ga_environment PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libGA_Environment.a )
set_target_properties( cdeps PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libcdeps.a )
set_target_properties( cmeps PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libcmeps.a )
set_target_properties( ccpp PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libccpp_framework.a )
set_target_properties( stochastic_physics PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libstochastic_physics.a )
set_target_properties( fv3atm PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libfv3atm.a )
set_target_properties( ccppphys PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libccpp_physics.a )
set_target_properties( mom6 PROPERTIES IMPORTED_LOCATION ${DEPEND_LIB_ROOT}/${CMAKE_INSTALL_LIBDIR}/libmom6.a )

# Additional dependencies that we can't know about because ufs-weather-model is an external project 
target_link_libraries( fv3atm INTERFACE fms )

ecbuild_bundle( PROJECT femps    GIT "https://github.com/jcsda/femps.git"    TAG 1.3.0 )
if(UFS_APP MATCHES "^(ATMAERO)$" OR UFS_APP MATCHES "^(S2S)$" OR UFS_APP MATCHES "^(ATM)$")
  option(ENABLE_FV3_JEDI_DATA "Obtain fv3-jedi test data from fv3-jedi-data repository (vs tarball)" ON)
  ecbuild_bundle( PROJECT fv3-jedi-data GIT "https://github.com/JCSDA-internal/fv3-jedi-data.git" BRANCH develop UPDATE )
  ecbuild_bundle( PROJECT fv3-jedi GIT "https://github.com/jcsda/fv3-jedi.git" BRANCH develop UPDATE )
elseif(UFS_APP MATCHES "^(NG-GODAS)$")
  ecbuild_bundle( PROJECT soca     GIT "https://github.com/jcsda/soca.git" BRANCH feature/ufs_dom_update UPDATE )
  add_dependencies(soca ufs-weather-model)
else()
  message(FATAL_ERROR "ufs-bundle unknown UFS_APP ${UFS_APP}")
endif()

# Build Doxygen documentation
# ---------------------------
option(BUILD_UFSJEDI_BUNDLE_DOC "Build documentation" OFF)
if(BUILD_UFSJEDI_BUNDLE_DOC)
   add_subdirectory( Documentation )
endif()

endif()
#
# Finalize bundle
# ---------------
ecbuild_bundle_finalize()
