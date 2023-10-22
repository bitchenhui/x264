cmake_minimum_required(VERSION 3.6)

project(libx264)
add_definitions(-DBIT_DEPTH=8)
if(${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
    set(CLANG 1)
endif()
if(${CMAKE_CXX_COMPILER_ID} STREQUAL "Intel")
    set(INTEL_CXX 1)
endif()
if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    set(GCC 1)
endif()
if(INTEL_CXX AND UNIX)
    set(GCC 1) # treat icpc roughly like gcc
elseif(CLANG)
    set(GCC 1) # treat clang roughly like gcc
elseif(CMAKE_COMPILER_IS_GNUCXX)
    set(GCC 1)
elseif(INTEL_CXX AND WIN32)
    # treat icl roughly like MSVC
    set(MSVC 1)
endif()

include_directories(
    ./extras
    ./common
    ./encoder
    ./)

set(SOURCE_FILES
    ./common/base.h
    ./common/base.c
    ./common/bitstream.h
    ./common/bitstream.c
    ./common/cabac.h
    ./common/cabac.c
    ./common/common.h
    ./common/common.c
    ./common/cpu.h
    ./common/cpu.c
    ./common/dct.h
    ./common/dct.c
    ./common/deblock.c
    ./common/frame.h
    ./common/frame.c
    ./common/macroblock.h
    ./common/macroblock.c
    ./common/mc.h
    ./common/mc.c
    ./common/mvpred.c
    ./common/osdep.h
    ./common/osdep.c
    ./common/pixel.h
    ./common/pixel.c
    ./common/predict.h
    ./common/predict.c
    ./common/quant.h
    ./common/quant.c
    ./common/rectangle.h
    ./common/rectangle.c
    ./common/set.h
    ./common/set.c
    ./common/tables.h
    ./common/tables.c
    ./common/threadpool.h
    ./common/threadpool.c
    ./common/vlc.c
    ./encoder/analyse.h
    ./encoder/analyse.c
    ./encoder/api.c
    ./encoder/cabac.c
    ./encoder/cavlc.c
    ./encoder/encoder.c
    ./encoder/lookahead.c
    ./encoder/macroblock.h
    ./encoder/macroblock.c
    ./encoder/me.h
    ./encoder/me.c
    ./encoder/ratecontrol.h
    ./encoder/ratecontrol.c
    ./encoder/set.h
    ./encoder/set.c
    ./config.h
    ./x264.h
    ./x264_config.h)

if (WIN32)
    list(APPEND SOURCE_FILES
      ./common/win32thread.h
      ./common/win32thread.c)
endif()

if (APPLE)
    add_definitions(-DBIT_DEPTH=8)
    set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "7.0")
    if (IOS)
        add_definitions(-DTARGET_IS_IPHONE=1 -DPREFIX -DPIC)
    elseif(OSX)
        if(${CMAKE_OSX_ARCHITECTURES} STREQUAL x86_64)
            add_definitions(-DTARGET_IS_MAC=1
                            -DHAVE_SSE)
        else()
            add_definitions(-DTARGET_IS_MAC=1
                            -DPREFIX -DPIC)
        endif()
    endif()
elseif(ANDROID)
    add_definitions(-DBIT_DEPTH=8 -DPIC)
elseif(LINUX_ARCH_x86_64)
    set_source_files_properties(./common/x86/x264-avx2.c PROPERTIES COMPILE_FLAGS -mavx2)
endif()

if (GCC)
    add_compile_options(-fPIC -W -Wall)
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.8")
        #message(FATAL_ERROR "gcc version above 4.8 required")
    endif()

    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} -Wl,--gc-sections ")
    if(ANDROID)
        set(HIDDEN_SYMBOLS_FLAGS "-ffunction-sections -fdata-sections -fvisibility=hidden")
    elseif(LINUX)
        set(HIDDEN_SYMBOLS_FLAGS "-ffunction-sections -fdata-sections")
    endif()
    if (ANDROID OR LINUX)
        set(RELEASE_COMPILE_FLAGS "-D_NDEBUG -DNDEBUG -g -O3 -Wno-incompatible-pointer-types -Wno-compare-distinct-pointer-types")
        set(RELEASE_COMPILE_FLAGS "${RELEASE_COMPILE_FLAGS} ${HIDDEN_SYMBOLS_FLAGS}")
        set(DEBUG_COMPILE_FLAGS "-D_DEBUG -DDEBUG -g -O0 -funwind-tables -fno-omit-frame-pointer -fstack-protector-all")

        set(CMAKE_C_FLAGS"${CMAKE_C_FLAGS} -std=gnu99")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -rdynamic")

        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${RELEASE_COMPILE_FLAGS}")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${RELEASE_COMPILE_FLAGS}")
        set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${DEBUG_COMPILE_FLAGS}")
        set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${DEBUG_COMPILE_FLAGS}")

        if(ENABLE_ASAN)
            set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -fsanitize=address")
            set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -fsanitize=address")
            set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -fsanitize=address")
            set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fsanitize=address")
            message(STATUS "ENABLE_ASAN:" ${ENABLE_ASAN})
        endif()

        message(STATUS "CMAKE_C_FLAGS:" ${CMAKE_C_FLAGS})
    endif()
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DH264ENC_ENABLE_LOG1")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DH264ENC_ENABLE_LOG1")
endif()

