@echo off
REM Activate fastapi-py312 environment and start uvicorn server
echo Starting FastAPI server...
C:\Users\Magiauy\.conda\envs\fastapi-py312\Scripts\uvicorn.exe app.main:app --reload --host 127.0.0.1 --port 8000
pause
