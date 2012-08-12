with
table_space_usage ( schema_name, table_name, used, reserved, ind_rows, tbl_rows )
AS (SELECT 
s.Name
, o.Name
, p.used_page_count * 8
, p.reserved_page_count * 8
, p.row_count
, case when i.index_id in ( 0, 1 ) then p.row_count else 0 end
FROM sys.dm_db_partition_stats p
INNER JOIN sys.objects as o ON o.object_id = p.object_id
INNER JOIN sys.schemas as s ON s.schema_id = o.schema_id
LEFT OUTER JOIN sys.indexes as i on i.object_id = p.object_id and i.index_id = p.index_id
WHERE o.type_desc = 'USER_TABLE' and o.is_ms_shipped = 0)

SELECT t.schema_name
, t.table_name
, sum(t.used) as used_in_kb
, sum(t.reserved) as reserved_in_kb
,sum(t.tbl_rows) as rows

FROM table_space_usage as t

GROUP BY t.schema_name , t.table_name  

ORDER BY used_in_kb desc
 