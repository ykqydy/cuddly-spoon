@echo off
call "D:\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64
if %errorlevel% neq 0 (
    echo [ERROR] vcvarsall.bat failed
    exit /b 1
)
echo [BUILD] %1 configuration...
"D:\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" zzr1213_MoveandCut\zzr1213_MoveandCut.vcxproj /p:Configuration=%1 /p:Platform=x64
if %errorlevel% neq 0 (
    echo [ERROR] Build failed
    exit /b 1
)
echo [SUCCESS] Build completed: %1
