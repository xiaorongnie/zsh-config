#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示代理信息（如果设置了代理）
if [ -n "$http_proxy" ] || [ -n "$https_proxy" ]; then
    echo -e "${BLUE}=== 检测到代理设置 ===${NC}"
    [ -n "$http_proxy" ] && echo -e "${BLUE}HTTP代理: $http_proxy${NC}"
    [ -n "$https_proxy" ] && echo -e "${BLUE}HTTPS代理: $https_proxy${NC}"
    echo ""
fi

echo -e "${BLUE}=== 开始ZSH环境安装检查 ===${NC}\n"

# 1. 检查并安装基础依赖
echo -e "${YELLOW}>>> 检查系统依赖 (zsh/git/curl)...${NC}"

install_packages() {
    local to_install=()
    for pkg in "$@"; do
        if ! command -v "$pkg" &> /dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo -e "${BLUE}-> 需要安装: ${to_install[*]}${NC}"
        if command -v apt &> /dev/null; then
            sudo -E apt update && sudo -E apt install -y "${to_install[@]}"
        elif command -v yum &> /dev/null; then
            sudo -E yum install -y "${to_install[@]}"
        elif command -v dnf &> /dev/null; then
            sudo -E dnf install -y "${to_install[@]}"
        elif command -v pacman &> /dev/null; then
            sudo -E pacman -Sy --noconfirm "${to_install[@]}"
        elif command -v zypper &> /dev/null; then
            sudo -E zypper install -y "${to_install[@]}"
        elif command -v brew &> /dev/null; then
            # brew不需要sudo
            brew install "${to_install[@]}"
        else
            echo -e "${RED}错误：未检测到支持的包管理器${NC}"
            return 1
        fi
        echo -e "${GREEN}<<< 依赖安装完成${NC}"
    else
        echo -e "${GREEN}所有依赖已安装，跳过${NC}"
    fi
}

install_packages zsh git curl
echo -e "${GREEN}<<< 依赖检查完成${NC}\n"

# 2. 检查并安装Oh My Zsh
echo -e "${YELLOW}>>> 检查Oh My Zsh安装...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${BLUE}-> 开始安装Oh My Zsh...${NC}"
    
    # 添加代理参数（如果设置了代理）
    curl_args=()
    if [ -n "$https_proxy" ]; then
        curl_args=(--proxy "$https_proxy")
    elif [ -n "$http_proxy" ]; then
        curl_args=(--proxy "$http_proxy")
    fi
    
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL "${curl_args[@]}" https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo -e "${GREEN}<<< Oh My Zsh安装完成${NC}"
else
    echo -e "${GREEN}Oh My Zsh已安装，跳过 (目录: ~/.oh-my-zsh)${NC}"
fi
echo -e "${GREEN}<<< 检查完成${NC}\n"

# 3. 检查并安装插件
echo -e "${YELLOW}>>> 检查ZSH插件...${NC}"
plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

install_plugin() {
    local plugin_name=$1
    local repo_url=$2
    local plugin_dir="$plugins_dir/$plugin_name"
    
    if [ ! -d "$plugin_dir" ]; then
        echo -e "${BLUE}-> 安装$plugin_name...${NC}"
        
        # 添加代理参数（如果设置了代理）
        if [ -n "$https_proxy" ] || [ -n "$http_proxy" ]; then
            git -c http.proxy="${http_proxy:-$https_proxy}" \
                -c https.proxy="${https_proxy:-$http_proxy}" \
                clone "$repo_url" "$plugin_dir"
        else
            git clone "$repo_url" "$plugin_dir"
        fi
        
        echo -e "${GREEN}$plugin_name安装成功${NC}"
    else
        echo -e "${GREEN}$plugin_name已存在，跳过 (目录: $plugin_dir)${NC}"
    fi
}

install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
install_plugin "zsh-motd" "https://github.com/xiaorongnie/zsh-motd.git"
echo -e "${GREEN}<<< 插件检查完成${NC}\n"

# 4. 检查并配置.zshrc
echo -e "${YELLOW}>>> 检查.zshrc配置...${NC}"

config_block_exists() {
    grep -q "# ===== ZSH CONFIG BLOCK =====" ~/.zshrc
}

if [ -f ~/.zshrc ]; then
    echo -e "${BLUE}-> 发现现有.zshrc文件${NC}"
    if ! config_block_exists; then
        echo -e "${BLUE}-> 追加配置到.zshrc${NC}"
        cat >> ~/.zshrc << 'EOL'

# ===== ZSH CONFIG BLOCK =====
# 由安装脚本自动添加
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="random"
plugins=(git z docker docker-compose zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
# ===== END OF CONFIG BLOCK =====
EOL
        echo -e "${GREEN}配置已追加到.zshrc${NC}"
    else
        echo -e "${GREEN}配置块已存在，跳过追加${NC}"
    fi
else
    echo -e "${BLUE}-> 创建新的.zshrc文件${NC}"
    cat > ~/.zshrc << 'EOL'
# ===== ZSH CONFIG BLOCK =====
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="random"
plugins=(git z docker docker-compose zsh-autosuggestions zsh-syntax-highlighting zsh-motd)
source $ZSH/oh-my-zsh.sh
# ===== END OF CONFIG BLOCK =====
EOL
    echo -e "${GREEN}已创建.zshrc文件${NC}"
fi
echo -e "${GREEN}<<< 配置检查完成${NC}\n"

# 5. 检查并设置默认shell
echo -e "${YELLOW}>>> 检查默认shell...${NC}"
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "zsh" ]; then
    echo -e "${BLUE}-> 当前shell为$current_shell，尝试设置为zsh${NC}"
    if command -v chsh >/dev/null 2>&1; then
        sudo chsh -s "$(command -v zsh)" "$USER"
        echo -e "${GREEN}默认shell已设置为zsh${NC}"
    else
        echo -e "${RED}警告：chsh命令不可用，请手动设置zsh为默认shell${NC}"
        echo -e "可执行命令: ${BLUE}chsh -s $(command -v zsh)${NC}"
    fi
else
    echo -e "${GREEN}当前已经是zsh，无需更改${NC}"
fi
echo -e "${GREEN}<<< shell检查完成${NC}\n"

# 安装完成提示
echo -e "${BLUE}=== 安装结果汇总 ===${NC}"
echo -e "${GREEN}✓ 所有组件检查/安装完成${NC}"
echo -e "提示：随机主题每次打开终端都会变化，固定主题请修改.zshrc中的ZSH_THEME"

if command -v omz &> /dev/null; then
    omz_version=$(omz version)
    echo -e "Oh My Zsh版本: ${GREEN}$omz_version${NC}"
fi

echo -e "\n${GREEN}请执行以下命令使配置生效：${NC}"
echo -e "  ${BLUE}exec zsh${NC} 或重新打开终端"
echo -e "\n${BLUE}=== ZSH环境安装完成 ===${NC}"
