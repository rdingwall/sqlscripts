-- Drop all objects in a Microsoft SQL Server Database including schemas. Useful
-- for locked down servers when you need a fresh empty database, but you don't
-- have permissions to simply drop and recreate the entire database. Based on
-- original by Adam Anderson:
-- http://blog.falafel.com/Blogs/AdamAnderson/09-01-06/T-SQL_Drop_All_Objects_in_a_SQL_Server_Database.aspx

-- This script will destroy all objects in the schema!! Use with caution!!

declare @n char(1)
set @n = char(10)

declare @stmt nvarchar(max)

-- procedures
select @stmt = isnull( @stmt + @n, '' ) +
    'drop procedure [' + name + ']'
from sys.procedures

-- check constraints
select @stmt = isnull( @stmt + @n, '' ) +
    'alter table [' + schema_name(t.schema_id) + '].[' + t.name + '] drop constraint [' + c.name + ']'
from sys.check_constraints c
inner join sys.tables t on
	t.object_id = c.parent_object_id

-- functions
select @stmt = isnull( @stmt + @n, '' ) +
    'drop function [' + name + ']'
from sys.objects
where type in ( 'FN', 'IF', 'TF' )

-- views
select @stmt = isnull( @stmt + @n, '' ) +
    'drop view [' + name + ']'
from sys.views

-- foreign keys
select @stmt = isnull( @stmt + @n, '' ) +
    'alter table [' + schema_name(t.schema_id) + '].[' + t.name + '] drop constraint [' + f.name + ']'
from sys.foreign_keys f
inner join sys.tables t on
	t.object_id = f.parent_object_id

-- tables
select @stmt = isnull( @stmt + @n, '' ) +
    'drop table [' + schema_name(schema_id) + '].[' + name + ']'
from sys.tables

-- user defined types
select @stmt = isnull( @stmt + @n, '' ) +
    'drop type [' + name + ']'
from sys.types
where is_user_defined = 1

-- schemas
select @stmt = isnull( @stmt + @n, '' ) +
    'drop schema [' + name + ']'
from sys.schemas 
where name not in ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
	and name not like ('db_%')

exec sp_executesql @stmt