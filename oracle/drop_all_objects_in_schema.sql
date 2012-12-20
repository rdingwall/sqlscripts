-- Drop all objects in an Oracle schema. Useful for locked down servers when you
-- need a fresh empty database, but you don't have permissions to simply drop
-- and recreate the entire user. 

-- This script will destroy all objects in the schema!! Use with caution!!
whenever sqlerror exit sql.sqlcode rollback;
set serveroutput on;
declare
  cursor c_get_objects is
    select object_type,'"'||object_name||'"'||decode(object_type,'TABLE' ,' cascade constraints purge',null) obj_name
    from user_objects
    where object_type in ('TABLE','VIEW','PACKAGE','SEQUENCE','SYNONYM', 'MATERIALIZED VIEW')
    and object_name not like 'MLOG$%' -- materialized log view tables (will be dropped automatically)
    and object_name not like 'RUPD$%' -- ignore updateable snapshots
    order by object_type;
    
  cursor c_get_types is
    select object_type, '"'||object_name||'"' obj_name
    from user_objects
    where object_type in ('TYPE');
    
  v_sql varchar2(255);
  
begin
  for object_rec in c_get_objects loop
    v_sql := 'drop '||object_rec.object_type||' ' ||object_rec.obj_name;
    dbms_output.put_line(v_sql);
    execute immediate (v_sql);
  end loop;
  for object_rec in c_get_types loop
  begin
    v_sql := 'drop '||object_rec.object_type||' ' ||object_rec.obj_name;
    dbms_output.put_line(v_sql);
    execute immediate (v_sql);
  end;
  end loop;
end;
/
purge recyclebin;
