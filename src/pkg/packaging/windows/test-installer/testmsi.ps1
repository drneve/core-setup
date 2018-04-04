# Copyright (c) .NET Foundation and contributors. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

param(
    [string]$TestDir,
    [string[]]$InputMsi,
    [string]$InputExe,
    [string]$ProductVersion
)

$RepoRoot = Convert-Path "$PSScriptRoot\..\..\..\..\.."
$CommonScript = "$RepoRoot\tools-local\scripts\common\_common.ps1"

if(-Not (Test-Path "$CommonScript"))
{
    Exit -1
} 
. "$CommonScript"

$dotNetCli = "$RepoRoot\Tools\dotnetcli"
$dotNetExe = Join-Path $dotNetCli "dotnet.exe"

if(-Not (Test-Path $dotNetCli))
{
    throw "$dotNetCli not found" 
}


function CopyInstaller([string]$destination)
{
    # Copy the .msi and the .exe to the testBin directory so
    # the tests running in the docker container have access to them.
    foreach($msi in $InputMsi)
    {
    	Copy-Item $msi -Destination $destination
    }

    Copy-Item $InputExe -Destination $destination -ErrorAction Ignore
}

function CopyDotnetCli([string]$destination)
{
    Copy-Item -Path $dotNetCli -Destination $destination -Recurse
}

function CreateMsiListFile()
{
    if( Test-Path $msiListPath )
    {
    	Remove-Item $msiListPath
    }
    foreach($msi in $InputMsi)
    {
    	[System.IO.Path]::GetFileName($msi) | Out-File -filepath $msiListPath -Append
    }
}


Write-Output "Running tests for MSI installer at $inputMsi."

$testName = "Msi.Tests"
#$testProjDir="$PSScriptRoot\$testName"
$testBin= $TestDir 

$dockerDir= Join-Path $testBin "dockerDir"
#$dllProj="$dockerDir\$testName.dll"

$listMsiFileName="ListMsi.txt"
$msiListPath="$dockerDir\$listMsiFileName"

Write-Output "$TestDir"

#Copy-Item $testProjDir -Destination $TestDir -Recurse

pushd "$testBin"

try {
     
    & $dotNetExe restore

    if($LastExitCode -ne 0)
    {
        throw "dotnet restore failed with exit code $LastExitCode."     
    }

    & $dotNetExe build --output $dockerDir 

    if($LastExitCode -ne 0)
    {
        throw "dotnet build failed with exit code $LastExitCode."
    }


    Write-Output "Running installer tests"
   
    CopyInstaller $dockerDir
    CopyDotnetCli $dockerDir
    CreateMsiListFile

    $RuntimeExeFileName = [System.IO.Path]::GetFileName($InputExe)

    #docker run --rm -v "$dockerDir\:C:\sharedFolder" -e RUNTIME_EXE=$RuntimeExeFileName -e MSI_LIST=$listMsiFileName -e PROD_VERSION=$ProductVersion microsoft/windowsservercore C:\sharedFolder\dotnetcli\dotnet.exe vstest C:\sharedFolder\$testName.dll | Out-Host

   # & $dotNetExe vstest $dllProj

    if($LastExitCode -ne 0)
    {
        throw "dotnet test failed with exit code $LastExitCode."     
    }
}

finally {
    popd
    Write-Output "End of test"
}
Exit 0
