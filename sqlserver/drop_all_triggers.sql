-- Drops all triggers in a database.

DECLARE TRCursor CURSOR FOR
	SELECT
		s.name AS [Schema],
		o.name AS [Trigger]
	FROM
		sys.objects o
		INNER JOIN sys.schemas s ON
			s.SCHEMA_ID = o.SCHEMA_ID
	WHERE
		type IN (N'TR')
		AND is_ms_shipped = 0
	ORDER BY
		s.name,
		o.name

DECLARE @Schema SYSNAME
DECLARE @Trigger SYSNAME

OPEN TRCursor

FETCH NEXT FROM TRCursor INTO @Schema, @Trigger

WHILE @@FETCH_STATUS = 0 
BEGIN
	BEGIN
		PRINT 'Dropping ' + @Schema + '.' + @Trigger + ' ...'
		EXEC(N'DROP TRIGGER [' + @Schema + '].[' + @Trigger + '];')
	END
	
	FETCH NEXT FROM TRCursor INTO @Schema, @Trigger
END

CLOSE TRCursor
DEALLOCATE TRCursor

GO
