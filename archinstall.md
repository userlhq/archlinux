
下面给出一个面向初学者但完整的 Arch Linux 安装流程（含常用选项示例）。安装会清除目标分区上的数据，操作前请备份重要数据。官方最完整的文档是 Arch Wiki 的安装指南（强烈建议同时参照）：[Arch Wiki — Installation guide](https://wiki.archlinux.org/title/Installation_guide)

概览（主要步骤）
1. 准备：下载并写入 Arch ISO 到 USB，检查校验
2. 从 USB 启动（UEFI 或 BIOS）
3. 设置网络与时钟
4. 分区与格式化（UEFI 推荐使用 EFI 分区）
5. 安装基础系统（pacstrap）
6. 配置系统（fstab、chroot、时区、语言、主机名、用户）
7. 安装引导程序（systemd-boot 或 GRUB）
8. 重启并做后续配置（网络管理、图形环境等）

下面为每步给出命令示例与说明（以常见 UEFI + ext4 根分区为例；若使用 BIOS 或 LVM/LUKS、btrfs 等，请参照 Arch Wiki 相应章节）。

1) 准备
- 下载镜像并校验 SHA256（来自官网）
- 将镜像写入 USB（Linux 下示例）：
```
sudo dd if=archlinux-xxxx.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
替换 /dev/sdX 为你的 USB 设备（不是分区）。

2) 从 USB 启动
- 在目标机器的 UEFI/BIOS 中选择从 USB 启动，进入 Arch live 环境。默认用户名/密码无登录名，直接在 shell 下操作。

3) 检查网络与镜像源
- 有线通常自动联网。测试：
```
ping -c 3 archlinux.org
```
- 若为 Wi-Fi，可使用 `iwctl`（iwd）：
```
iwctl
# inside iwctl:
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect SSID
exit
```
或用 `wifi-menu`（如果可用）/ `wpa_supplicant`/NetworkManager 等。

- 同步系统时钟：
```
timedatectl set-ntp true
```

4) 分区（示例：GPT，UEFI）
- 使用 fdisk/gdisk/parted 分区，例如：
  - /dev/sda1 — EFI 分区，512M，类型 EFI System
  - /dev/sda2 — 根分区，剩余空间（ext4）
示例（使用 parted）：
```
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary fat32 1MiB 513MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary ext4 513MiB 100%
```

5) 格式化并挂载
```
# EFI
mkfs.fat -F32 /dev/sda1

# 根分区
mkfs.ext4 /dev/sda2

# 挂载
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
```
- 若使用 swapfile：
```
fallocate -l 4G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
```

6) 安装基础系统
- 选择镜像源（编辑 /etc/pacman.d/mirrorlist）或使用 reflector 更新镜像列表（可选）。
- 安装 base 包：
```
pacstrap /mnt base linux linux-firmware vim nano
# 可加 networkmanager、dhcpcd、openssh 等
```

7) 生成 fstab 并 chroot
```
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

8) 在 chroot 内的基础配置
- 设置时区：
```
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
```
- 本地化（编辑 /etc/locale.gen，去掉 zh_CN.UTF-8 UTF-8 前的注释）：
```
locale-gen
echo "LANG=zh_CN.UTF-8" > /etc/locale.conf
```
- 主机名与 hosts：
```
echo "myarch" > /etc/hostname
# /etc/hosts 示例
cat >> /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   myarch.localdomain myarch
EOF
```
- 设置 root 密码：
```
passwd
```
- 创建普通用户并加入 wheel 组：
```
useradd -m -G wheel -s /bin/bash username
passwd username
# 允许 sudo（安装 sudo 并编辑 /etc/sudoers ）
pacman -S sudo
EDITOR=visudo visudo
# 取消 %wheel ALL=(ALL:ALL) ALL 前的注释
```

- 安装并生成 initramfs（通常 pacstrap 已安装 mkinitcpio）：
```
mkinitcpio -P
```

9) 安装引导程序
- UEFI 推荐 systemd-boot（简单）：
```
bootctl install
cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda2) rw
EOF
# 或用 /dev/sda2 的 UUID（可用 blkid 查看）
echo "default arch.conf" > /boot/loader/loader.conf
```
- 或安装 GRUB（适合 BIOS 或 UEFI 双兼容）：
```
pacman -S grub efibootmgr
# UEFI 情况
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
# BIOS 情况（示例）
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

10) 启用网络管理（推荐 NetworkManager）
```
pacman -S networkmanager
systemctl enable NetworkManager
```

11) 退出并重启
```
exit
umount -R /mnt
reboot
# 记得移除安装 USB
```

12) 重启后（首次登录）
- 登录后更新系统：
```
sudo pacman -Syu
```
- 安装图形环境（示例 Xorg + GNOME）：
```
sudo pacman -S xorg gnome gnome-extra gdm
sudo systemctl enable gdm
# 安装显卡驱动：intel/amd/nvidia，根据硬件选包
```

常见选项与进阶
- 自动化安装：在 live 环境可以运行 archinstall（交互式脚本），适合首次体验：
```
archinstall
```
- 磁盘加密（LUKS）、LVM、btrfs、RAID：请参照 Arch Wiki 对应章节，操作更复杂且风险更高。
- 中文支持：安装字体与输入法（fcitx5/ibus），并配置 locale。
- AUR：Arch User Repository 用于社区包，可用 aur helper（如 paru、yay）管理（需谨慎）。

常见故障排查提示
- 无法联网：检查网络接口、dhcpcd/NetworkManager 服务、DNS（/etc/resolv.conf）。
- pacstrap 失败：更换镜像源（/etc/pacman.d/mirrorlist），检查网络与时间。
- 引导不出现：确认 EFI 分区已正确挂载到 /boot（部分发行版挂载到 /boot/efi），检查引导程序安装日志与 UEFI 设置。

推荐阅读（中文/英文）
- Arch Wiki — Installation guide: https://wiki.archlinux.org/title/Installation_guide
- Arch Wiki — Beginners' guide（中文翻译和教程很多，仍以 Arch Wiki 为准）

如果你愿意，我可以：
- 根据你的机器（UEFI/BIOS、磁盘布局、是否需要 LUKS）给出一份“按你实际情况”的定制化命令清单；
- 或给出一个使用 archinstall 的交互式快速脚本配置示例。

告诉我你的电脑是 UEFI 还是 BIOS、打算怎样分区（是否保留 Windows 双系统）、是否需要磁盘加密，我就给出精确步骤和命令。
