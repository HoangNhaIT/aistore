@echo off
chcp 65001 >nul
title Day Ma Nguon CCCD NFC Reader Len GitHub

echo ======================================================================
echo    TỰ ĐỘNG ĐẨY MÃ NGUỒN LÊN GITHUB & KÍCH HOẠT CLOUD BUILD APK/IPA
echo ======================================================================
echo.

cd /d "%~dp0"

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [1/3] May chua co Git, dang tu dong cai dat Git qua winget...
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    if %errorlevel% neq 0 (
        echo [Loi] Khong the tu dong cai Git. Ban hay tai va cai Git tai: https://git-scm.com/
        pause
        exit /b 1
    )
    set "PATH=C:\Program Files\Git\cmd;%PATH%"
) else (
    echo [OK] Git da san sang.
)

echo.
echo [2/3] Chuan bi kho chua Git local...
if not exist ".git" (
    git init
    git branch -M main
)

git add .
git commit -m "Khoi tao ung dung doc chip CCCD NFC Flutter cho Android va iOS"

echo.
echo [3/3] Ket noi voi GitHub:
echo Ban hay tao 1 repository moi tren GitHub (https://github.com/new), sau do copy link repo dan vao day.
set /p REPO_URL="Nhap link GitHub Repo (VD: https://github.com/tenban/cccd_nfc_reader.git): "

if "%REPO_URL%"=="" (
    echo [Thong bao] Ban chua nhap link. Code da duoc commit o local. Ban co the push len sau.
    pause
    exit /b 0
)

git remote remove origin >nul 2>&1
git remote add origin %REPO_URL%
git push -u origin main --force

echo.
echo ======================================================================
echo [THANH CONG] Ma nguon da duoc day len GitHub!
echo He thong GitHub Actions se tu dong build 2 file:
echo    1. CCCD_NFC_Reader_Android.apk (Cho Android)
echo    2. CCCD_NFC_Reader_iOS.ipa (Cho iPhone)
echo.
echo Ban chi can vao tab "Actions" tren GitHub cua ban de tai file ve dung.
echo ======================================================================
pause
