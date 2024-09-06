@echo off
setlocal

:: Variables
set "SOURCE_HOST=localhost"        :: IP address of the source PostgreSQL server
set "SOURCE_USER=postgres"         :: PostgreSQL username on the source server
set "SOURCE_PASSWORD=password" :: PostgreSQL password on the source server
set "TARGET_HOST=8.8.8.8"      :: IP address of the target PostgreSQL server
set "TARGET_USER=postgres"             :: PostgreSQL username on the target server (for restore operation)
set "TARGET_PASSWORD=password" :: PostgreSQL password on the target server
set "SSH_USER=Administrator"         :: OS username on the target server (for SSH access)
set "SSH_PASSWORD=password" :: SSH password for the target server


set "SUCCESS=1"

:: Check if the dump or zip files exist and skip dumping if found
if exist all_databases.sql (
    echo Found existing dump file all_databases.sql. Skipping dump.
) else if exist all_databases.zip (
    echo Found existing ZIP file all_databases.zip. Skipping dump and compression.
) else (
    echo Dumping all databases...
    set PGPASSWORD=%SOURCE_PASSWORD%
    pg_dumpall -h %SOURCE_HOST% -U %SOURCE_USER% -f all_databases.sql

    if not exist all_databases.sql (
        echo Error: Dump file was not created.
        set "SUCCESS=0"
        goto :cleanup
    )

    echo Compressing the dump file...
    "C:\Program Files\7-Zip\7z.exe" a -tzip all_databases.zip all_databases.sql

    if not exist all_databases.zip (
        echo Error: ZIP file was not created.
        set "SUCCESS=0"
        goto :cleanup
    )
)

:: Transfer ZIP file to the target server
echo Transferring zip file to target server...
pscp -pw %SSH_PASSWORD% all_databases.zip %SSH_USER%@%TARGET_HOST%:C:/Users/%SSH_USER%/

if %ERRORLEVEL% neq 0 (
    echo Error: Transfer failed.
    set "SUCCESS=0"
)

:cleanup
:: Optionally clean up local files if transfer was successful
if %SUCCESS% equ 1 (
    echo Cleaning up...
    del all_databases.sql
    del all_databases.zip
) else (
    echo Not deleting files due to errors.
)

endlocal
