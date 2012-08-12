-- Query to find all downstream dependencies of an object in Oracle 11g R2+. For
-- example, stored procedure SP selects from a view VW over table TB, therefore
-- TB's downstream dependencies are VW and SP.
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
    -- Optional: limit search to only components referenced by object X
    --AND NAME = 'MYTABLE'
    
  UNION ALL
  
  SELECT
    a.NAME,
    d.REFERENCED_NAME,
    d.TYPE
  FROM
    RECURSIVE_DEPENDENCY a 
    INNER JOIN ALL_DEPENDENCIES d ON
      d.NAME = a.REFERENCED_NAME
      AND d.referenced_type != 'PACKAGE'
       -- exclude objects that are dependent on themselves
      AND d.REFERENCED_NAME != d.NAME
      AND d.OWNER = 'MYAPP'
)
SELECT DISTINCT
  NAME,
  REFERENCED_NAME AS USES,
  TYPE
FROM
  RECURSIVE_DEPENDENCY
ORDER BY
  TYPE,
  REFERENCED_NAME;