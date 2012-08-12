# Concatenate multiple plsql scripts together into one script. Files are read in
# order by name, so this works best if you're using numbered scripts e.g.
#
# 0001_create_customer_tables.sql
# 0002_create_order_tables.sql

cls;

$files = Get-ChildItem C:\myapp\sql\up | Sort-Object

$outputFile = "C:\myapp\sql\merged.sql"

foreach ($file in $files) {
	Write-Output "$file";

	$lines = Get-Content $file.FullName;

	"--------------------------------------------------------------------------------" | Out-File -FilePath $outputFile -Append
	"-- Script: $file" | Out-File -FilePath $outputFile -Append
	"--------------------------------------------------------------------------------" | Out-File -FilePath $outputFile -Append
	$lines | Out-File -FilePath $outputFile -Append
}