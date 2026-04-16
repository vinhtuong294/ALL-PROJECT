@echo off

cd /d D:\LLM\code\chatbot_api

call C:\Users\ADMIN\miniconda3\Scripts\activate.bat chatbot

python -m uvicorn main:app --host 0.0.0.0 --port 8000

pause