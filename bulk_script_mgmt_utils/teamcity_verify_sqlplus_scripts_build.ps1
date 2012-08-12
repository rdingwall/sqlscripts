# Powershell script to be used in a TeamCity build to verify all your Oracle
# upgrade scripts play through successfully in SQL*Plus, from 0001 to n (and
# optionally back to 0001 again if you have downgrade scripts).
#
# Features: 
# 
# * Drops and recreates the user (via a separate script, you need to write
#   this), runs all the upgrade scripts, and recompiles all the packages etc.
# * This script emits specially-formatted messages to the console that can be
#   read by TeamCity build server and provide live progress updates (e.g. the
#   name of the script that is currently executing, and the total number of
#   scripts that were run).
# * Runs all *.sql scripts in a directory in Oracle SQL*Plus.
# * Scripts are wrapped with error handling, and stop on any error.
#
# NB optionally instead of dropping and recreating the user you could just drop
# all objects in the schema (and there is a script in github repo that does
# this).

$ErrorActionPreference = 'Stop'

$logon = "foo/password@XE"
$upgradeScriptsDir = sql\up
$downScriptsDir = sql\down
$recompileObjectsScript = sql\utils\recompile_all_objects.sql

$adminLogon = "SYS/password@XE AS SYSDBA"
$dropCreateScript = sql\utils\drop-create-user.sql

# Powershell truncating long messages workaround 
# From http://youtrack.jetbrains.com/issue/TW-15080
if (Test-Path env:TEAMCITY_VERSION) {
    $rawUI = (Get-Host).UI.RawUI
    $maxwinwidth = $rawUI.MaxPhysicalWindowSize.Width
    $rawUI.BufferSize = New-Object Management.Automation.Host.Size ([Math]::max($maxwinwidth, 500), $rawUI.BufferSize.Height)
    $rawUI.WindowSize = New-Object Management.Automation.Host.Size ($maxwinwidth, $rawUI.WindowSize.Height)
    Write-Output "maxwinwidth=$maxwinwidth"
}

$global:scriptRunCount = 0

function Invoke-SqlPlus($file, $logon) {
	$fileNameOnly = [System.IO.Path]::GetFileName($file)
	Write-Output "##teamcity[progressStart '$fileNameOnly']";

	# Wrap script to make sqlplus stop on errors (because Oracle doesn't do this
	# by default). Also exit the prompt after the script has run.
	$lines = Get-Content $file;
	$lines = ,'whenever sqlerror exit sql.sqlcode rollback;' + $lines;
	$lines += 'exit';

	$global:scriptRunCount++

	$lines | sqlplus -S $logon | Tee-Object -Variable output | Microsoft.PowerShell.Utility\out-default;

	if (!$? -or # Stop on non-zero exit codes.
        # Stop on script errors. Have to detect them from output
        # unfortunately, as I couldn't find a way to make SQL*Plus halt on
        # warnings.
		$output -match "compilation errors" -or 
		$output -match "unknown command" -or 
		$output -match "Input is too long" -or
		$output -match "unable to open file") { 
		throw "Script failed: $fileNameOnly"; 
	}

	Write-Output "##teamcity[progressFinish '$fileNameOnly']";
}
function Execute-Scripts($directory, $logon) {
	$files = Get-ChildItem $directory | Sort-Object
	foreach ($file in $files) {
		Invoke-SqlPlus $file.FullName $logon
	}
}

function Run-Upgrade($logon) {
	Write-Output "##teamcity[progressStart 'Up scripts']";
	Execute-Scripts $upgradeScriptsDir $logon
	Invoke-SqlPlus $recompileObjectsScript $logon
	Write-Output "##teamcity[progressFinished 'Up scripts']";
}

function Run-Downgrade($logon) {
	Write-Output "##teamcity[progressStart 'Down scripts']";
	Execute-Scripts-Descending $downScriptsDir $logon
	Write-Output "##teamcity[progressFinished 'Down scripts']";
}

try
{
	cls
	Invoke-SqlPlus $dropCreateScript $adminLogon
	Run-Upgrade $logon
	
	# Optional, uncomment these lines if you have downgrade scripts, to upgrade
	# and downgrade and upgrade again. Why twice?? The second upgrade will find
	# any objects that were missed/forgotten in the downgrade scripts.
	#Run-Downgrade $logon
	#Run-Upgrade $logon

	Write-Output "##teamcity[buildStatus status='SUCCESS' text='Scripts run: $global:scriptRunCount']"
}
catch
{
	# Escape TeamCity service messages
	$text = $_ -replace "'", "|'"
	$text = $text -replace "\[", "|\["
	$text = $text -replace "\]", "|\]"
	Write-Error "##teamcity[buildStatus status='FAILURE' text='$text']"
	throw
}