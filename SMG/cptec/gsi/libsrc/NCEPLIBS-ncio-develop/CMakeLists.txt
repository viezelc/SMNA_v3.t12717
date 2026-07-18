# This is the main CMake build file for NCEPLIBS-ncio, a NOAA library
# to for reading and writing netCDF data.
#
# 2/9/21

cmake_minimum_required(VERSION 3.15)

file(STRINGS "VERSION" pVersion)

project(ncio
        VERSION ${pVersion}
        LANGUAGES Fortran)

include(GNUInstallDirs)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

if(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release|RelWithDebInfo|MinSizeRel)$")
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE
      "Release"
      CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
                                               "MinSizeRel" "RelWithDebInfo")
endif()

# --- 1. AJUSTE DE FLAGS PARA INTEL / INTEL LLVM (ifx) ---
if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel|IntelLLVM)$")
  set(CMAKE_Fortran_FLAGS "-free -convert big_endian -assume byterecl ${CMAKE_Fortran_FLAGS}")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O2")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "-ffree-form -fconvert=big-endian -funroll-loops ${CMAKE_Fortran_FLAGS}")
endif()

# --- 2. SUPORTE A MPI PARA AMBIENTE CRAY ---
if(DEFINED ENV{CRAY_MPICH_DIR})
  message(STATUS "Ambiente Cray detectado ($ENV{CRAY_MPICH_DIR}). Criando target MPI customizado.")
  
  if(NOT TARGET MPI::MPI_Fortran)
    add_library(MPI::MPI_Fortran INTERFACE IMPORTED)
    target_include_directories(MPI::MPI_Fortran INTERFACE "$ENV{CRAY_MPICH_DIR}/include")
    
    # Adiciona os diretórios de biblioteca da Cray e as bibliotecas do mpich/ofi
    target_link_directories(MPI::MPI_Fortran INTERFACE "$ENV{CRAY_MPICH_DIR}/lib")
    target_link_libraries(MPI::MPI_Fortran INTERFACE mpifort mpi)
  endif()
  
  set(MPI_Fortran_FOUND TRUE)
  set(MPI_FOUND TRUE)
else()
  # Ambiente padrão Linux fora da Cray
  find_package(MPI REQUIRED COMPONENTS Fortran)
endif()
# ----------------------------------------------------

find_package(NetCDF REQUIRED Fortran)

add_subdirectory(src)

include(CTest)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

# Determine whether or not to generate documentation.
option(ENABLE_DOCS "Enable generation of doxygen-based documentation." OFF)
if(ENABLE_DOCS)
  find_package(Doxygen REQUIRED)
  add_subdirectory(docs)
endif()
