[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw "Build.ps1 is Windows-only. Use Build.sh on macOS/Linux."
}

function Show-Help {
    Write-Host @'
Usage: ./Scripts/Build.sh [CONFIG] [--build-dir <path>] [--projucer] [--help]

Build configuration:
  Debug | Release | RelWithDebInfo | MinSizeRel   (default: Debug)

Options:
  --build-dir <path>   CMake build directory (default: ./Builds/CMake)
  --projucer           Use legacy Projucer/Xcode/Visual Studio build script
  --help               Show this help text

Examples:
  ./Scripts/Build.sh
  ./Scripts/Build.sh Release
  ./Scripts/Build.sh --build-dir ./build
  ./Scripts/Build.sh Debug --projucer
'@
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [string[]]$Arguments,
        [string]$WorkingDirectory,
        [string]$FailureLabel
    )

    $didPush = $false
    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        Push-Location $WorkingDirectory
        $didPush = $true
    }

    try {
        if ($Arguments) {
            & $Command @Arguments
        }
        else {
            & $Command
        }
    }
    finally {
        if ($didPush) {
            Pop-Location
        }
    }

    $exitCode = 0
    if ($null -ne $LASTEXITCODE) {
        $exitCode = [int]$LASTEXITCODE
    }

    if ($exitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($FailureLabel)) {
            $FailureLabel = $Command
        }

        Write-Host "$FailureLabel failed with exit code $exitCode"
        exit $exitCode
    }
}

function Invoke-ProjucerBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootDir,
        [Parameter(Mandatory = $true)]
        [string]$BuildConfiguration
    )

    $productName = 'Moonbase App Demo'
    $jucerProject = Join-Path $RootDir "$productName.jucer"

    $projucerBuildDir = Join-Path $RootDir 'Submodules\JUCE\extras\Projucer\Builds\VisualStudio2022'
    $projucerBinary = Join-Path $projucerBuildDir 'x64\Release\App\Projucer.exe'

    if (-not (Test-Path -LiteralPath $projucerBinary -PathType Leaf)) {
        Invoke-NativeCommand -Command 'MSBuild.exe' -Arguments @(
            'Projucer_App.vcxproj',
            '-p:Configuration=Release',
            '-p:Platform=x64'
        ) -WorkingDirectory $projucerBuildDir -FailureLabel 'Build Projucer'
    }

    if (-not (Test-Path -LiteralPath $projucerBinary -PathType Leaf)) {
        throw "Error, Projucer binary not found after build at $projucerBinary"
    }

    $prebuildScript = Join-Path $RootDir 'Submodules\moonbase_JUCEClient\PreBuild.ps1'
    $configJsonPath = Join-Path $RootDir 'Resources\moonbase_api_config.json'
    & $prebuildScript $configJsonPath

    Invoke-NativeCommand -Command $projucerBinary -Arguments @('--resave', $jucerProject) -FailureLabel 'Resave Projucer project'

    $appBuildDir = Join-Path $RootDir 'Builds\VisualStudio2022'
    Invoke-NativeCommand -Command 'MSBuild.exe' -Arguments @(
        "${productName}_App.vcxproj",
        "-p:Configuration=$BuildConfiguration",
        '-p:Platform=x64'
    ) -WorkingDirectory $appBuildDir -FailureLabel 'Build app project'
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Resolve-Path -LiteralPath (Join-Path $scriptDir '..')).Path

$buildConfiguration = 'Debug'
$buildDirectory = ''
$useProjucer = $false

for ($i = 0; $i -lt $CliArgs.Count; $i++) {
    $arg = $CliArgs[$i]

    switch ($arg) {
        'Debug' {
            $buildConfiguration = 'Debug'
            continue
        }
        'Release' {
            $buildConfiguration = 'Release'
            continue
        }
        'RelWithDebInfo' {
            $buildConfiguration = 'RelWithDebInfo'
            continue
        }
        'MinSizeRel' {
            $buildConfiguration = 'MinSizeRel'
            continue
        }
        '--build-dir' {
            if (($i + 1) -ge $CliArgs.Count) {
                Write-Host 'Error: --build-dir requires a value'
                exit 1
            }

            $i++
            $buildDirectory = $CliArgs[$i]
            continue
        }
        '--projucer' {
            $useProjucer = $true
            continue
        }
        '--help' {
            Show-Help
            exit 0
        }
        '-h' {
            Show-Help
            exit 0
        }
        default {
            Write-Host "Error: Unknown argument '$arg'"
            Write-Host ''
            Show-Help
            exit 1
        }
    }
}

if ($useProjucer) {
    Invoke-ProjucerBuild -RootDir $rootDir -BuildConfiguration $buildConfiguration
    exit 0
}

if ([string]::IsNullOrWhiteSpace($buildDirectory)) {
    $buildDirectory = Join-Path $rootDir 'Builds\CMake'
}

Invoke-NativeCommand -Command 'cmake' -Arguments @(
    '-S', $rootDir,
    '-B', $buildDirectory,
    "-DCMAKE_BUILD_TYPE=$buildConfiguration"
) -FailureLabel 'Configure CMake project'

Invoke-NativeCommand -Command 'cmake' -Arguments @(
    '--build', $buildDirectory,
    '--config', $buildConfiguration
) -FailureLabel 'Build CMake project'
