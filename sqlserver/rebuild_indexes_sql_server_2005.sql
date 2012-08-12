--Check database for integrity
DBCC CHECKDB

-- Check consistency between tables
DBCC CHECKCATALOG

-------------------------------------------------------------------------------
-- Rebuild indexes on all tables and views in the current database.
-------------------------------------------------------------------------------
DECLARE TableCursor CURSOR FOR
	SELECT
		TABLE_SCHEMA,
		TABLE_NAME
	FROM
		INFORMATION_SCHEMA.TABLES
	ORDER BY
		TABLE_NAME ASC

DECLARE @Table SYSNAME
DECLARE @Schema SYSNAME

OPEN TableCursor

FETCH NEXT FROM TableCursor INTO @Schema, @Table

WHILE @@FETCH_STATUS = 0 
BEGIN
    PRINT 'Rebuilding indexes on ' + @Schema + '.' + @Table + ' table...'
	
    EXEC(N'ALTER INDEX ALL ON [' + @Schema + '].[' + @Table + '] REBUILD;')
	
	FETCH NEXT FROM TableCursor INTO @Schema, @Table
END

CLOSE TableCursor
DEALLOCATE TableCursor

-------------------------------------------------------------------------------
-- Update statistics on every object in the current database. 
-------------------------------------------------------------------------------
EXEC sp_updatestats

-------------------------------------------------------------------------------
-- Correct any pages and row count inaccuracies in the catalog views from pre-
-- SQL Server 2005 databases.
-------------------------------------------------------------------------------
DBCC UPDATEUSAGE (0)


--Now check for any pending changes in full text catalogs, and run the full text catalog rebuild
GO
