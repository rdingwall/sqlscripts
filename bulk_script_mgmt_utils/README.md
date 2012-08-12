Bulk SQL Script Management Tools
================================

This is a collection of PowerShell scripts for maintaining numbered SQL script files to support the following practices. Most are RDBMS agnostic (or can be easily adapted).

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

Optionally, for large databases where restoring backups is impractical, DBAs may require you to provide **downgrade** scripts as well:

```
sql/down/
    00001_rollback_prehistoric_export.sql
    00002_rollback_create_table_foo.sql
    00003_rollback_issue_54_fix_some_bug.sql
    00004_rollback_issue_55_fix_some_other_bug.sql
    ...
```

In this technique, every database change must be scripted, including one-time data fixes and static lookup data e.g. adding a new country. This is a good thing: if it's scripted, you know it happened, you can version control it, and you can keep track of what changes have been applied to any given database. And once a script has been applied to a production environment, it can never be changed. Instead, create a new script that does the modification.

Follow the naming convention for delta scripts. Script names must begin with a number that indicates the order in which it should be run (1.sql gets run first, then 2.sql and so on). You can optionally add a comment to the file name to describe what the script does (eg 1 Created the CustomerAddress table.sql) the comment will get written to the schema version table as the script is applied.

#### Script Log / Schema Version Table

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

Many tools such as [dbdeploy](http://dbdeploy.com), [dbdeploy.net](http://dbdeploynet2.codeplex.com) and [roundhouse](https://github.com/chucknorris/roundhouse/wiki) maintain this table for you. However if you are not able to use such a tool (for example, because your DBAs will only accept plain *.sql files), then you need to populate this table yourself: each script must insert a row into the CHANGELOG table to record that the script has completed, and update the schema version.

An example delta/upgrade script might then look like this:

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

Note the changelog insert at the end (and commit\!). This means the schema is strictly versioned (we can tell what version it is on using a query), and at all times *we know exactly what scripts have been run* in the database. The CHANGELOG table contains the following columns:

To ensure every database environment is identical, the same set of scripts is applied against every environment. For technical limitations e.g. no partitioning/materialized view support in Oracle XE, you can use things like PL/SQL IF blocks as a workaround.

*Side note: see the error handling at the top of the file. This is required in every change script because when an error occurs, Oracle's default behaviour is to blindly plow onwards, attempting to execute the rest of the script, leaving the database in an unknown state. Note that you only need to include this line once per script (it is not affected by / delimiters).*

#### Concatenating SQL Scripts

Although we are using separate numbered scripts, some DBAs may prefer to only receive a single SQL script for each release. A PowerShell script is included here to concatenate multiple scripts in the order.

#### Invoking Oracle scripts in SQL*Plus

If your DBAs only use SQL*Plus to run scripts,a PowerShell script is provided for developers to simply call sqlplus.exe in a loop over a directory of scripts (including error handling etc).

#### Testing your upgrade/downgrade scripts in TeamCity

A PowerShell script is included for continuous integration/test driven environments to be used in a TeamCity build to verify all your Oracle upgrade scripts play through successfully in SQL*Plus, from 0001 to n (and ptionally back to 0001 again if you have downgrade scripts). The PowerShell script will:

* Drop and recreate the user (via a separate script, you need to write this), runs all the upgrade scripts, and recompiles all the packages etc.
* Emit specially-formatted messages to the console that can be read by TeamCity build server and provide live progress updates (e.g. the name of the script that is currently executing, and the total number of scripts that were run).
* Run all *.sql scripts in a directory in Oracle SQL*Plus.
* Wrap scripts in PLSQL error handling, and stop on any error.

## Links

You can read more about this style of deployment and its benefits here:

* [Deployment and source-control-friendly database versioning scripts (my blog)](http://richarddingwall.name/2009/02/06/deployment-and-source-control-friendly-database-versioning-scripts/)
* [Database Version Control](http://techportal.ibuildings.com/2011/01/11/database-version-control)
* [Database Continuous Integration Part 1](http://www.pebblesteps.com/post/Database-Continuous-Integration-Part-1.aspx)
* [The road to automated database deployment](http://richarddingwall.name/2011/02/09/the-road-to-automated-database-deployment)