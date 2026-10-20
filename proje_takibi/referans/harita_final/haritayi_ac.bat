@echo off
rem Haritayi yerel bir sunucudan acar (index.html'i dogrudan acmak da cogu tarayicida calisir).
cd /d "%~dp0goruntuleyici"
start "" http://127.0.0.1:8731/
python -m http.server 8731 --bind 127.0.0.1
