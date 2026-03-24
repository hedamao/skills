@echo off
echo 正在安装必需的打包工具 (pyinstaller)...
pip install pyinstaller -i https://pypi.tuna.tsinghua.edu.cn/simple
echo 正在为您独立打包成绿色的 Windows EXE 悬浮时钟...
pyinstaller -w -F --name "Windows悬浮时钟" windows_floating_clock.py
echo.
echo =======================================================
echo 打包成功！请查看当前文件夹下的 "dist" 目录，里面存放着您的 "Windows悬浮时钟.exe"。
echo 拿到任意一台 Win10 电脑皆可直接双击运行！
echo =======================================================
pause
