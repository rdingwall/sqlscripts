# find un-used stored procedures from a .NET application.
# http://richarddingwall.name/2009/11/10/powershell-script-to-find-orphan-stored-procedures/
# ---------------------------------------------------------
 
# C# files
$src = "C:\yourproject\src"
 
# db objects (e.g. DDL for views, sprocs, triggers, functions)
$sqlsrc = "C:\yourproject\sqlscripts"
 
# connection string
$db = "Data Source=localhost;Initial Cataog..."
 
# ---------------------------------------------------------
 
echo "Looking for stored procedures..."
$cn = new-object system.data.SqlClient.SqlConnection($db)
 
$q = "SELECT
    name
FROM
    sys.objects
WHERE
    type in ('P', 'PC')
    AND is_ms_shipped = 0
    AND name NOT IN
    (
        'sp_alterdiagram', -- sql server stuff
        'sp_creatediagram',
        'sp_dropdiagram',
        'sp_helpdiagramdefinition',
        'sp_helpdiagrams',
        'sp_renamediagram',
        'sp_upgraddiagrams'
    )
ORDER BY
    name ASC"
 
$da = new-object "System.Data.SqlClient.SqlDataAdapter" ($q, $cn)
$ds = new-object "System.Data.DataSet" "dsStoredProcs"
$da.Fill($ds) | out-null
 
# chuck stored procs name in an array
$sprocs = New-Object System.Collections.Specialized.StringCollection
$ds.Tables[0] | FOREACH-OBJECT {
    $sprocs.Add($_.name) | out-null
}
$count = $sprocs.Count
echo "  found $count stored procedures"
 
# search in C# files
echo "Searching source code..."
dir -recurse -filter *.cs $src | foreach ($_) {
    $file = $_.fullname
 
    echo "searching $file"
    for ($i = 0; $i -lt $sprocs.Count; $i++) {
        $sproc = $sprocs[$i];
        if (select-string -path $file -pattern $sproc) {
            $sprocs.Remove($sproc)
            echo "  found $sproc"
        }
    }
}
 
# search in NHibernate *.hbm.xml mapping files
echo "Searching hibernate mappings..."
dir -recurse -filter *hbm.xml $src | foreach ($_) {
    $file = $_.fullname
 
    echo "searching $file"
    for ($i = 0; $i -lt $sprocs.Count; $i++) {
        $sproc = $sprocs[$i];
        if (select-string -path $file -pattern $sproc) {
            $sprocs.Remove($sproc)
            echo "  found $sproc"
        }
    }
}
 
# search through other database objects
dir -recurse -filter *.sql $sqlsrc | foreach ($_) {
    $file = $_.fullname
 
    echo "searching $file"
    for ($i = 0; $i -lt $sprocs.Count; $i++) {
        $sproc = $sprocs[$i];
        if ($file -notmatch $sproc) {
                    if (select-string -path $file -pattern $sproc) {
                $sprocs.Remove($sproc)
                echo "  found $sproc"
            }
        }
    }
}
 
# list any that are still here (i.e. weren't found)
$count = $sprocs.Count
echo "Found $count un-used stored procedures."
for ($i=0; $i -lt $count; $i++) {
    $x = $sprocs[$i]
    echo "  $i. $x"