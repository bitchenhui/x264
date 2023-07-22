cmake_minimum_required(VERSION 3.6)

project(libx264)

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

if (WIN32)
    set(CMAKE_CONFIGURATION_TYPES "Debug;Release" CACHE STRING "build types" FORCE)
    
    if (CMAKE_SIZEOF_VOID_P EQUAL 8)
        add_definitions(-DTARGET_IS_WIN64)
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
        add_definitions(-DTARGET_IS_WIN32)
    endif()

    add_definitions(-DUNICODE
                  -D_UNICODE
                  -DWIN32
                  -D__ICL
                  -DBIT_DEPTH=8
                  -DSYS_WINDOWS
                  -DHAVE_SSE)

    if (MSVC)
        set(CMAKE_C_FLAGS "/GF /EHs-c- /W4 /sdl- /TP")
        set(CMAKE_C_FLAGS_RELEASE "/MT /O2  /D NDEBUG")
        set(CMAKE_C_FLAGS_DEBUG "/MTd /D DEBUG /Od /Ob0")

        set(CMAKE_CXX_FLAGS "/GF /GR- /EHs-c- /W4 /sdl-")
        set(CMAKE_CXX_FLAGS_RELEASE "/MT /O2 /Ob2 /D NDEBUG")
        set(CMAKE_CXX_FLAGS_DEBUG "/MTd /Od /Ob0 /D DEBUG /D _DEBUG")

    else()
        message(FATAL_ERROR "not support currently")
    endif(MSVC)
elseif(APPLE)
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

option(CMAKE_OSX_ARCHITECTURES "osx_architectures" 'x86_64')
string(REPLACE " " "" OSX_ARCH ${CMAKE_OSX_ARCHITECTURES})
if( (OSX AND (${OSX_ARCH} STREQUAL x86_64)) OR WIN32 OR LINUX_ARCH_x86_64)
    #find_program(NASM_EXECUTABLE NAMES nasm)
    if (WIN32)
        if (CMAKE_SIZEOF_VOID_P EQUAL 8)
            # message(STATUS "use win64")
            set(NASM_EXECUTABLE ${CMAKE_SOURCE_DIR}/../cmake/win/nasm-win64.exe)
        elseif (CMAKE_SIZEOF_VOID_P EQUAL 4)
            set(NASM_EXECUTABLE ${CMAKE_SOURCE_DIR}/../cmake/win/nasm.exe)
        endif()
    elseif(OSX)
        set(NASM_EXECUTABLE ${CMAKE_SOURCE_DIR}/../cmake/osx/nasm)
    else()
        set(NASM_EXECUTABLE ${CMAKE_SOURCE_DIR}/../cmake/linux/nasm)
    endif()

    if (${NASM_EXECUTABLE} STREQUAL NASM_EXECUTABLE-NOTFOUND)
        message(FATAL_ERROR "cann't find nasm")
    endif()
    message(STATUS "nasm : " ${NASM_EXECUTABLE})
    set(ASM_EXECUTABLE "${NASM_EXECUTABLE}")

    set(X86_ASM_SRCS
        bitstream-a.asm
        cabac-a.asm
        const-a.asm
        cpu-a.asm
        dct-a.asm
        deblock-a.asm
        mc-a.asm
        mc-a2.asm
        pixel-a.asm
        predict-a.asm
        quant-a.asm
        sad-a.asm
        x86inc.asm
        x86util.asm)

    if (WIN32)
        if (CMAKE_SIZEOF_VOID_P EQUAL 8)
            # message(STATUS "use win64")
            list(APPEND X86_ASM_SRCS
                        dct-64.asm 
                        trellis-64.asm)
        elseif (CMAKE_SIZEOF_VOID_P EQUAL 4)
            list(APPEND X86_ASM_SRCS
                        dct-32.asm
                        pixel-32.asm)
        endif()
    elseif (OSX)
        list(APPEND X86_ASM_SRCS
                    dct-64.asm
                    sad16-a.asm)
    elseif (LINUX)
        list(APPEND X86_ASM_SRCS
                    dct-64.asm)
    endif()

    set(C_SRCS
        bitstream.h
        dct.h
        deblock.h
        mc.h
        mc-c.c
        pixel.h
        predict.h
        predict-c.c
        quant.h
        util.h)

    if (WIN32)
        #set(ASM_FLAGS -I${CMAKE_CURRENT_SOURCE_DIR}/common/x86/ -f win32 -O2 -DHIGH_BIT_DEPTH=0 -DBIT_DEPTH=8 -DARCH_X86_64=0 -DOS_MAC=0 -DPREFIX)
        if (CMAKE_SIZEOF_VOID_P EQUAL 8)
            #set(ASM_FLAGS -I${CMAKE_CURRENT_SOURCE_DIR}/common/x86/ -f win64 -O2 -DBIT_DEPTH=8 -DARCH_X86_64=1 -DTARGET_IS_WIN64)
            set(ASM_FLAGS -I${CMAKE_CURRENT_SOURCE_DIR}/common/x86/ -f win64 -O2 -DHIGH_BIT_DEPTH=0 -DBIT_DEPTH=8 -DARCH_X86=0 -DARCH_X86_64=1 -DTARGET_IS_WIN64)
        elseif (CMAKE_SIZEOF_VOID_P EQUAL 4)
            set(ASM_FLAGS -I${CMAKE_CURRENT_SOURCE_DIR}/common/x86/ -f win32 -O2 -DBIT_DEPTH=8 -DARCH_X86_64=0 -DTARGET_IS_WIN32 -DPREFIX)
        endif()
    elseif(OSX)
        set(ASM_FLAGS -I${CMAKE_CURRENT_SOURCE_DIR}/common/x86/ -f macho64 -O2 -DBIT_DEPTH=8 -DARCH_X86_64=1 -DPREFIX -DOS_MAC=1 -DPIC -Worphan-labels -DSTACK_ALIGNMENT=16)
    elseif(LINUX)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLINUX -D__GUNC__ -D__STRICT_ANSI__ -DARCH_X86_64 -DHAVE_SSE -DX64 -DBIT_DEPTH=8")
        set(ASM_FLAGS -I${CMAKE_CURRENT_SOURCE_DIR}/common/x86/ -DLINUX -D__GUNC__  -DHAVE_SSE -DARCH_X86_64=1 -DBIT_DEPTH=8 -DSTACK_ALIGNMENT=64 -D_DEBUG -DX64 -f elf64)
    endif()

    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/common)
    foreach(ASM ${X86_ASM_SRCS})
        set(ASM_SRC ${CMAKE_CURRENT_SOURCE_DIR}/common/x86/${ASM})
        set(ASM_OBJ ${CMAKE_BINARY_DIR}/common/${ASM}.${SUFFIX})
        list(APPEND ASM_SRCS ${ASM_SRC})
        list(APPEND ASM_OBJS ${ASM_OBJ})
        add_custom_command(
            OUTPUT ${ASM_OBJ}
            COMMAND ${ASM_EXECUTABLE}
            ARGS ${ASM_FLAGS} ${ASM_SRC} -o ${ASM_OBJ}
            DEPENDS ${ASM_SRC})
    endforeach()

    foreach(SRC ${X86_ASM_SRCS} ${C_SRCS})
    #foreach(SRC ${C_SRCS})
        list(APPEND ASM_PRIMITIVES ${CMAKE_CURRENT_SOURCE_DIR}/common/x86/${SRC})
    endforeach()
    foreach(OBJ ${ASM_OBJS})
        list(APPEND ASM_PRIMITIVES ${OBJ})
    endforeach()
    source_group(Assembly FILES ${ASM_PRIMITIVES})

