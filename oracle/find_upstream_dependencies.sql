-- Query to find all upstream dependencies of an object in Oracle 11g R2+. For
-- example, stored procedure SP selects from a view VW over table TB, therefore
-- SP's downstream dependencies are VW and TB.
WITH RECURSIVE_DEPENDENCY(NAME, REFERENCED_NAME, TYPE) AS
(
  SELECT
    NAME,
    REFERENCED_NAME,
    TYPE
  FROM
    ALL_DEPENDENCIES
  WHERE
    REFERENCED_TYPE  != 'PACKAGE'
    AND OWNER = 'MYAPP'
    -- Optional: limit search to only what depends on object X
    AND REFERENCED_NAME = 'MYTABLE'
    
  UNION ALL
  
  SELECT
    d.NAME,
    a.REFERENCED_NAME,
    d.TYPE
  FROM
    RECURSIVE_DEPENDENCY a 
    INNER JOIN ALL_DEPENDENCIES d ON
      d.REFERENCED_NAME = a.NAME
      AND d.referenced_type != 'PACKAGE'
       -- exclude objects that are dependent on themselves
      AND d.NAME != d.REFERENCED_NAME
      AND d.OWNER = 'MYAPP'
)
SELECT DISTINCT
  REFERENCED_NAME AS NAME,
  NAME AS USED_BY,
  TYPE
FROM
  RECURSIVE_DEPENDENCY
ORDER BY
  TYPE,
  REFERENCED_NAME;