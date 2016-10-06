@echo off
rem PATH=D:\Anaconda;%PATH%
rem python scour.py -i %1 -o ..\%1 --indent=none --shorten-ids --enable-comment-stripping --remove-metadata --enable-viewboxing
for /r %%i in (*.svg) do (
    echo Limpando %%~nxi
    python scour.py -i %%~nxi -o ..\%%~nxi --indent=none --shorten-ids --enable-comment-stripping --remove-metadata --enable-viewboxing
)