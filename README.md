# LinuxScripts
Linux自用一键脚本，集成如IP修改、Hostname修改、MosDNS安装及Ui面板安装和Singbox安装等功能，后续随使用**持续更新**，敬请关注

## 特别鸣谢
@ovpavac

@[Myhero_my](https://github.com/52shell/sing-box-mosdns-fakeip)

@Panicpanic 

@[孔昊天](https://github.com/KHTdhl/AIO/blob/main/3.%E7%BD%91%E7%BB%9C%E7%9B%B8%E5%85%B3/DNS/mosdns%E6%95%99%E7%A8%8B%E4%B8%8E%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6/0.mosdns%2Bui%E6%90%AD%E5%BB%BA%E6%95%99%E7%A8%8B.md)

@[FrozenGEE](https://github.com/FrozenGEE/compose)

## AIO脚本
Linux综合脚本，包含基础环境设置、更新及部分软件安装、卸载。

**持续更新中**

### 功能简介
 - IP
   - 静态IP修改
   - DHCP
 - HostName
 - 基础环境设置
   - Update & Upgrade
   - 安装程序依赖
   - 设置时区为Asia/Shanghai
   - 设置NTP为ntp.aliyun.com
   - 关闭53端口监听
   - 一键安装以上所有基础设置
 - MosDNS
   - 安装Mosdns
   - 重置Mosdns缓存
   - 安装Mosdns UI
   - 卸载Mosdns
   - 一键安装Mosdns及UI面板
   - 一键卸载Mosdns及UI面板
 - Sing-box
   - 安装官方sing-box/升级
   - hysteria2 回家
   - 卸载sing-box
   - 卸载hysteria2 回家
   - 一键卸载singbox及HY2回家
 - PVE系统
   - 开启硬件直通
   - 虚拟机/LXC容器 解锁
   - img转系统盘
   - LXC容器调用核显
 - Docker
   - 安装docker
   - 安装docker-compose
   - 设定docker日志文件大小
   - 开启docker IPV6
   - 开启docker API - 2375端口
   - 卸载docker
   - 卸载docker-compose
 - Docker-compose(准备中，即将上线)   
---
 依赖安装程序安装的依赖有：
 * curl
 * wget
 * tar
 * gawk
 * sed
 * cron
 * unzip
 * nano
 * sudo
 * vim
 * sshfs
 * net-tools
 * nfs-common
 * bind9-host
 * adduser
 * libfontconfig1
 * musl
 * git
 * build-essential
 * libssl-dev
 * libevent-dev
 * zlib1g-dev
 * gcc-mingw-w64
---

# 下载使用
```shell
wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
```

# 特别说明
> mosdns脚本部分借鉴[孔昊天](https://github.com/KHTdhl/AIO/blob/main/3.%E7%BD%91%E7%BB%9C%E7%9B%B8%E5%85%B3/DNS/mosdns%E6%95%99%E7%A8%8B%E4%B8%8E%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6/0.mosdns%2Bui%E6%90%AD%E5%BB%BA%E6%95%99%E7%A8%8B.md)一键脚本，特别鸣谢。
> 
> singbox脚本部分借鉴[Myhero_my](https://github.com/52shell/sing-box-mosdns-fakeip)大佬脚本，特别鸣谢。
> 
> 配置由ovpavac、Panicpanic两位大佬调教优化，特别鸣谢。
> 
> docker-compose部分出自[FrozenGEE](https://github.com/FrozenGEE/compose)大佬通用库，还有其他仓库，如有需要请移步大佬仓库，特别鸣谢。