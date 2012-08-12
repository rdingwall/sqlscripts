-- Find columns on tables with names like <Blah>ID which should be part of
-- primary or foreign keys, but aren't.
-- http://richarddingwall.name/2008/12/21/find-missing-foreignprimary-keys-in-sql-server/

SELECT
	s.name As [Schema],
	t.name AS [Table],
	c.name AS [Column]
FROM
	sys.tables t
	INNER JOIN sys.schemas s ON
		s.schema_id = t.schema_id
	INNER JOIN sys.syscolumns c ON
		c.id = t.object_id
	
	-- Join on foreign key columns
	LEFT JOIN sys.foreign_key_columns fkc ON
		(fkc.parent_object_id = t.object_id
		AND c.colid = fkc.parent_column_id)
		OR (fkc.referenced_object_id = t.object_id
		AND c.colid = fkc.referenced_column_id)
	
	-- Join on primary key columns
	LEFT JOIN sys.indexes i ON
		i.object_id = t.object_id
		and i.is_primary_key = 1
	LEFT JOIN sys.index_columns ic ON
		ic.object_id = t.object_id
		AND ic.index_id = i.index_id
		AND ic.column_id = c.colid
WHERE
	t.is_ms_shipped = 0
	AND (c.name LIKE '%ID' OR c.name LIKE '%Code')
	AND
	(
		fkc.constraint_object_id IS NULL -- Not part of a foreign key 
		AND ic.object_id IS NULL -- Not part of a primary key
	)
	AND
	(
		-- Ignore some tables
		t.name != 'sysdiagrams'
		AND t.name NOT LIKE '[_]%'
		AND t.name NOT LIKE '%temp%'
		AND t.name NOT LIKE '%History%' -- audit tables don't use FKs because they link to potentially deleted data
		
		-- Ignore some columns
		AND c.name NOT LIKE '%Valid%' -- not keys
	)
ORDER BY
	s.name,
	t.name,
	c.name