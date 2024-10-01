@echo off
REM Description: This script is used to back up a MySQL database
REM Author: Your Name
REM Date: 2024-10-01

REM Configuration Variables
SET MYSQL_USER=root
SET MYSQL_PASSWORD=yourpassword
SET MYSQL_DATABASE=yourdatabase
SET BACKUP_DIR=C:\Backups\MySQL
SET RETENTION_DAYS=90

REM Get current date and time for the backup filename
SET DATETIME=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
SET DATETIME=%DATETIME: =0%

REM Create backup directory if it doesn't exist
IF NOT EXIST "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
    IF ERRORLEVEL 1 (
        ECHO Failed to create backup directory: %BACKUP_DIR%
        GOTO END
    )
)

REM Backup the database
SET BACKUP_FILE=%BACKUP_DIR%\%MYSQL_DATABASE%_%DATETIME%.sql

ECHO Backing up database %MYSQL_DATABASE% to %BACKUP_FILE%
mysqldump -u%MYSQL_USER% -p%MYSQL_PASSWORD% %MYSQL_DATABASE% > "%BACKUP_FILE%"
IF ERRORLEVEL 1 (
    ECHO Backup failed!
    GOTO END
) ELSE (
    ECHO Backup succeeded: %BACKUP_FILE%
)

REM Compress the backup file (optional)
REM Uncomment the following lines if you have 7-Zip installed and want to compress the backup

REM SET ZIP_FILE=%BACKUP_FILE%.zip
REM "C:\Program Files\7-Zip\7z.exe" a "%ZIP_FILE%" "%BACKUP_FILE%"
REM IF ERRORLEVEL 1 (
REM     ECHO Compression failed!
REM ) ELSE (
REM     ECHO Compression succeeded: %ZIP_FILE%
REM     DEL "%BACKUP_FILE%"
REM )

REM Delete backups older than RETENTION_DAYS
ECHO Deleting backups older than %RETENTION_DAYS% days...
forfiles /p "%BACKUP_DIR%" /s /m *.sql /d -%RETENTION_DAYS% /c "cmd /c del @path"
IF ERRORLEVEL 1 (
    ECHO Failed to delete old backups.
) ELSE (
    ECHO Old backups deleted successfully.
)

:END
REM Script ends here
