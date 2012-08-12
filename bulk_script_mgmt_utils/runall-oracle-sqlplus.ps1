function Invoke-SqlPlus($file, $logon) {
	Write-Output "$file";

	# Wrap script to make SqlPlus stop on errors (why is this not the default
	# behaviour???). Also to exit the prompt after the script has run.
	$lines = Get-Content $file;
	$lines = ,'whenever sqlerror exit sql.sqlcode rollback;' + $lines;
	$lines += 'exit';

	$lines | sqlplus -S $logon | Tee-Object -Variable output | Microsoft.PowerShell.Utility\out-default;

	# Stop on non-zero exit codes.
	if (!$?) { throw "Script failed: $file"; }

	# Stop on compilation errors. Have to detect them from output unfortunately,
	# as I couldn't find a way to make SQL*Plus halt on warnings.
	if ($output -match "compilation errors" -or $output -match "unknown command" -or $output -match "unable to open file") { throw "Script failed: $file"; } 
}
function Execute-Scripts($directory, $logon) {
	$files = Get-ChildItem $directory | Sort-Object
	foreach ($file in $files) {
		Invoke-SqlPlus $file.FullName $logon
	}
}

$adminLogon = "SYS/password@XE AS SYSDBA"
$logon = "myapp\sql/password@XE"

cls
Invoke-SqlPlus C:\myapp\sql\drop-create-user.sql $adminLogon
Invoke-SqlPlus C:\myapp\sql\00001-create-changelog-table.sql $logon
Execute-Scripts C:\myapp\sql\up $logon
Execute-Scripts C:\myapp\sql\functions $logon
Execute-Scripts C:\myapp\sql\package_headers $logon
Execute-Scripts C:\myapp\sql\views $logon
Execute-Scripts C:\myapp\sql\package_bodies $logon
Invoke-SqlPlus C:\myapp\sql\oracle-recompile_all_objects.sql $logon
Write-Output "All done!"