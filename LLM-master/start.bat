@echo off

cd /d "c:\market_app 1\LLM-master"

call venv\Scripts\activate.bat

set PYTHONIOENCODING=utf-8

uvicorn main:app --host 0.0.0.0 --port 8001 --workers 1

pause