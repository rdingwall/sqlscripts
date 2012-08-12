# Powershell script to renumber a series of numbered *.sql files. For example,
# if you have a directory of scripts numbered 1-100, but need to insert 4
# scripts between 78-79, you could:
#
# 1. Use this script to renumber them all with an increment of 5 to make room
#    for the new scripts.
# 2. Add your scripts.
# 3. Run this script again with increment of 1 to collapse the numbering back
#    into a tight form (would now be 1-104).

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

	$versionNumber = [Int32]::Parse($file.Name.Substring(0, 5));

	$newVersionNumber = (($i + 1) * $increment) + $start;
	$newFileName =  ("{0:D$padding}" -f $newVersionNumber) + $file.Name.Substring($padding);

	Rename-Item $file.FullName $newFileName;

	Write-Output "$file.Name => $newFileName";
}