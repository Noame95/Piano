@echo off

tasm piano.asm
if errorlevel 1 goto error

tlink piano.obj
if errorlevel 1 goto error

piano.exe
goto end

:error
echo Build failed!

:end
