Bulk SQL Script Management Tools
================================

This is a collection of PowerShell scripts for maintaining numbered SQL script files.

#### Numbered Scripts / Schema Versioning

To improve our database development and deployment practice (specifically around continuous integration and integration testing), database objects are checked into source control as a series of numbered .sql scripts that, when executed in order, produce a complete database schema including tables, views, packages, and with all static data inserted. For example:

```
sql/up/
    00001_prehistoric_export.sql
    00002_create_table_foo.sql
    00003_issue_54_fix_some_bug.sql
    00004_issue_55_fix_some_other_bug.sql
    ...
```

Every change must be scripted (including one-time data fixes). This is a good thing: if it's scripted, you know it happened, you can version control it, and you can keep track of what changes have been applied to any given database.

Follow the naming convention for delta scripts. Script names must begin with a number that indicates the order in which it should be run (1.sql gets run first, then 2.sql and so on). You can optionally add a comment to the file name to describe what the script does (eg 1 Created the CustomerAddress table.sql) the comment will get written to the schema version table as the script is applied.

Included are a number of scripts for numbering and re-numbering SQL script filenames.

#### Script Log Table

Now each script has a number, we can effectively use that as the database schema version. (The number of the last-run script). In order to do this, we need to keep some record of which scripts have been run. Typically this is just stored in a table:

```sql
CREATE TABLE CHANGELOG
(
    VERSION_NUMBER, -- the schema version e.g. 00001
    FILE_NAME, -- the script's file name e.g. 00001_prehistoric_export.sql
    RUN_DATE, -- time at which the script was run
    RUN_BY -- user who ran it
)
```
The current schema version of the database can be queried as `SELECT MAX(VERSION_NUMBER) FROM CHANGELOG`. If this does not match the expected value, the application should refuse to start up.

Many tools such as [dbdeploy](http://dbdeploy.com), [dbdeploy.net](http://dbdeploynet2.codeplex.com) and [roundhouse](https://github.com/chucknorris/roundhouse/wiki) maintain this table for you.

However if you are not able to use such a tool (for example, because the DBAs will only accept plain *.sql files) you need to populate this table yourself: each script must insert a row into the CHANGELOG table to record that the script has completed, and update the schema version.

An example delta/upgrade script might then look like example:

```sql
-- 00003_issue_54_fix_some_bug.sql

-- required at the top of every script, because Oracle doesn't do this by default.
whenever sqlerror exit sql.sqlcode rollback;

-- make your schema changes
ALTER TABLE ...;
INSERT INTO ...;
CREATE OR REPLACE VIEW ...;

-- update CHANGELOG table
INSERT INTO CHANGELOG (VERSION_NUMBER, FILE_NAME) VALUES (3, '00003_issue_54_fix_some_bug.sql');
COMMIT;
```

*Side note: see the error handling at the top of the file. This is required in every change script because when an error occurs, Oracle's default behaviour is to blindly plow onwards, attempting to execute the rest of the script, leaving the database in an unknown state. Note that you only need to include this line once per script (it is not affected by `/` delimiters).*

Also note the changelog insert at the end (and commit\!). This means the schema is strictly versioned (we can tell what version it is on using a query), and at all times *we know exactly what scripts have been run* in the database. The CHANGELOG table contains the following columns:


To ensure every database environment is identical, the same set of scripts is applied against every environment. (For technical limitations e.g. no partitioning in Oracle XE, use PL/SQL IF blocks).

Once a script has been applied to a production environment, it can never be changed. Instead, create a new script that does the modification.

# Tooling and automation

TBA. Because all our scripts have to run in SQL*Plus, we simply have a PowerShell script to call sqlplus.exe in a loop. This will be improved over time.

# Migrating from previous structure

Previously all database objects existed as separate files, with deltas for later structural changes. These have all been concatenated together as one large "prehistoric export" script (script #00001). This required:

* Determining the correct order (e.g. dependent objects).
* Fixing numerous bugs and errors in the scripts (not surprising considering they have never all been run together before\!)
* Any untracked changes in PROD and UAT have been detected and scripted out using [Schema Compare for Oracle|http://www.red-gate.com/products/oracle-development/schema-compare-for-oracle/]
* Any untracked static reference/mapping data in PROD has been scripted out using [Data Compare for Oracle|http://www.red-gate.com/products/oracle-development/data-compare-for-oracle/]
* Script #00001 also creates the requisite CHANGELOG table.

Numbered deltas must now be used for all future changes.

# FAQ

#### Why not use [dbdeploy|http://dbdeploy.com], [dbdeploy.net|http://dbdeploynet2.codeplex.com/], [﻿roundhouse|https://github.com/chucknorris/roundhouse/wiki] etc? They already do this\!

There are a lot of great tools for database versioning we could use, but while DBAs still have to manually perform every deployment, our options are limited to whatever they will support (SQL*Plus).

In future we would definitely like to use such a tool to fully automate database deployments, and eliminate the current risk of human error from manually running database scripts against PROD.

#### Why do we have to INSERT INTO CHANGELOG manually in each script? Most tools do this already.

See above question about tools.

#### I'm still unconvinced. Where can I read more?

You can read more about this style of deployment and its benefits here:
* [Database Version Control|http://techportal.ibuildings.com/2011/01/11/database-version-control/]
* [Database Continuous Integration Part 1|http://www.pebblesteps.com/post/Database-Continuous-Integration-Part-1.aspx]
* [The road to automated database deployment|http://richarddingwall.name/2011/02/09/the-road-to-automated-database-deployment/]