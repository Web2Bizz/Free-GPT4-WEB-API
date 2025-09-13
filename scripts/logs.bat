@echo off
setlocal enabledelayedexpansion

REM FreeGPT4 API Log Management Script for Windows

REM Default values
set SERVICE_NAME=api
set LOG_FILE=logs\freegpt4.log
set FOLLOW=false
set LEVEL=
set LINES=50

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :main
if "%~1"=="-f" (
    set FOLLOW=true
    shift
    goto :parse_args
)
if "%~1"=="--follow" (
    set FOLLOW=true
    shift
    goto :parse_args
)
if "%~1"=="-l" (
    set LINES=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--lines" (
    set LINES=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--level" (
    set LEVEL=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--file" (
    set LOG_FILE=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--service" (
    set SERVICE_NAME=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--clean" (
    call :clean_logs
    exit /b 0
)
if "%~1"=="--stats" (
    call :show_stats
    exit /b 0
)
if "%~1"=="--help" (
    call :show_usage
    exit /b 0
)
echo Unknown option: %~1
call :show_usage
exit /b 1

:main
REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not running or not accessible
    exit /b 1
)

REM If LOG_FILE is specified, read from file, otherwise use Docker logs
if "%LOG_FILE:~0,6%"=="logs\" (
    call :show_log_file
) else (
    call :check_service
    call :show_logs
)
exit /b 0

:show_usage
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   -f, --follow          Follow log output in real-time
echo   -l, --lines N         Number of lines to show (default: 50)
echo   --level LEVEL         Filter by log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
echo   --file FILE           Log file to read (default: logs\freegpt4.log)
echo   --service NAME        Docker service name (default: api)
echo   --help                Show this help message
echo.
echo Examples:
echo   %~nx0 -f                                    # Follow logs in real-time
echo   %~nx0 -l 100                               # Show last 100 lines
echo   %~nx0 --level ERROR                        # Show only ERROR logs
echo   %~nx0 --file logs\freegpt4-dev.log -f      # Follow dev logs
echo   %~nx0 --service api --level DEBUG -l 200   # Show last 200 DEBUG lines from api service
exit /b 0

:check_service
docker-compose ps %SERVICE_NAME% | findstr "Up" >nul
if errorlevel 1 (
    echo Warning: Service '%SERVICE_NAME%' is not running
    echo Starting service...
    docker-compose up -d %SERVICE_NAME%
    timeout /t 5 /nobreak >nul
)
exit /b 0

:show_logs
set CMD=docker-compose logs
if "%FOLLOW%"=="true" set CMD=%CMD% -f
if %LINES% gtr 0 set CMD=%CMD% --tail=%LINES%
set CMD=%CMD% %SERVICE_NAME%

if not "%LEVEL%"=="" (
    echo Filtering logs by level: %LEVEL%
    %CMD% | findstr /i "%LEVEL%"
) else (
    %CMD%
)
exit /b 0

:show_log_file
if not exist "%LOG_FILE%" (
    echo Error: Log file '%LOG_FILE%' not found
    exit /b 1
)

set CMD=type
if "%FOLLOW%"=="true" set CMD=type
if %LINES% gtr 0 set CMD=more +%LINES%

if not "%LEVEL%"=="" (
    echo Filtering logs by level: %LEVEL%
    %CMD% "%LOG_FILE%" | findstr /i "%LEVEL%"
) else (
    %CMD% "%LOG_FILE%"
)
exit /b 0

:clean_logs
echo Cleaning old log files...
REM Remove log files older than 7 days (Windows doesn't have find -mtime, so we'll use a different approach)
forfiles /p logs /m *.log* /d -7 /c "cmd /c del @path" 2>nul
echo Log cleanup completed
exit /b 0

:show_stats
echo Log Statistics:
echo ==================
if exist "%LOG_FILE%" (
    echo File: %LOG_FILE%
    for %%A in ("%LOG_FILE%") do echo Size: %%~zA bytes
    echo Last modified: %~t1
    echo.
    echo Log level distribution:
    findstr /c:"DEBUG" "%LOG_FILE%" 2>nul | find /c /v "" >nul && echo DEBUG: !ERRORLEVEL! || echo DEBUG: 0
    findstr /c:"INFO" "%LOG_FILE%" 2>nul | find /c /v "" >nul && echo INFO: !ERRORLEVEL! || echo INFO: 0
    findstr /c:"WARNING" "%LOG_FILE%" 2>nul | find /c /v "" >nul && echo WARNING: !ERRORLEVEL! || echo WARNING: 0
    findstr /c:"ERROR" "%LOG_FILE%" 2>nul | find /c /v "" >nul && echo ERROR: !ERRORLEVEL! || echo ERROR: 0
    findstr /c:"CRITICAL" "%LOG_FILE%" 2>nul | find /c /v "" >nul && echo CRITICAL: !ERRORLEVEL! || echo CRITICAL: 0
) else (
    echo Log file not found: %LOG_FILE%
)
exit /b 0
