-- Recompile all packages etc in an Oracle schema.
DECLARE
  this_schema VARCHAR2(100);
BEGIN
  -- Recompile anything which may have broken as a result of adding columns to
  -- views etc. Substitute your own schema if different.
  SELECT sys_context('USERENV', 'CURRENT_SCHEMA') into this_schema FROM DUAL;
  -- this_schema := 'MY_APP';
  DBMS_UTILITY.compile_schema(schema => this_schema);
END;
/