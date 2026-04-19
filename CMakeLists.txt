cmake_minimum_required(VERSION 3.20)

project(MoonbaseAppDemo VERSION 0.11.3 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT DEFINED MOONBASE_JUCECLIENT_CONFIG_JSON OR MOONBASE_JUCECLIENT_CONFIG_JSON STREQUAL "")
    set(MOONBASE_JUCECLIENT_CONFIG_JSON
        "${CMAKE_CURRENT_SOURCE_DIR}/Resources/moonbase_api_config.json"
        CACHE FILEPATH "Path to moonbase_api_config.json used by moonbase_JUCEClient")
endif()

add_subdirectory(Submodules/JUCE)
add_subdirectory(Submodules/moonbase_JUCEClient)

juce_add_gui_app(MoonbaseAppDemo
    PRODUCT_NAME "Moonbase App Demo"
    COMPANY_NAME "Demo Co."
    BUNDLE_ID "com.democo.mbappdemo"
    VERSION "${PROJECT_VERSION}"
    NEEDS_CURL TRUE
    NEEDS_WEB_BROWSER TRUE)

juce_generate_juce_header(MoonbaseAppDemo)

target_sources(MoonbaseAppDemo
    PRIVATE
        Source/Main.cpp
        Source/MainComponent.cpp
        Source/MainComponent.h)

juce_add_binary_data(MoonbaseAppDemoBinaryData
    SOURCES
        Assets/MoonbaseLogo.svg)

set_target_properties(MoonbaseAppDemoBinaryData PROPERTIES POSITION_INDEPENDENT_CODE TRUE)

target_compile_definitions(MoonbaseAppDemo
    PRIVATE
        JUCE_STRICT_REFCOUNTEDPOINTER=1
        JUCE_USE_CURL=1
        JUCE_WEB_BROWSER=1
        MOONBASE_APP_MODE=1
        $<$<CONFIG:Debug>:OBF_DEBUG=1>)

if(MSVC)
    target_compile_options(MoonbaseAppDemo PRIVATE /EHsc)
endif()

target_link_libraries(MoonbaseAppDemo
    PRIVATE
        MoonbaseAppDemoBinaryData
        moonbase_JUCEClient
        juce::juce_audio_basics
        juce::juce_audio_devices
        juce::juce_audio_formats
        juce::juce_audio_processors
        juce::juce_audio_utils
        juce::juce_cryptography
        juce::juce_data_structures
        juce::juce_events
        juce::juce_graphics
        juce::juce_gui_basics
        juce::juce_gui_extra
        juce::juce_product_unlocking
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags)