set(ASM_OBJ_OUTPUT_DIR ${CMAKE_BINARY_DIR}/H264Encoder/h264encoder.dir)

# this is required because of this cmake bug
# http://www.cmake.org/Bug/print_bug_page.php?bug_id=8170
if(WIN32)
    set(SUFFIX obj)
else()
    set(SUFFIX o)
endif()

option(CMAKE_OSX_ARCHITECTURES "osx_architectures" 'arm64')
# string(REPLACE "·" " " OSX_ARCH ${CMAKE_OSX_ARCHITECTURES})
if (IOS OR ANDROID OR (OSX AND (${CMAKE_OSX_ARCHITECTURES} STREQUAL 'arm64')) OR LINUX_ARCH_AARCH64)
    enable_language(ASM)

    if (LINUX_ARCH_AARCH64)
        add_definitions(-DBIT_DEPTH=8 -DPIC -D__aarch64__)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__STRICT_ANSI__ ")
    endif()

    set(C_SRCS
        dct.h
        deblock.h
        mc.h
        mc-c.c
        pixel.h
        quant.h
        predict.h
        predict-c.c
    )

    #warning: use '.S' instead '.s' while compile asm file on android by clang.
    #because clang doesn't recognize '.s'
    set(ARM64_SRCS
        ./common/aarch64/asm.S
        ./common/aarch64/bitstream-a.S
        ./common/aarch64/cabac-a.S
        ./common/aarch64/dct-a.S
        ./common/aarch64/deblock-a.S
        ./common/aarch64/mc-a.S
        ./common/aarch64/pixel-a.S
        ./common/aarch64/predict-a.S
        ./common/aarch64/quant-a.S
    )

    if (ANDROID)
        if(${ANDROID_ABI} STREQUAL "armeabi-v7a")
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mfpu=neon")
            foreach(SRC ${C_SRCS})
                list(APPEND ASM_PRIMITIVES ./common/arm/${SRC})
            endforeach()
            set(A_SRCS ${ARM_SRCS})
            source_group(arm FILES ${ARM_SRCS})
        elseif(${ANDROID_ABI} STREQUAL "arm64-v8a")
            include_directories(./common/aarch64)
            foreach(SRC ${C_SRCS})
                list(APPEND ASM_PRIMITIVES ./common/aarch64/${SRC})
            endforeach()
            set(A_SRCS ${ARM64_SRCS})
            source_group(arm64 FILES ${ARM64_SRCS})
        endif()
    elseif(IOS OR OSX)
        foreach(SRC ${C_SRCS})
            #list(APPEND ARM_SRCS ./common/arm/${SRC})
            list(APPEND ARM64_SRCS ./common/aarch64/${SRC})
        endforeach()
        set(A_SRCS ${ARM64_SRCS})
        #source_group(arm FILES ${ARM_SRCS})
        source_group(arm64 FILES ${ARM64_SRCS})
    elseif(LINUX_ARCH_AARCH64)
        foreach(SRC ${C_SRCS})
            list(APPEND ARM64_SRCS ./common/aarch64/${SRC})
        endforeach()
        set(A_SRCS ${ARM64_SRCS})
        source_group(arm64 FILES ${ARM64_SRCS})    
    endif()

    foreach(ASM ${A_SRCS})
        if(ANDROID)
            set_property(SOURCE ${ASM} PROPERTY LANGUAGE C)
        endif()
        list(APPEND ASM_PRIMITIVES ${ASM})
    endforeach()
