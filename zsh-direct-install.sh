#!/bin/bash

# 检测系统包管理器并安装zsh
if command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install -y zsh git curl
elif command -v yum &> /dev/null; then
    sudo yum install -y zsh git curl
elif command -v dnf &> /dev/null; then
    sudo dnf install -y zsh git curl
elif command -v pacman &> /dev/null; then
    sudo pacman -Sy --noconfirm zsh git curl
elif command -v zypper &> /dev/null; then
    sudo zypper install -y zsh git curl
elif command -v brew &> /dev/null; then
    brew install zsh git curl
else
    echo "错误：未检测到支持的包管理器 (apt/yum/dnf/pacman/zypper/brew)"
    exit 1
fi

# 安装Oh My Zsh（非交互式模式）
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 安装插件
plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

# 安装zsh-autosuggestions
if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions"
fi

# 安装zsh-syntax-highlighting
if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
fi

# 检查是否已有配置块
config_block_exists() {
  grep -q "# ===== ZSH CONFIG BLOCK =====" ~/.zshrc
}

# 备份现有.zshrc（如果存在）
if [ -f ~/.zshrc ]; then
    echo "备份现有.zshrc为.zshrc.bak"
    cp ~/.zshrc ~/.zshrc.bak
fi

# 仅在配置块不存在时追加
if ! config_block_exists; then
  cat >> ~/.zshrc << 'EOL'

# ===== ZSH CONFIG BLOCK =====
# 由安装脚本自动添加
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="random"
plugins=(git z docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
# ===== END OF CONFIG BLOCK =====
EOL
else
  echo "检测到已有配置块，跳过追加"
fi

# 设置zsh为默认shell
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "zsh" ]; then
  echo "设置zsh为默认shell..."
  if command -v chsh >/dev/null 2>&1; then
    sudo chsh -s "$(command -v zsh)" "$USER"
  else
    echo "警告：chsh命令不可用，请手动设置zsh为默认shell"
  fi
fi

echo -e "\n\033[32m安装完成！请重新登录或打开新终端生效\033[0m"
echo "提示：随机主题每次打开终端都会变化，固定主题请修改.zshrc中的ZSH_THEME"
echo "当前安装的oh-my-zsh版本: $(omz version)"

# 如果备份存在，提示用户
if [ -f ~/.zshrc.bak ]; then
    echo -e "\n\033[33m备份文件: ~/.zshrc.bak\033[0m"
fi