elseif(IOS OR ANDROID OR (OSX AND (${OSX_ARCH} STREQUAL arm64)) OR LINUX_ARCH_AARCH64)
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

    set(ARM_SRCS
        ./common/arm/asm.S
        ./common/arm/bitstream-a.S
        ./common/arm/cpu-a.S
        ./common/arm/dct-a.S
        ./common/arm/deblock-a.S
        ./common/arm/mc-a.S
        ./common/arm/pixel-a.S
        ./common/arm/predict-a.S
        ./common/arm/predict-c.c
        ./common/arm/quant-a.S
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

    set(X86_ASM_SRCS
        ./common/x86/bitstream-a.asm
        ./common/x86/cabac-a.asm
        ./common/x86/const-a.asm
        ./common/x86/cpu-a.asm
        ./common/x86/dct-a.asm
        ./common/x86/deblock-a.asm
        ./common/x86/mc-a.asm
        ./common/x86/mc-a2.asm
        ./common/x86/pixel-a.asm
        ./common/x86/predict-a.asm
        ./common/x86/quant-a.asm
        ./common/x86/sad-a.asm
        ./common/x86/x86inc.asm
        ./common/x86/x86util.asm)

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
        elseif(${ANDROID_ABI} MATCHES "x86")
            foreach(SRC ${C_SRCS})
                list(APPEND ASM_PRIMITIVES ./common/x86/${SRC})
            endforeach()
            #set(A_SRCS ${X86_ASM_SRCS})
            set(A_SRCS)
            set(ASM_PRIMITIVES)
            source_group(x86 FILES ${A_SRCS})
        endif()
    elseif(IOS OR OSX)
        foreach(SRC ${C_SRCS})
            list(APPEND ARM_SRCS ./common/arm/${SRC})
            list(APPEND ARM64_SRCS ./common/aarch64/${SRC})
        endforeach()
        set(A_SRCS ${ARM_SRCS} ${ARM64_SRCS})
        source_group(arm FILES ${ARM_SRCS})
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