endif()

if (APPLE OR WIN32 OR LINUX OR ANDROID)
    if (APPLE OR LINUX_ARCH_x86_64)
        add_custom_target(x264-asm ALL DEPENDS ${ASM_PRIMITIVES})
        add_library(x264 STATIC ${SOURCE_FILES} ${ASM_PRIMITIVES})
        add_dependencies(x264 x264-asm)
    elseif(ANDROID OR LINUX_ARCH_AARCH64)
        add_library(libx264-objects OBJECT ${SOURCE_FILES} ${ASM_PRIMITIVES})
        add_library(x264 STATIC ${SOURCE_FILES} ${ASM_PRIMITIVES})
    else()
        add_library(libx264 STATIC ${SOURCE_FILES} ${ASM_PRIMITIVES})
    endif()

    if (MSVC)
        set_target_properties(libx264 PROPERTIES COMPILE_FLAGS "/Z7")
    endif()
else()
    add_library(libx264 )
endif()

if (APPLE OR LINUX)
    if (APPLE)
        set_private_xcode_attr(x264)
        set_xcode_attr_property(x264 GCC_PRECOMPILE_PREFIX_HEADER "YES")
        set_xcode_attr_property(x264 GCC_PREFIX_HEADER, "${CMAKE_CURRENT_SOURCE_DIR}/../X264EncLib-Prefix.pch")
        if (IOS)
            set_xcode_attr_property(x264 IPHONEOS_DEPLOYMENT_TARGET "8.1")
        elseif(OSX)
            set_xcode_attr_property(x264 MACOSX_DEPLOYMENT_TARGET "10.13")
        endif(IOS)
    endif (APPLE)

    if (LINUX_ARCH_x86_64)
        add_custom_command(TARGET x264-asm
                        PRE_BUILD
                        COMMAND rm -rf ${CMAKE_BINARY_DIR}/common
                        COMMAND mkdir ${CMAKE_BINARY_DIR}/common
                        DEPENDS x264-asm)
        set(ASM_OUTPUT_DIR ${CMAKE_BINARY_DIR}/common)
        if (NOT EXISTS ${ASM_OUTPUT_DIR})
            file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/common)
        endif()
    endif()
endif(APPLE OR LINUX)

if (APPLE OR LINUX)
    install(DIRECTORY
        $<TARGET_FILE_DIR:x264>
        DESTINATION ${CMAKE_BINARY_DIR}/build)
elseif(ANDROID)
    install(DIRECTORY
        $<TARGET_FILE_DIR:x264>
        DESTINATION ${CMAKE_BINARY_DIR}/build)
else()
    install(DIRECTORY
        $<TARGET_FILE_DIR:libx264>
        DESTINATION ${CMAKE_BINARY_DIR}/build)
endif()

install(FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/x264.h
        ${CMAKE_CURRENT_SOURCE_DIR}/x264_config.h
        DESTINATION ${CMAKE_BINARY_DIR}/build/include)
