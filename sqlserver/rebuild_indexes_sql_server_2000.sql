declare @TableName sysname
declare c_Tables cursor for 
select Table_Name from information_schema.tables where Table_Type = 'Base Table'

open c_Tables fetch next from c_Tables into @TableName

while @@fetch_status = 0 
begin
    print @TableName
    dbcc dbreindex(@TableName)
    execute( N' Update Statistics [' + @TableName + ']' )
    print ' '
    fetch next from c_Tables into @TableName
end

close c_Tables
deallocate c_Tables