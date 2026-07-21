cmake_minimum_required(VERSION 3.20)

# ==============================================================================
# Configuração para ambiente Cray (força wrappers cc/ftn com caminho absoluto)
# DEVE VIR ANTES DO COMANDO project()
# ==============================================================================
if(DEFINED ENV{CRAY_MPICH_DIR} OR DEFINED ENV{CRAYPE_DIR} OR DEFINED ENV{CRAY_CPU_TARGET})
    message(STATUS "Ambiente Cray detectado. Localizando wrappers cc e ftn...")

    # Encontra o caminho completo dos executáveis cc e ftn
    find_program(CRAY_CC cc REQUIRED)
    find_program(CRAY_FTN ftn REQUIRED)

    # Define os caminhos absolutos dos compiladores
    set(CMAKE_C_COMPILER "${CRAY_CC}" CACHE STRING "C compiler" FORCE)
    set(CMAKE_Fortran_COMPILER "${CRAY_FTN}" CACHE STRING "Fortran compiler" FORCE)

    # Informa ao FindMPI para usar os wrappers com caminho absoluto
    set(MPI_C_COMPILER "${CRAY_CC}" CACHE STRING "MPI C compiler" FORCE)
    set(MPI_Fortran_COMPILER "${CRAY_FTN}" CACHE STRING "MPI Fortran compiler" FORCE)

    # Força a aprovação do FindMPI (já que os wrappers cc/ftn linkam o MPI nativamente)
    set(MPI_C_FOUND TRUE CACHE BOOL "" FORCE)
    set(MPI_Fortran_FOUND TRUE CACHE BOOL "" FORCE)
endif()

project(GSIApp
        VERSION 1.0.0
        LANGUAGES C Fortran)

set(CMAKE_DIRECTORY_LABELS ${PROJECT_NAME})
enable_testing()
include(GNUInstallDirs)

if(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release|RelWithDebInfo|MinSizeRel)$")
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE
      "Release"
      CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Verificação de compatibilidade de compiladores (incluindo IntelLLVM)
if(NOT CMAKE_C_COMPILER_ID MATCHES "^(GNU|Intel|IntelLLVM|Clang|AppleClang)$")
  message(WARNING "${CMAKE_C_COMPILER_ID} is not supported.")
endif()

if(NOT CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU|Intel|IntelLLVM)$")
  message(WARNING "${CMAKE_Fortran_COMPILER_ID} is not supported.")
endif()

# User options
option(OPENMP "Enable OpenMP Threading" OFF)
option(ENABLE_MKL "Use MKL for LAPACK implementation (if available)" ON)
option(BUILD_NCDIAG "Build GSI NetCDF Diagnostic Library" ON)
option(BUILD_GSDCLOUD "Build GSD Cloud Analysis Library" OFF)
option(BUILD_GSI "Build GSI" ON)
option(BUILD_ENKF "Build EnKF" OFF)
option(BUILD_UTIL "Build Utilities" OFF)
option(BUILD_REG_TESTING "Build the Regression Testing Suite" OFF)

# Echo user options
message(STATUS "OPENMP ................. ${OPENMP}")
message(STATUS "ENABLE_MKL ............. ${ENABLE_MKL}")
message(STATUS "BUILD_NCDIAG ........... ${BUILD_NCDIAG}")
message(STATUS "BUILD_GSDCLOUD ......... ${BUILD_GSDCLOUD}")
message(STATUS "BUILD_GSI .............. ${BUILD_GSI}")
message(STATUS "BUILD_ENKF ............. ${BUILD_ENKF}")
message(STATUS "BUILD_UTIL ............. ${BUILD_UTIL}")
message(STATUS "BUILD_REG_TESTING ...... ${BUILD_REG_TESTING}")

# Build components
add_subdirectory(src)

if(BUILD_UTIL)
  add_subdirectory(util)
endif()

if(BUILD_REG_TESTING)
  add_subdirectory(regression)
endif()
