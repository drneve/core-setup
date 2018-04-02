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
    Copy-Item -Path $dotNetCli -Destination $destination -Recurse -ErrorAction Ignore
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
#$testBin="$RepoRoot\Bin\win-x64.Debug\Msi.Tests\net46"
#$testProj="$PSScriptRoot\$testName\$testName.csproj"
$testProj="$PSScriptRoot\$testName"
$testBin= Join-Path $TestDir "$testName"

$listMsiFileName="ListMsi.txt"
$msiListPath="$testBin\$listMsiFileName"

if(Test-Path $testBin){
    Remove-Item $testBin -Recurse -Force -ErrorAction Ignore
}
Write-Output "$testBin"
New-Item -Name $testBin -ItemType directory

#Copy-Item $testProj -Destination $testBin

<#
try {
     
    & $dotNetExe restore $testProj

    if($LastExitCode -ne 0)
    {
        throw "dotnet restore failed with exit code $LastExitCode."     
    }

    & $dotNetExe build $testProj

    if($LastExitCode -ne 0)
    {
        throw "dotnet build failed with exit code $LastExitCode."
    }

    Write-Output "Running installer tests"
   
   
    $RuntimeExeFileName = [System.IO.Path]::GetFileName($InputExe)

    CopyInstaller $testBin
    CopyDotnetCli $testBin
    CreateMsiListFile

    docker run --rm -v "$testBin\:C:\sharedFolder" -e RUNTIME_EXE=$RuntimeExeFileName -e MSI_LIST=$listMsiFileName -e PROD_VERSION=$ProductVersion microsoft/windowsservercore C:\sharedFolder\dotnetcli\dotnet.exe vstest C:\sharedFolder\$testName.dll | Out-Host

#    & $dotNetExe test $testProj

    if($LastExitCode -ne 0)
    {
        throw "dotnet xunit failed with exit code $LastExitCode."     
    }
}

finally {
    Write-Output "End of test"
}
#>
Exit 0
