@echo off
REM Description: This script is used to start the container
REM Author: Alexander Gmyrek
REM Date: 2024-10-01

REM Set this variable to the path of the docker container
SET CONTAINER_PATH=C:\Users\Jgrenz\BillingDatabase\ModelBuillingDatabase
SET CONTAINER_NAME=modelbuillingdatabase

REM Frontend and Backend
SET FRONTEND_URL=http://localhost:5000
SET FRONTEND_PORT=5000
SET BACKEND_URL=http://localhost:3000
SET BACKEND_PORT=3000

REM Set this variable if you don't want to start the container
SET DONT_START=0

REM Check if the container is running (if it is, set DONT_START to 1)
ECHO Checking if container is already running
docker ps | findstr /C:"%CONTAINER_NAME%" > nul
IF %ERRORLEVEL%==0 SET DONT_START=1

REM If DONT_START is 1, exit the script
IF %DONT_START%==1 GOTO END
ECHO Container is not already running. Starting container.
REM Change the directory to the container path
CD /D "%CONTAINER_PATH%"

REM Start the container
docker-compose up -d --build --remove-orphans
ECHO Building container
REM Wait for the container to start
timeout /t 30 > nul

:CHECK_CONTAINER_RUNNING
REM Check if the container is running
ECHO Checking if container is running
docker ps | findstr /C:"%CONTAINER_NAME%" > nul
IF %ERRORLEVEL%==0 GOTO CHECK_BACKEND

REM If the container is not running, wait and check again
timeout /t 30 > nul
ECHO Checking again if container is running
docker ps | findstr /C:"%CONTAINER_NAME%" > nul
IF %ERRORLEVEL%==0 GOTO CHECK_BACKEND

REM If the container is not running, wait and check again
timeout /t 30 > nul
docker ps | findstr /C:"%CONTAINER_NAME%" > nul
IF %ERRORLEVEL%==0 GOTO CHECK_BACKEND

REM If the container is not running, wait and check again
timeout /t 30 > nul
ECHO Last checking if container is running
docker ps | findstr /C:"%CONTAINER_NAME%" > nul
IF %ERRORLEVEL%==0 GOTO CHECK_BACKEND

REM Restart the container if it's still not running
ECHO restarting container
docker-compose down
timeout /t 5 > nul
docker-compose up -d --build --remove-orphans
timeout /t 30 > nul
docker ps | findstr /C:"%CONTAINER_NAME%" > nul
IF %ERRORLEVEL%==0 GOTO CHECK_BACKEND

REM Exit if the container could not be started
ECHO The container could not be started: Container is not running
GOTO END

:CHECK_BACKEND
REM Check if the backend is up
ECHO Checking if the backend for the container is working.
FOR /F "delims=" %%i IN ('curl -s -o nul -w "%%{http_code}" %BACKEND_URL%/') DO SET HTTP_STATUS=%%i
IF "%HTTP_STATUS%"=="200" GOTO CHECK_FRONTEND

REM Restart the container and kill processes on the backend port
ECHO The back end isn't working. Restarting Container
docker-compose down
timeout /t 5 > nul
FOR /F "tokens=5" %%A IN ('netstat -ano ^| findstr /C:":%BACKEND_PORT%" ^| findstr /C:"LISTENING"') DO taskkill /F /PID %%A
timeout /t 5 > nul
docker-compose up -d --build --remove-orphans
timeout /t 90 > nul
FOR /F "delims=" %%i IN ('curl -s -o nul -w "%%{http_code}" %BACKEND_URL%/healthcheck') DO SET HTTP_STATUS=%%i
IF "%HTTP_STATUS%"=="200" GOTO CHECK_FRONTEND

REM Exit if the backend could not be started
ECHO The container could not be started: Backend is not up
GOTO END

:CHECK_FRONTEND
REM Check if the frontend is up
FOR /F "delims=" %%i IN ('curl -s -o nul -w "%%{http_code}" %FRONTEND_URL%/healthcheck') DO SET HTTP_STATUS=%%i
IF "%HTTP_STATUS%"=="200" GOTO END

REM Restart the container and kill processes on the frontend port
docker-compose down
timeout /t 5 > nul
FOR /F "tokens=5" %%A IN ('netstat -ano ^| findstr /C:":%FRONTEND_PORT%" ^| findstr /C:"LISTENING"') DO taskkill /F /PID %%A
timeout /t 5 > nul
docker-compose up -d --build --remove-orphans
timeout /t 90 > nul
FOR /F "delims=" %%i IN ('curl -s -o nul -w "%%{http_code}" %FRONTEND_URL%/healthcheck') DO SET HTTP_STATUS=%%i
IF "%HTTP_STATUS%"=="200" GOTO END

REM Exit if the frontend could not be started
ECHO The container could not be started: Frontend is not up
GOTO END

:END
REM Script ends here
