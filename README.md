# zsh-config

推荐使用代理安装
vscode自定义ssh快捷方式 D:\SoftWare\VSCode-win32-x64-1.98.0\Code.exe --user-data-dir "D:\vscode\ssh\user-data" --extensions-dir "D:\vscode\ssh\extensions"
```
ssh -v -R 7890:localhost:7890 tg.xxx
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
bash zsh-proxy-install.sh
```
![image](https://github.com/user-attachments/assets/f1dbf42d-8e9b-4d6d-a4e2-a0d82934a85c)


注意sudo代理问题，sudo 默认会重置环境变量（出于安全考虑）。
除非显式配置（如 sudo -E 或修改 /etc/sudoers），
否则通过 export 设置的变量不会传递给 sudo 后的命令。
```
export http_proxy="..."
export https_proxy="..."
sudo yum install -y zsh  # 代理失效

sudo HTTP_PROXY=$HTTP_PROXY HTTPS_PROXY=$HTTPS_PROXY yum install -y zsh  # 代理有效
```
