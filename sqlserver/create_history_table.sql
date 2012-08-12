-- SQL Server script that sets up an history (audit log) table that records all
-- updates, inserts and deletes from a particular table.

-- NOTE THIS SCRIPT DOES NOT WORK IF YOU HAVE TEXT/NTEXT/BLOB COLUMNS - you
-- need to join back on the original table itself instead.

DECLARE @table VARCHAR(100), @schema VARCHAR(100), @bPrintOnly BIT

-- Which table to create history table for?
SET @schema = N'dbo'
SET @table = N'Customers'

-- Actually create the table/triggers or just print the DDL?
SET @bPrintOnly = 1

------------------------------------------------------------------------------
-- Create _Audit table
------------------------------------------------------------------------------

DECLARE @crlf CHAR(2), @sql NVARCHAR(MAX)
SET @crlf = CHAR(10)

SET @sql = '
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + @schema + '].[' + @table + 'History]'') AND type in (N''U''))
	DROP TABLE [' + @schema + '].[' + @table + 'History]'

PRINT @sql
IF @bPrintOnly != 1 EXEC sp_executesql @sql ELSE PRINT @crlf + 'GO' + @crlf

set @sql = 'CREATE TABLE [' + @schema + '].[' + @table + 'History]
(' + @crlf

DECLARE
	@columnID INT,
	@columnName VARCHAR(MAX),
	@columnType VARCHAR(MAX),
	@columnSize VARCHAR(10),
	@done BIT

SET @columnID = 0
SET @done = 0

WHILE @done = 0   
BEGIN            
    SELECT TOP 1
		@columnID = c.column_id,
		@columnName = c.name,
		@columnType = ut.name,
		@columnSize = CASE
			WHEN c.max_length = -1 THEN 'MAX'
			ELSE CAST(CASE
				WHEN bt.name IN (N'nchar', N'nvarchar')
				THEN c.max_length/2
				ELSE c.max_length
			END AS VARCHAR(10)) 
		END
    FROM
		sys.tables t
		INNER JOIN sys.all_columns c ON
			c.object_id = t.object_id
		LEFT JOIN sys.types AS ut ON
			ut.user_type_id = c.user_type_id
		LEFT JOIN sys.types AS bt ON
			bt.user_type_id = c.system_type_id 
			AND bt.user_type_id = bt.system_type_id
    WHERE
		(t.name = @table AND SCHEMA_NAME(t.schema_id) = @schema)
		AND c.column_id > @columnID
	ORDER BY
		c.column_id

    IF @@rowcount = 0   
		SET @done = 1
    ELSE
    BEGIN
        SET @sql = @sql + '	[' + @columnName + '] [' + @columnType + ']'
        IF @columnType IN ('varchar', 'nvarchar', 'char', 'nchar')
			SET @sql = @sql + '('+LTRIM(@columnSize) + ')'
        SET @sql = @sql + ' NULL, ' + @crlf
    END
END

SET @sql = @sql + '   [ModifiedDate] [datetime] NOT NULL
);'
PRINT @sql
IF @bPrintOnly != 1 EXEC sp_executesql @sql ELSE PRINT @crlf + 'GO' + @crlf

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

------------------------------------------------------------------------------
-- Create UPDATE trigger
------------------------------------------------------------------------------

SET @sql = 'IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N''[' + @schema + '].[tg_' + @table + '_History]''))
	DROP TRIGGER [' + @schema + '].[tg_' + @table + '_History]'
PRINT @sql
IF @bPrintOnly != 1 EXEC sp_executesql @sql ELSE PRINT @crlf + 'GO' + @crlf

set @sql = 'CREATE TRIGGER [tg_' + @table + '_History] 
   ON  ['+@schema+'].['+@table+'] 
   AFTER UPDATE, INSERT
AS 
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO [' + @schema + '].[' + @table + 'History]
    SELECT
		*,
		GETDATE()
	FROM
		Inserted
END'
PRINT @sql
IF @bPrintOnly != 1 EXEC sp_executesql @sql ELSE PRINT @crlf + 'GO' + @crlf

------------------------------------------------------------------------------
-- Do initial population
------------------------------------------------------------------------------

SET @sql = 'INSERT INTO [' + @schema + '].' + @table + 'History 
    SELECT
		*,
		GETDATE()
	FROM
		[' + @schema + '].[' + @table + ']'
    
PRINT @sql
IF @bPrintOnly != 1 EXEC sp_executesql @sql ELSE PRINT @crlf + 'GO' + @crlf

-- Fin
