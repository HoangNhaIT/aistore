@echo off
chcp 65001 >nul
title Day Ma Nguon CCCD NFC Reader Len GitHub
cls

echo ======================================================================
echo    TỰ ĐỘNG ĐẨY MÃ NGUỒN LÊN GITHUB & KÍCH HOẠT CLOUD BUILD APK/IPA
echo ======================================================================
echo.

cd /d "%~dp0"

set "GIT_DIR=C:\Users\Hoang Nha IT\AppData\Local\Microsoft\WinGet\Packages\Git.MinGit_Microsoft.Winget.Source_8wekyb3d8bbwe\cmd"
set "GH_DIR=C:\Users\Hoang Nha IT\AppData\Local\Microsoft\WinGet\Packages\GitHub.cli_Microsoft.Winget.Source_8wekyb3d8bbwe\bin"
set "PATH=%GIT_DIR%;%GH_DIR%;%PATH%"

echo [1/3] Kiểm tra Git local...
git add .
git commit -m "Complete CCCD NFC Reader with Android & iOS support" >nul 2>&1
echo       ✓ Đã chuẩn bị xong mã nguồn!

echo.
echo [2/3] Cấu hình GitHub Repository:
echo       https://github.com/HoangNhaIT/aistore.git
git remote remove origin >nul 2>&1
git remote add origin https://github.com/HoangNhaIT/aistore.git

echo.
echo ======================================================================
echo    BẠN CẦN NHẬP GITHUB TOKEN ĐỂ ĐẨY CODE (DO GITHUB YÊU CẦU BẢO MẬT)
echo ======================================================================
echo.
echo 👉 Nếu bạn đã có Personal Access Token (bắt đầu bằng ghp_...):
echo    Hãy dán mã Token vào bên dưới rồi nhấn Enter.
echo.
echo 👉 Nếu chưa có Token, hãy nhấn ENTER để trình duyệt tự mở trang tạo Token
echo    (Trang web sẽ tự tích sẵn quyền, bạn chỉ cần cuộn xuống cuối bấm Generate).
echo.
set /p TOKEN="Nhập GitHub Token (hoặc nhấn Enter để tạo mới): "

if "%TOKEN%"=="" (
    echo.
    echo Đang mở trình duyệt tạo Token cho bạn...
    start https://github.com/settings/tokens/new?scopes=repo,workflow^&description=CCCD_NFC_Builder
    echo.
    echo Sau khi tạo xong, bạn hãy copy mã Token (dạng ghp_xxxx) và dán vào đây:
    set /p TOKEN="Dán mã Token vào đây: "
)

if "%TOKEN%"=="" (
    echo [Lỗi] Bạn chưa nhập Token. Không thể đẩy code lên GitHub.
    pause
    exit /b 1
)

echo.
echo [3/3] Đang đẩy code lên https://github.com/HoangNhaIT/aistore.git ...
git push "https://%TOKEN%@github.com/HoangNhaIT/aistore.git" main --force

if %errorlevel% equ 0 (
    echo.
    echo ======================================================================
    echo    🎉🎉🎉 ĐÃ ĐẨY CODE LÊN GITHUB THÀNH CÔNG!
    echo ======================================================================
    echo.
    echo Đang tự động mở tab Actions trên trình duyệt...
    start https://github.com/HoangNhaIT/aistore/actions
    echo.
    echo 👉 Bạn sẽ thấy tiến trình "Build CCCD NFC Reader (Android & iOS)" đang chạy.
    echo 👉 Sau khoảng 3-4 phút, bạn bấm vào đó và tải file CCCD_NFC_Reader_iOS.ipa về nhé!
) else (
    echo.
    echo [LỖI] Không thể đẩy code lên GitHub. Vui lòng kiểm tra lại Token của bạn!
)

echo.
pause
