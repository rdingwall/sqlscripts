------------------------------------------------------------------------------
-- Create a snapshot that we can rollback to.
------------------------------------------------------------------------------
CREATE DATABASE XyzSnapshot ON
(
	NAME = 'Xyz_Data',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Data\XyzSnapshot.ds'
),
(
	NAME = 'Xyz_FullText',
	FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Data\XyzFullTextSnapshot.ds'
)
AS SNAPSHOT OF Xyz

------------------------------------------------------------------------------
-- Kick everyone off so we can restore a snapshot
------------------------------------------------------------------------------
USE master
ALTER DATABASE Xyz SET SINGLE_USER WITH ROLLBACK IMMEDIATE

------------------------------------------------------------------------------
-- Restore a snapshot
------------------------------------------------------------------------------
USE master
RESTORE DATABASE Xyz FROM DATABASE_SNAPSHOT = 'XyzSnapshot'

------------------------------------------------------------------------------
-- Delete a snapshot
------------------------------------------------------------------------------
-- DROP DATABASE XyzSnapshot
