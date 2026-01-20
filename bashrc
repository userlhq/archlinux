#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Nix
if [ -e /home/lhq/.nix-profile/etc/profile.d/nix.sh ]; then
    . /home/lhq/.nix-profile/etc/profile.d/nix.sh
fi

# 确保系统路径在前面
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias f='func_find_file '
alias d='func_find_dir '
alias n='navi -p $(fd -d 1  ".cheat"  ~/cheats | fzf )'




# 查找一个文件并编辑
func_find_file(){
 file=$(fd -H -tf "$1" / | fzf)
  vim $file
}
# 查找一个目录并进入
func_find_dir()
{
	file=$(fd -H -td "$1" / | fzf)
	cd $file
}

PS1='[\u@\h \W]\$ '

# 搜索并安装软件包
s() {
    local help_text="用法:search [选项] [参数]
    
选项:
  -h, --help          显示此帮助信息
  -l, --list          列出显示安装的软件包
  -s, --search <name> 搜索并安装软件包
  -y, --yay_search <name> 在archlinuxcn 搜索安装
  "
  

    
    # 如果没有参数，显示帮助
    if [ $# -eq 0 ]; then
        echo "$help_text"
        return 1
    fi
    
    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                echo "$help_text"
                return 0
                ;;
            -l|--list)
				pacman -Qe > /tmp/pacman.pac
				vim /tmp/pacman.pac
                return 0
                ;;
            -s|--search)
                if [ -z "$2" ]; then
                    echo "错误: --search 需要一个名称参数"
                    return 1
                fi
				sudo pacman -Ss $2 > /tmp/pacman.pac
				vim /tmp/pacman.pac
                shift
                ;;
            -y|--yay_search)
                if [ -z "$2" ]; then
                    echo "错误: --yay_search 需要一个名称参数"
                    return 1
                fi
				yay -Ss $2 > /tmp/pacman.pac
				vim /tmp/pacman.pac
                shift
                ;;
            *)
				sudo pacman -S $1 
                return 1
                ;;
        esac
        shift
    done
}

# 键盘交换
setxkbmap -option ctrl:nocaps

export PYTHONPATH="/home/lhq/documents/pymode:$PYTHONPATH"
export EDITOR=vim

export NIX_PATH=$NIX_PATH:nixpkgs=$HOME/.nix-defexpr/channels/nixpkgs
