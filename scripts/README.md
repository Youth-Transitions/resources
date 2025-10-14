These scripts are intended for use with the LEO (Longitudinal Education Outcomes) dataset supplied within the SRS (Secure Research Service). In order to make use of them, however, there are a few necessary housekeeping tasks that must be completed for each project.

## References

Data from the LEO dataset are supplied in a series views in multiple databases on a single SQL Server instance. Each project's views are in a schema identified by project number; you will therefore need to edit the scripts to reference the correct project views.

You can use find and replace (Ctrl H) to replace the text `<project number>` with your projects number. If you are comfortable with it, you can use Notepad++ (which is available in this environment) to perform these replacements on all scripts at once: on the Find/Replace prompt, select the "Find in Files" tab and use the "Replace in Files" option (the "Directory" needs to be writeable, so you will need to copy the scripts to somewhere in your Working folder).

## Data scope

The scripts are designed to accommodate for only a subset of data sources being available. For example, if you requested data from 2014-2018 rather than the full year range, it will load only those years that are available and the absence of views relating to data outside the available range (School Census and HESA are provided with each collection in its own view) will not cause issues.

While the absence of a view will not cause problems, the absence of an expected column *will* cause an error to appear when the script is run. Since these scripts are written to cater for as much as possible, some scripts, particularly the School Census one (`fft.census.sql`), will inevitably throw errors at first.

When the error appears, double click the red text in the Messages window of SSMS (SQL Server Management Studio) and it will highlight the missing column. You can replace the value (or expression) with `null` to enable it to load.

## Non-LEO uses

These scripts are designed to be used with the LEO dataset, but since they are intended to be relatively easy to understand (with some SQL knowledge) they could be used as a starting point for scripts working with the same (or similar) data from other sources, particularly NPD (National Pupil Database). You will need to adjust refererences (NPD is typically provided as tables in the project database) and make some admendments, such as reworking the person lookup (since `AE_ID` is specific to LEO) and using the non-anonymised institution references (`LAESTAB`, `URN`, `UKPRN`, etc.).
