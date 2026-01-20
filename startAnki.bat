@echo off
setlocal enabledelayedexpansion

:: --- 配置区域 ---
set "SYNC_USER1=admin:123456"    :: 格式: “用户名:密码”
set "SYNC_HOST="                   :: 服务器局域网IP，留空则绑定所有接口
set "SYNC_PORT=8080"               :: 监听端口
set "SYNC_BASE=F:\SoftwareData\AnkiServer"  :: 数据存储目录
set "PROCESS_NAME=python.exe"      :: 进程名称
set "PROCESS_ARG=anki.syncserver"  :: 进程特征参数

:: 显示配置信息
echo ==============================================
echo Anki 同步服务器配置
echo ==============================================
echo 用户配置:    !SYNC_USER1!
echo 服务器地址:  !SYNC_HOST!
echo 监听端口:    !SYNC_PORT!
echo 数据存储目录:!SYNC_BASE!
echo ==============================================

:: 检测服务器状态：同时检查端口和进程信息
set "SERVER_PID="
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /i ":!SYNC_PORT! LISTENING"') do (
    :: 检查该PID是否为python进程且包含指定参数
    for /f "delims=" %%b in ('wmic process where "ProcessId=%%a" get CommandLine /value ^| findstr /i "!PROCESS_NAME! !PROCESS_ARG!"') do (
        set "SERVER_PID=%%a"
    )
)

:: 如果找到匹配的进程PID
if defined SERVER_PID (
    echo 检测到Anki服务器已在运行（PID:!SERVER_PID!，端口:!SYNC_PORT!）
    echo.
    echo 请选择操作:
    echo  按下 C 键并回车 - 关闭服务器
    echo  按下其他键并回车 - 取消操作
    echo.
    
    :: 读取用户输入
    set /p "CHOICE=请输入选择: "
    
    :: 判断用户输入是否为c或C
    if /i "!CHOICE!" equ "C" (
        echo 正在关闭服务器...
        :: 杀死找到的服务器进程
        taskkill /F /PID !SERVER_PID! >nul 2>&1
        if !errorlevel! equ 0 (
            echo 服务器已成功关闭（PID:!SERVER_PID!）
        ) else (
            echo 关闭服务器失败，请手动结束进程（PID:!SERVER_PID!）
        )
    ) else (
        echo 已取消关闭操作，服务器继续运行
    )
    pause
    goto end
)

:: 启动服务器（未运行时）
echo 未检测到运行中的Anki服务器
echo 正在启动 Anki 同步服务器...
echo 服务器将在后台运行，关闭此窗口不影响服务
echo ==============================================

:: 使用VBScript创建隐藏窗口启动服务器
echo Set objShell = CreateObject("WScript.Shell") > temp.vbs
echo objShell.Run "cmd /c .venv\Scripts\python -m anki.syncserver", 0, False >> temp.vbs
cscript //nologo temp.vbs
del temp.vbs


echo 服务器已在后台启动（端口:!SYNC_PORT!）
echo 可以关闭此窗口
echo 再次运行本脚本将提供关闭选项
echo ==============================================
echo 3秒后自动关闭此窗口...
timeout /t 3 /nobreak >nul
goto end




:end
endlocal
