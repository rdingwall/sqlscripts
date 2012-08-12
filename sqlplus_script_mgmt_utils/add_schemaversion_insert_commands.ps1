# Powershell script to add an extra command to the bottom of a series of *.sql
# scripts, so that after running, each script records itself with an entry in a
# changelog/schemaversion/dbscripts/scriptslog table.
#
# This assumes each script has a number prefix and uses that to populate one of
# the columns, for example:
#
# 00001_a.sql --> INSERT INTO CHANGELOG (VERSION_NUMBER, FILE_NAME) VALUES (1, '00001_a.sql');

$padding = 5;

$files = Get-ChildItem C:\yourapp\sql\up | Sort-Object

cls;

# Strip them out
foreach ($file in $files) {
	[string] $str = [System.IO.File]::ReadAllText($file.FullName).Trim();

	$regex = [regex] "INSERT INTO CHANGELOG.*(\r|\n|\r\n)*\w*COMMIT;"
	$lines = $regex.Replace($str, "");
	Write-Output $file.Name;
	Set-Content $file.FullName $lines;
}

# Add them back
foreach ($file in $files) {

	$versionNumber = [Int32]::Parse($file.Name.Substring(0, $padding));

	[string] $str = [System.IO.File]::ReadAllText($file.FullName).Trim();

	if ($str.Contains("CHANGELOG")) {
		continue;
	}

	$str += [Environment]::NewLine;
	$str += [Environment]::NewLine;
	$str += "INSERT INTO CHANGELOG (VERSION_NUMBER, FILE_NAME) VALUES ($versionNumber, '$file');";
	$str += [Environment]::NewLine;
	$str += "COMMIT;";

	Write-Output $file.Name;

	Set-Content $file.FullName $str;
}