# Copyright (c) .NET Foundation and contributors. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

param(
    [string]$InputMsi,
    [string]$TestDir
)

$RepoRoot = Convert-Path "$PSScriptRoot\..\..\..\..\.."
$CommonScript = "$RepoRoot\tools-local\scripts\common\_common.ps1"
$dotNetExe = Join-Path $RepoRoot "Tools\dotnetcli\dotnet.exe"

if(-Not (Test-Path "$CommonScript"))
{
    Exit -1
} 
. "$CommonScript"

function CopyExe([string]$destination)
{
    Copy-Item $dotNetExe -Destination:$destination
}

Write-Output "Running tests for MSI installer at $inputMsi."

if(!(Test-Path $InputMsi))
{
    throw "$inputMsi not found" 
}

$testName = "Msi.Tests"
$testProj="$PSScriptRoot\$testName\$testName.csproj"
$testBin="$TestDir$testName"

$toolsLocalPath = Join-Path $RepoRoot "Tools"
$dotNetExe = Join-Path $toolsLocalPath "dotnetcli\dotnet.exe"

Write-Output "dotnet cli path: $dotNetExe"

try {
    & $dotNetExe restore $testProj | Out-Host

    if($LastExitCode -ne 0)
    {
        throw "dotnet restore failed with exit code $LastExitCode."     
    }

    & $dotNetExe publish --output $testBin $testProj | Out-Host

    if($LastExitCode -ne 0)
    {
        throw "dotnet publish failed with exit code $LastExitCode."     
    }


	CopyExe $testBin

#	$runTest = Join-Path $testBin $testName
#	$runTest = $runTest + ".dll"

        Write-Output "Running installer tests"
        $MsiFileName = [System.IO.Path]::GetFileName($InputMsi)

	docker run --rm -v "$testBin\:D:" -e "HOST_MSI=D:\$MsiFileName"  windowsservercore  D:\dotnet.exe D:\$testName.dll | Out-Host

	Write-Output "after run test $runTest"

    	if($LastExitCode -ne 0)
    	{
        	throw "dotnet run-dll failed with exit code $LastExitCode."     
    	} 
}
finally{
	Write-Output "End of test"
}

Exit 0

