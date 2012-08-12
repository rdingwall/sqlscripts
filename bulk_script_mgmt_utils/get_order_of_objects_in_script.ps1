# Parses out all the views in a *.sql script (or directory of scripts) to
# show the order in which they need to be run in the database for inter-object
# dependencies e.g. views querying other views.

$files = Get-ChildItem C:\myapp\sql\up | Sort-Object

function Get-Views($file) {
	Print-Objects $file 'CREATE\s*(OR\s*REPLACE)?\s*(FORCE)?\s*VIEW\s*\"?([\w]+)\"?'
}

function Get-Package-Headers($file) {
	Print-Objects $file 'CREATE\s*(OR\s*REPLACE)?\s*(FORCE)?\s*PACKAGE\s*\"?([\w]+)\"?'
}

function Get-Package-Bodies($file) {
	Print-Objects $file 'CREATE\s*(OR\s*REPLACE)?\s*(FORCE)?\s*PACKAGE\s+BODY\s*\"?([\w]+)\"?'
}

function Get-Materialized-Views($file) {
	Print-Objects $file 'CREATE\s*(OR\s*REPLACE)?\s*(FORCE)?\s*MATERIALIZED\s+VIEW\s*\"?([\w]+)\"?'
}

function Print-Objects($file, $regex) {
	$count = 0
	# Assumes CREATE (options) OBJ_NAME always appears on the same line!
	Get-Content $file | %{ if ($_ -imatch $regex) { $count++; $Matches[3].ToString().ToUpper() }} | Write-Output
	Write-Output "Found $count matching objects."
}

cls
foreach ($file in $files) {	
	Write-Output Get-Materialized-Views($file.FullName)
	Write-Output Get-Views($file.FullName)
	Write-Output Get-Package-Headers($file.FullName)
	Write-Output Get-Package-Bodies($file.FullName)
}
