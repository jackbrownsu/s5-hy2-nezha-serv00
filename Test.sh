#!/bin/bash

# 介绍信息
echo -e "\e[32m
  ____   ___   ____ _  ______ ____  
 / ___| / _ \ / ___| |/ / ___| ___|  
 \___ \| | | | |   | ' /\___ \___ \ 
  ___) | |_| | |___| . \ ___) |__) |           不要直连
 |____/ \___/ \____|_|\_\____/____/            没有售后   
 缝合怪：cmliu 原作者们：RealNeoMan、k0baya、eooce
\e[0m"

# 获取当前用户名
USER=$(whoami)
USER_HOME=$(readlink -f /home/$USER) # 获取标准化的用户主目录
WORKDIR="$USER_HOME/.nezha-agent"
FILE_PATH="$USER_HOME/.s5"
HYSTERIA_WORKDIR="$USER_HOME/.hysteria"

# 创建必要的目录，如果不存在
[ ! -d "$WORKDIR" ] && mkdir -p "$WORKDIR"
[ ! -d "$FILE_PATH" ] && mkdir -p "$FILE_PATH"
[ ! -d "$HYSTERIA_WORKDIR" ] && mkdir -p "$HYSTERIA_WORKDIR"

###################################################

# 随机生成密码函数
generate_password() {
  export PASSWORD=${PASSWORD:-$(openssl rand -base64 12)}
}

# 设置服务器端口函数
set_server_port() {
  read -p "请输入服务器端口（默认 20026）: " input_port
  export SERVER_PORT="${input_port:-20026}"
}

# 下载依赖文件函数
download_dependencies() {
  ARCH=$(uname -m)
  DOWNLOAD_DIR="$HYSTERIA_WORKDIR"
  mkdir -p "$DOWNLOAD_DIR"
  FILE_INFO=()

  if [[ "$ARCH" == "arm" || "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    FILE_INFO=("https://download.hysteria.network/app/latest/hysteria-freebsd-arm64 web" "https://github.com/eooce/test/releases/download/ARM/swith npm")
  elif [[ "$ARCH" == "amd64" || "$ARCH" == "x86_64" || "$ARCH" == "x86" ]]; then
    FILE_INFO=("https://download.hysteria.network/app/latest/hysteria-freebsd-amd64 web" "https://github.com/eooce/test/releases/download/freebsd/swith npm")
  else
    echo "不支持的架构: $ARCH"
    exit 1
  fi

  for entry in "${FILE_INFO[@]}"; do
    URL=$(echo "$entry" | cut -d ' ' -f 1)
    NEW_FILENAME=$(echo "$entry" | cut -d ' ' -f 2)
    FILENAME="$DOWNLOAD_DIR/$NEW_FILENAME"
    if [[ -e "$FILENAME" ]]; then
      echo -e "\e[1;32m$FILENAME 已存在，跳过下载\e[0m"
    else
      curl -L -sS -o "$FILENAME" "$URL"
      echo -e "\e[1;32m下载 $FILENAME\e[0m"
    fi
    chmod +x "$FILENAME"
  done
  wait
}

# 生成证书函数
generate_cert() {
  openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout "$HYSTERIA_WORKDIR/server.key" -out "$HYSTERIA_WORKDIR/server.crt" -subj "/CN=bing.com" -days 36500
}

# 生成配置文件函数
generate_config() {
  cat << EOF > "$HYSTERIA_WORKDIR/config.yaml"
listen: :$SERVER_PORT

tls:
  cert: $HYSTERIA_WORKDIR/server.crt
  key: $HYSTERIA_WORKDIR/server.key

auth:
  type: password
  password: "$PASSWORD"

fastOpen: true

masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true

transport:
  udp:
    hopInterval: 30s
EOF
}

# 运行下载的文件函数
run_files() {
  if [[ -e "$HYSTERIA_WORKDIR/web" ]]; then
    nohup "$HYSTERIA_WORKDIR/web" server "$HYSTERIA_WORKDIR/config.yaml" >/dev/null 2>&1 &
    sleep 1
    echo -e "\e[1;32mweb 正在运行\e[0m"
  fi
}

# 获取IP地址函数
get_ip() {
  ipv4=$(curl -s ipv4.ip.sb)
  if [[ -n "$ipv4" ]]; then
    HOST_IP="$ipv4"
  else
    ipv6=$(curl -s --max-time 1 ipv6.ip.sb)
    if [[ -n "$ipv6" ]]; then
      HOST_IP="$ipv6"
    else
      echo -e "\e[1;35m无法获取IPv4或IPv6地址\033[0m"
      exit 1
    fi
  fi
  echo -e "\e[1;32m本机IP: $HOST_IP\033[0m"
}

# 获取网络信息函数
get_ipinfo() {
  ISP=$(curl -s https://speed.cloudflare.com/meta | awk -F\" '{print $26"-"$18}' | sed -e 's/ /_/g')
}

# 输出配置函数
print_config() {
  echo -e "\e[1;32mHysteria2 安装成功\033[0m"
  echo ""
  echo -e "\e[1;33mV2rayN或Nekobox 配置\033[0m"
  echo -e "\e[1;32mhysteria2://$PASSWORD@$HOST_IP:$SERVER_PORT/?sni=www.bing.com&alpn=h3&insecure=1#$ISP\033[0m"
  echo ""
  echo -e "\e[1;33mSurge 配置\033[0m"
  echo -e "\e[1;32m$ISP = hysteria2, $HOST_IP, $SERVER_PORT, password = $PASSWORD, skip-cert-verify=true, sni=www.bing.com\033[0m"
  echo ""
  echo -e "\e[1;33mClash 配置\033[0m"
  cat << EOF
- name: $ISP
  type: hysteria2
  server: $HOST_IP
  port: $SERVER_PORT
  password: $PASSWORD
  alpn:
    - h3
  sni: www.bing.com
  skip-cert-verify: true
  fast-open: true
EOF
}

# 删除临时文件函数
cleanup() {
  rm -rf "$HYSTERIA_WORKDIR/web" "$HYSTERIA_WORKDIR/config.yaml"
}

# 安装和配置 socks5
socks5_config(){
  # 提示用户输入 socks5 端口号
  read -p "请输入 socks5 端口号: " SOCKS5_PORT

  # 提示用户输入用户名和密码
  read -p "请输入 socks5 用户名: " SOCKS5_USER

  while true; do
    read -p "请输入 socks5 密码（不能包含@和:）：" SOCKS5_PASS
    echo
    if [[ "$SOCKS5_PASS" == *"@"* || "$SOCKS5_PASS" == *":"* ]]; then
      echo "密码中不能包含@和:符号，请重新输入。"
    else
      break
    fi
  done

  # config.js 文件
  cat > "$FILE_PATH/config.json" << EOF
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": "$SOCKS5_PORT",
      "protocol": "socks",
      "tag": "socks",
      "settings": {
        "auth": "password",
        "udp": false,
        "ip": "0.0.0.0",
        "userLevel": 0,
        "accounts": [
          {
            "user": "$SOCKS5_USER",
            "pass": "$SOCKS5_PASS"
          }
        ]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ]
}
EOF
}

install_socks5(){
  socks5_config
  if [[ ! -e "${FILE_PATH}/s5" ]]; then
    curl -L -sS -o "${FILE_PATH}/s5" "https://github.com/eooce/test/releases/download/freebsd/web"
  else
    read -p "socks5 程序已存在，是否重新下载覆盖？(Y/N 回车N)" downsocks5
    downsocks5=${downsocks5^^} # 转换为大写
    if [[ "$downsocks5" == "Y" ]]; then
      curl -L -sS -o "${FILE_PATH}/s5" "https://github.com/eooce/test/releases/download/freebsd/web"
    fi
  fi
  chmod +x "${FILE_PATH}/s5"
  nohup "${FILE_PATH}/s5" -c "${FILE_PATH}/config.json" >/dev/null 2>&1 &
  sleep 1
  if pgrep -x "s5" > /dev/null; then
    echo -e "\e[1;32mSocks5 代理程序启动成功\e[0m"
    echo -e "\e[1;33mSocks5 代理地址：\033[0m \e[1;32m$HOST_IP:$SOCKS5_PORT 用户名：$SOCKS5_USER 密码：$SOCKS5_PASS\033[0m"
  else
    echo -e "\e[1;31mSocks5 代理程序启动失败\033[0m"
  fi
}

# 安装和配置 Nezha Agent
install_nezha(){
  mkdir -p "$WORKDIR"
  read -p "请输入 Nezha Dashboard 地址(如: www.nezha.com):" NEZHA_SERVER
  read -p "请输入 Nezha Dashboard RPC 端口:" NEZHA_PORT
  read -p "请输入 Nezha Agent 密钥:" NEZHA_KEY
  echo "安装和配置 Nezha Agent"
  curl -sL https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip -o "$WORKDIR/nezha-agent.zip"
  unzip -o "$WORKDIR/nezha-agent.zip" -d "$WORKDIR" && chmod +x "$WORKDIR/nezha-agent"
  rm -f "$WORKDIR/nezha-agent.zip"
  cat > "$WORKDIR/service.sh" << EOF
#!/bin/bash
if [[ ! \$(pgrep -f nezha-agent) ]]; then
  read -p "请输入当前服务器的名称: " NEZHA_NAME
  read -p "是否允许安装Agent时自动更新？（yes/no，默认：yes）: " AUTO_UPDATE
  [ -z "\$AUTO_UPDATE" ] && AUTO_UPDATE="yes"
  "$WORKDIR/nezha-agent" -s "$NEZHA_SERVER:$NEZHA_PORT" -p "$NEZHA_KEY" -n "\$NEZHA_NAME" -a "\$AUTO_UPDATE" 2>&1 &
fi
EOF
  chmod +x "$WORKDIR/service.sh"
  nohup "$WORKDIR/service.sh" >/dev/null 2>&1 &
  echo -e "\e[1;32mNezha Agent 安装完成并启动\e[0m"
}

# 安装和配置 Hysteria
install_hysteria() {
  generate_password
  set_server_port
  download_dependencies
  generate_cert
  generate_config
  run_files
  get_ip
  get_ipinfo
  print_config
  cleanup
}

# 添加 crontab 守护进程任务
add_crontab_task() {
  crontab -l > /tmp/crontab.bak
  echo "*/1 * * * * if ! pgrep -f nezha-agent; then nohup $WORKDIR/service.sh >/dev/null 2>&1 & fi" >> /tmp/crontab.bak
  echo "*/1 * * * * if ! pgrep -x s5; then nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 & fi" >> /tmp/crontab.bak
  echo "*/1 * * * * if ! pgrep -x web; then nohup $HYSTERIA_WORKDIR/web server $HYSTERIA_WORKDIR/config.yaml >/dev/null 2>&1 & fi" >> /tmp/crontab.bak
  crontab /tmp/crontab.bak
  rm /tmp/crontab.bak
  echo -e "\e[1;32mCrontab 任务添加完成\e[0m"
}

# 主程序
read -p "是否安装 Hysteria？(Y/N 回车N)" install_hysteria_answer
install_hysteria_answer=${install_hysteria_answer^^}

if [[ "$install_hysteria_answer" == "Y" ]]; then
  install_hysteria
fi

read -p "是否安装 Socks5 代理？(Y/N 回车N)" install_socks5_answer
install_socks5_answer=${install_socks5_answer^^}

if [[ "$install_socks5_answer" == "Y" ]]; then
  install_socks5
fi

read -p "是否安装 Nezha Agent？(Y/N 回车N)" install_nezha_answer
install_nezha_answer=${install_nezha_answer^^}

if [[ "$install_nezha_answer" == "Y" ]]; then
  install_nezha
fi

read -p "是否添加 crontab 任务来守护进程？(Y/N 回车N)" add_crontab_answer
add_crontab_answer=${add_crontab_answer^^}

if [[ "$add_crontab_answer" == "Y" ]]; then
  add_crontab_task
fi
