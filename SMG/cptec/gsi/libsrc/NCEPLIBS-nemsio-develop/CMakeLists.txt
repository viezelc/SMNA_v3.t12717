# This is the main CMake file for NCEPLIBS-nemsio.
#
# Mark Potts, Kyle Gerheiser
cmake_minimum_required(VERSION 3.15)

file(STRINGS "VERSION" pVersion)

project(
  nemsio
  VERSION ${pVersion}
  LANGUAGES Fortran)

include(GNUInstallDirs)
include(CTest)

option(ENABLE_DOCS "Enable generation of doxygen-based documentation." OFF)
option(ENABLE_MPI "Enable MPI I/O with nemsio_module_mpi" ON)

if(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release|RelWithDebInfo|MinSizeRel)$")
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE
      "Release"
      CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# --- 1. AJUSTE DE FLAGS PARA INTEL / INTEL LLVM (ifx) ---
if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel|IntelLLVM)$")
  set(CMAKE_Fortran_FLAGS "-free -convert big_endian -assume byterecl ${CMAKE_Fortran_FLAGS}")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O2")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "-ffree-form -fconvert=big-endian -funroll-loops ${CMAKE_Fortran_FLAGS}")
endif()

# --- 2. SUPORTE A MPI PARA AMBIENTE CRAY / INTEL ---
if(ENABLE_MPI)
  if(DEFINED ENV{CRAY_MPICH_DIR})
    message(STATUS "Ambiente Cray detectado ($ENV{CRAY_MPICH_DIR}). Criando target MPI customizado.")

    if(NOT TARGET MPI::MPI_Fortran)
      add_library(MPI::MPI_Fortran INTERFACE IMPORTED)
      target_include_directories(MPI::MPI_Fortran INTERFACE "$ENV{CRAY_MPICH_DIR}/include")

      # Procura as bibliotecas reais presentes na pasta lib do cray-mpich
      find_library(CRAY_MPICH_LIB NAMES mpich mpifort PATHS "$ENV{CRAY_MPICH_DIR}/lib" NO_DEFAULT_PATH)

      if(CRAY_MPICH_LIB)
        target_link_libraries(MPI::MPI_Fortran INTERFACE "${CRAY_MPICH_LIB}")
      else()
        # Fallback de flags explícitas para linker Cray
        target_link_directories(MPI::MPI_Fortran INTERFACE "$ENV{CRAY_MPICH_DIR}/lib")
        target_link_libraries(MPI::MPI_Fortran INTERFACE mpich)
      endif()
    endif()

    set(MPI_Fortran_FOUND TRUE)
    set(MPI_FOUND TRUE)
  else()
    # Padrão para outros ambientes
    find_package(MPI REQUIRED COMPONENTS Fortran)
  endif()
endif()
# --------------------------------------------------

find_package(bacio 2.3.0 REQUIRED)
find_package(w3emc 2.9.0 REQUIRED)

if(bacio_VERSION GREATER_EQUAL 2.5.0)
  set(bacio_name bacio)
else()
  set(bacio_name bacio_4)
endif()

add_subdirectory(src)
add_subdirectory(utils)

if(BUILD_TESTING)
  enable_testing()
  add_subdirectory(tests)
endif()

# Determine whether or not to generate documentation.
if(ENABLE_DOCS)
  find_package(Doxygen REQUIRED)
endif()
add_subdirectory(docs)

