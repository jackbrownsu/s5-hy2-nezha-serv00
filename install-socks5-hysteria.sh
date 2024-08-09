#!/bin/bash
# 介绍信息
{
    echo -e "\e[92m" 
    echo "通往电脑的路不止一条，所有的信息都应该是免费的，打破电脑特权，在电脑上创造艺术和美，计算机将使生活更美好。"
    echo "    ______                   _____               _____         "
    echo "    ___  /_ _____  ____________  /______ ___________(_)______ _"
    echo "    __  __ \\__  / / /__  ___/_  __/_  _ \\__  ___/__  / _  __ \`/"
    echo "    _  / / /_  /_/ / _(__  ) / /_  /  __/_  /    _  /  / /_/ / "
    echo "    /_/ /_/ _\\__, /  /____/  \\__/  \\___/ /_/     /_/   \\__,_/  "
    echo "            /____/                                              "
    echo "                          ______          __________          "
    echo "    ______________ __________  /_____________  ____/         "
    echo "    __  ___/_  __ \\_  ___/__  //_/__  ___/______ \\           "
    echo "    _(__  ) / /_/ // /__  _  ,<   _(__  )  ____/ /        不要直连"
    echo "    /____/  \\____/ \\___/  /_/|_|  /____/  /_____/         没有售后"
    echo "缝合怪：天诚 原作者们：cmliu RealNeoMan、k0baya、eooce"
    echo "交流群:https://t.me/cncomorg"
    echo -e "\e[0m"  
}


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
  read -p "请输入 hysteria2 端口 (面板开放的UDP端口,默认 20026）: " input_port
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
  ipv4=$(curl -s 4.ipw.cn)
  if [[ -n "$ipv4" ]]; then
    HOST_IP="$ipv4"
  else
    ipv6=$(curl -s --max-time 1 6.ipw.cn)
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

# 安装 Hysteria
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
}

# 安装和配置 socks5
socks5_config(){
  # 提示用户输入 socks5 端口号
  read -p "请输入 socks5 端口 (面板开放的TCP端口): " SOCKS5_PORT

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
    read -p "socks5 程序已存在，是否重新下载？(Y/N 回车N): " reinstall_socks5_answer
    reinstall_socks5_answer=${reinstall_socks5_answer^^}
    if [[ "$reinstall_socks5_answer" == "Y" ]]; then
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

# 下载 Nezha Agent
download_agent() {
    DOWNLOAD_LINK="https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_freebsd_amd64.zip"
    if ! wget -qO "$ZIP_FILE" "$DOWNLOAD_LINK"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    return 0
}

# 解压缩 Nezha Agent
decompression() {
    unzip "$1" -d "$TMP_DIRECTORY"
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ];then
        rm -r "$TMP_DIRECTORY"
        echo "removed: $TMP_DIRECTORY"
        exit 1
    fi
}

# 安装 Nezha Agent
install_agent() {
    install -m 755 ${TMP_DIRECTORY}/nezha-agent ${WORKDIR}/nezha-agent
}

# 生成运行 Nezha Agent 的脚本
generate_run_agent(){
    echo "关于接下来需要输入的三个变量，请注意："
    echo "Dashboard 站点地址可以写 IP 也可以写域名（域名不可套 CDN）;但是请不要加上 http:// 或者 https:// 等前缀，直接写 IP 或者域名即可；"
    echo "面板 RPC 端口为你的 Dashboard 安装时设置的用于 Agent 接入的 RPC 端口（默认 5555）；"
    echo "Agent 密钥需要先在管理面板上添加 Agent 获取。"
    printf "请输入 Dashboard 站点地址："
    read -r NZ_DASHBOARD_SERVER
    printf "请输入面板 RPC 端口："
    read -r NZ_DASHBOARD_PORT
    printf "请输入 Agent 密钥: "
    read -r NZ_DASHBOARD_PASSWORD
    printf "是否启用针对 gRPC 端口的 SSL/TLS加密 (--tls)，需要请按 [Y]，默认是不需要，不理解的用户可回车跳过: "
    read -r NZ_GRPC_PROXY
    echo "${NZ_GRPC_PROXY}" | grep -qiw 'Y' && ARGS='--tls'

    if [ -z "${NZ_DASHBOARD_SERVER}" ] || [ -z "${NZ_DASHBOARD_PASSWORD}" ]; then
        echo "error! 所有选项都不能为空"
        rm -rf ${WORKDIR}
        return 1
    fi

    cat > ${WORKDIR}/start.sh << EOF
#!/bin/bash
pgrep -f 'nezha-agent' | xargs -r kill
cd ${WORKDIR}
TMPDIR="${WORKDIR}" exec ${WORKDIR}/nezha-agent -s ${NZ_DASHBOARD_SERVER}:${NZ_DASHBOARD_PORT} -p ${NZ_DASHBOARD_PASSWORD} --report-delay 4 --disable-auto-update --disable-force-update ${ARGS} >/dev/null 2>&1
EOF
    chmod +x ${WORKDIR}/start.sh
}

# 运行 Nezha Agent
run_agent(){
    nohup ${WORKDIR}/start.sh >/dev/null 2>&1 &
    printf "nezha-agent已经准备就绪，请按下回车键启动\n"
    read
    printf "正在启动nezha-agent，请耐心等待...\n"
    sleep 3
    if pgrep -f "nezha-agent -s" > /dev/null; then
        echo "nezha-agent 已启动！"
        echo "如果面板处未上线，请检查参数是否填写正确，并停止 agent 进程，删除已安装的 agent 后重新安装！"
        echo "停止 agent 进程的命令：pgrep -f 'nezha-agent' | xargs -r kill"
        echo "删除已安装的 agent 的命令：rm -rf ~/.nezha-agent"
    else
        rm -rf "${WORKDIR}"
        echo "nezha-agent 启动失败，请检查参数填写是否正确，并重新安装！"
    fi
}

# 安装和配置 Nezha Agent
install_nezha_agent(){
  mkdir -p ${WORKDIR}
  cd ${WORKDIR}
  TMP_DIRECTORY="$(mktemp -d)"
  ZIP_FILE="${TMP_DIRECTORY}/nezha-agent_freebsd_amd64.zip"

  [ ! -e ${WORKDIR}/start.sh ] && generate_run_agent
  [ ! -e ${WORKDIR}/nezha-agent ] && download_agent \
  && decompression "${ZIP_FILE}" \
  && install_agent
  rm -rf "${TMP_DIRECTORY}"
  [ -e ${WORKDIR}/start.sh ] && run_agent
}

# 添加 crontab 守护进程任务
add_crontab_task() {
  crontab -l > /tmp/crontab.bak
  echo "*/1 * * * * if ! pgrep -f nezha-agent; then nohup $WORKDIR/start.sh >/dev/null 2>&1 & fi" >> /tmp/crontab.bak
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
  install_nezha_agent
fi

read -p "是否添加 crontab 任务来守护进程？(Y/N 回车N)" add_crontab_answer
add_crontab_answer=${add_crontab_answer^^}

if [[ "$add_crontab_answer" == "Y" ]]; then
  add_crontab_task
fi
