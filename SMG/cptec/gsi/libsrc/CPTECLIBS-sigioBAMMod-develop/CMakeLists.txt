# This is the main CMake file for NCEPLIBS-sigio.
#
# Mark Potts, Kyle Gerheiser, Ed Hartnett

cmake_minimum_required(VERSION 3.15)

file(STRINGS "VERSION" pVersion)

project(
  sigioBAMMod
  VERSION ${pVersion}
  LANGUAGES Fortran)

# ==============================================================================
# Configuração de MPI em ambiente Cray
# ==============================================================================
option(ENABLE_MPI "Enable MPI support in sigioBAMMod" ON)

if(ENABLE_MPI)
  add_compile_options($<$<COMPILE_LANGUAGE:Fortran>:-DuseMPI>)

  # Em ambiente Cray MPICH
  if(DEFINED ENV{CRAY_MPICH_DIR})
    message(STATUS "Configurando MPICH do Cray via CRAY_MPICH_DIR: $ENV{CRAY_MPICH_DIR}")
    include_directories("$ENV{CRAY_MPICH_DIR}/include")
    link_directories("$ENV{CRAY_MPICH_DIR}/lib")
  elseif(DEFINED ENV{MPICH_DIR})
    message(STATUS "Configurando MPICH via MPICH_DIR: $ENV{MPICH_DIR}")
    include_directories("$ENV{MPICH_DIR}/include")
    link_directories("$ENV{MPICH_DIR}/lib")
  else()
    find_package(MPI REQUIRED Fortran)
    include_directories(${MPI_Fortran_INCLUDE_PATH})
  endif()
endif()

include(GNUInstallDirs)

# Handle user options.
option(ENABLE_TESTS "Build pfunit tests?" OFF)
OPTION(ENABLE_DOCS "Enable generation of doxygen-based documentation." OFF)

if(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release|RelWithDebInfo|MinSizeRel)$")
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE
    "Release"
    CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

add_subdirectory(src)

if(ENABLE_TESTS)
  find_package(PFUNIT REQUIRED)
  enable_testing()
  add_subdirectory(tests)
endif()

IF(ENABLE_DOCS)
  FIND_PACKAGE(Doxygen REQUIRED)
ENDIF()
ADD_SUBDIRECTORY(docs)
