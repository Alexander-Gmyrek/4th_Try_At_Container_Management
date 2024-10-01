@echo off
REM Description: This script is used to restore a MySQL database from a backup
REM Author: Your Name
REM Date: 2024-10-01

REM Configuration Variables
SET MYSQL_USER=root
SET MYSQL_PASSWORD=yourpassword
SET MYSQL_DATABASE=yourdatabase
SET BACKUP_DIR=C:\Backups\MySQL
SET USE_7ZIP=0  REM Set to 1 if you want to use 7-Zip for compressed backups

REM Check if backup directory exists
IF NOT EXIST "%BACKUP_DIR%" (
    ECHO Backup directory does not exist: %BACKUP_DIR%
    GOTO END
)

REM List available backup files
ECHO Available backup files:
DIR /B /O-D "%BACKUP_DIR%\%MYSQL_DATABASE%_*.sql"
IF %USE_7ZIP%==1 (
    DIR /B /O-D "%BACKUP_DIR%\%MYSQL_DATABASE%_*.sql.zip"
)

REM Prompt user to enter the backup filename
SET /P BACKUP_FILE="Enter the backup filename (with extension) to restore: "

REM Check if the backup file exists
IF NOT EXIST "%BACKUP_DIR%\%BACKUP_FILE%" (
    ECHO Backup file not found: %BACKUP_FILE%
    GOTO END
)

REM If the backup is compressed, decompress it first
SET BACKUP_FILE_PATH=%BACKUP_DIR%\%BACKUP_FILE%
SET FILE_EXTENSION=%BACKUP_FILE_PATH:~-4%

IF /I "%FILE_EXTENSION%"==".zip" (
    IF %USE_7ZIP%==0 (
        ECHO 7-Zip functionality is disabled. Cannot decompress the backup file.
        GOTO END
    )
    REM Decompress the backup file
    SET EXTRACTED_SQL=%BACKUP_FILE_PATH:~0,-4%
    "C:\Program Files\7-Zip\7z.exe" e "%BACKUP_FILE_PATH%" -o"%BACKUP_DIR%" -y
    IF ERRORLEVEL 1 (
        ECHO Failed to decompress backup file.
        GOTO END
    ) ELSE (
        ECHO Backup file decompressed: %EXTRACTED_SQL%
    )
    SET BACKUP_FILE_PATH=%EXTRACTED_SQL%
)

REM Confirm restoration
ECHO WARNING: This will overwrite the existing database: %MYSQL_DATABASE%
SET /P CONFIRM="Are you sure you want to proceed? (Y/N): "
IF /I NOT "%CONFIRM%"=="Y" GOTO CLEANUP

REM Restore the database
ECHO Restoring database %MYSQL_DATABASE% from %BACKUP_FILE_PATH%
mysql -u%MYSQL_USER% -p%MYSQL_PASSWORD% %MYSQL_DATABASE% < "%BACKUP_FILE_PATH%"
IF ERRORLEVEL 1 (
    ECHO Database restoration failed!
    GOTO CLEANUP
) ELSE (
    ECHO Database restored successfully.
)

:CLEANUP
REM If we decompressed a file, delete the extracted .sql file
IF /I "%FILE_EXTENSION%"==".zip" (
    DEL /F /Q "%EXTRACTED_SQL%"
)

:END
REM Script ends here
