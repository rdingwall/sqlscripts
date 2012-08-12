# Powershell script to add number incrementing script number prefixes to *.sql
# files. For example, running this script with default settings:
#
#   aaa.sql
#   bbb.sql
#   ccc.sql
#
# Would become:
# 
#   00001_aaa.sql
#   00002_bbb.sql
#   00003_ccc.sql

# Number of steps between scripts. E.g. if you want to leave a gap and number
# your scripts 10_aaa.sql 20_bbb.sql 30_ccc.sql etc set the increment to 10.
$increment = 1;

# Number to give to the first script. Useful if you already have a bunch of
# numbered scripts.
$start = 1;

# How much padding to give the numbers e.g. 00001 would be padding of 5.
$padding = 5;

# Location of *.sql files to rename.
$files = Get-ChildItem C:\myapp\sql\up | Sort-Object

cls;

for ($i = 0; $i -lt $files.Length; $i++) {

	$file = $files[$i];

	$newVersionNumber = ($i + $increment) + $start;
	$newFileName =  ("{0:D$padding}" -f $newVersionNumber) + "_" + $file.Name.Substring($padding + 1);

	Rename-Item $file.FullName $newFileName;

	Write-Output "$file.Name => $newFileName";
}