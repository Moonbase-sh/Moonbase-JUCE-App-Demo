#!/bin/bash

DO_STANDALONE_BUILD=1

BUILD_CONF="Debug"
PRODUCTNAME="Moonbase App Demo"


BASEDIR="$(realpath $(dirname "$0")/..)"
JUCERPROJ="$BASEDIR/$PRODUCTNAME.jucer"

"$BASEDIR/Scripts/BuildProjucer.sh" || exit $?
"$BASEDIR/Submodules/moonbase_JUCEClient/Assets/Build.sh" || exit $?
"$BASEDIR/Submodules/moonbase_JUCEClient/KeyIntegrity/IntegrityCheck.sh" "$BASEDIR/Resources/moonbase_api_config.json" || exit $?


if [[ "$OSTYPE" == "darwin"* ]]; then

    PROJUCER="$BASEDIR/Submodules/JUCE/extras/Projucer/Builds/MacOSX/build/Release/Projucer.app/Contents/MacOS/Projucer"
    BUILD_CMD="xcodebuild \
                -project \"$PRODUCTNAME.xcodeproj\" \
                -configuration $BUILD_CONF \
                -target \"$PRODUCTNAME - App\""

elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then

    PROJUCER="$BASEDIR/Submodules/JUCE/extras/Projucer/Builds/VisualStudio2022/x64/Release/App/Projucer.exe"
    BUILD_CMD="MSBuild.exe \"${PRODUCTNAME}_App.vcxproj\" -p:Configuration=$BUILD_CONF -p:Platform=x64"

else
  echo "Error: This script can only be run on macOS or Windows"
  exit 1
fi

if [ ! -f "$PROJUCER" ]; then
    echo "Error: Projucer binary not found at $PROJUCER"
    exit 1
fi

"$PROJUCER" --resave "$JUCERPROJ" || prematureExit $?

if [[ "$OSTYPE" == "darwin"* ]]; then
    cd "$BASEDIR/Builds/MacOSX"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
    cd "$BASEDIR/Builds/VisualStudio2022"
fi

eval "$BUILD_CMD" 
returnVal=$?

cd "$BASEDIR"

RED=$(tput setaf 9; tput bold)
GREEN=$(tput setaf 10; tput bold)
RESET=$(tput sgr0)

if [ $returnVal -eq 0 ]; then
	echo "$GREEN**************** BUILD SUCCESSFUL ****************$RESET"
else
	echo "$RED!!! **************** BUILD FAILED **************** !!!$RESET"
    echo "Build failed on exit code: $returnVal"
fi

exit $returnVal