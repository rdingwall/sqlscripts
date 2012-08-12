-- Drops all stored procedures in a database. 

DECLARE SPCursor CURSOR FOR
	SELECT
		s.name AS [Schema],
		o.name AS StoredProc
	FROM
		sys.objects o
		INNER JOIN sys.schemas s ON
			s.SCHEMA_ID = o.SCHEMA_ID
	WHERE
		type IN (N'P', N'PC')
		AND is_ms_shipped = 0
	ORDER BY
		s.name,
		o.name

DECLARE @Schema SYSNAME
DECLARE @StoredProc SYSNAME

OPEN SPCursor

FETCH NEXT FROM SPCursor INTO @Schema, @StoredProc

WHILE @@FETCH_STATUS = 0 
BEGIN
	
	IF @StoredProc NOT IN
	(
		'XXX' -- Put any stored procs you want to keep here
	)
	BEGIN
		PRINT 'Dropping ' + @Schema + '.' + @StoredProc + ' ...'
		EXEC(N'DROP PROCEDURE [' + @Schema + '].[' + @StoredProc + '];')
	END
	
	FETCH NEXT FROM SPCursor INTO @Schema, @StoredProc
END

CLOSE SPCursor
DEALLOCATE SPCursor

GO
