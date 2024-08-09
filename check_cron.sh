#!/bin/bash

USER=$(whoami)
USER_LOWER="${USER,,}"
WORKDIR="/home/${USER_LOWER}/.nezha-agent"
FILE_PATH="/home/${USER_LOWER}/.s5"
HYSTERIA_CONFIG="$WORKDIR/config.yaml"  # Hysteria 配置文件路径
CRON_S5="nohup ${FILE_PATH}/s5 -c ${FILE_PATH}/config.json >/dev/null 2>&1 &"
CRON_NEZHA="nohup ${WORKDIR}/start.sh >/dev/null 2>&1 &"
CRON_HYSTERIA="nohup /home/${USER_LOWER}/.hysteria/hysteria-server -c $HYSTERIA_CONFIG >/dev/null 2>&1 &"  # Hysteria 启动命令
PM2_PATH="/home/${USER_LOWER}/.npm-global/lib/node_modules/pm2/bin/pm2"
CRON_JOB="*/12 * * * * $PM2_PATH resurrect >> /home/$USER/pm2_resurrect.log 2>&1"
REBOOT_COMMAND="@reboot pkill -kill -u $USER && $PM2_PATH resurrect >> /home/$USER/pm2_resurrect.log 2>&1"

echo "检查并添加 crontab 任务"

# 添加 pm2 保活任务
if command -v pm2 > /dev/null 2>&1 && [[ $(which pm2) == "/home/${USER_LOWER}/.npm-global/bin/pm2" ]]; then
  echo "已安装 pm2 ，启用 pm2 保活任务"
  (crontab -l | grep -F "$REBOOT_COMMAND") || (crontab -l; echo "$REBOOT_COMMAND") | crontab -
  (crontab -l | grep -F "$CRON_JOB") || (crontab -l; echo "$CRON_JOB") | crontab -
else
  # 检查所需文件是否存在，并添加 crontab 任务
  if [ -e "${WORKDIR}/start.sh" ] && [ -e "${FILE_PATH}/config.json" ] && [ -e "$HYSTERIA_CONFIG" ]; then
    echo "添加 nezha, socks5 和 Hysteria 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $USER && ${CRON_S5} && ${CRON_NEZHA} && ${CRON_HYSTERIA}") || (crontab -l; echo "@reboot pkill -kill -u $USER && ${CRON_S5} && ${CRON_NEZHA} && ${CRON_HYSTERIA}") | crontab -
    (crontab -l | grep -F "* * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") || (crontab -l; echo "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "* * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") || (crontab -l; echo "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") | crontab -
    (crontab -l | grep -F "* * pgrep -x \"hysteria-server\" > /dev/null || ${CRON_HYSTERIA}") || (crontab -l; echo "*/12 * * * * pgrep -x \"hysteria-server\" > /dev/null || ${CRON_HYSTERIA}") | crontab -
  elif [ -e "${WORKDIR}/start.sh" ] && [ -e "$HYSTERIA_CONFIG" ]; then
    echo "添加 nezha 和 Hysteria 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $USER && ${CRON_NEZHA} && ${CRON_HYSTERIA}") || (crontab -l; echo "@reboot pkill -kill -u $USER && ${CRON_NEZHA} && ${CRON_HYSTERIA}") | crontab -
    (crontab -l | grep -F "* * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") || (crontab -l; echo "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "* * pgrep -x \"hysteria-server\" > /dev/null || ${CRON_HYSTERIA}") || (crontab -l; echo "*/12 * * * * pgrep -x \"hysteria-server\" > /dev/null || ${CRON_HYSTERIA}") | crontab -
  elif [ -e "${FILE_PATH}/config.json" ] && [ -e "$HYSTERIA_CONFIG" ]; then
    echo "添加 socks5 和 Hysteria 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $USER && ${CRON_S5} && ${CRON_HYSTERIA}") || (crontab -l; echo "@reboot pkill -kill -u $USER && ${CRON_S5} && ${CRON_HYSTERIA}") | crontab -
    (crontab -l | grep -F "* * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") || (crontab -l; echo "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") | crontab -
    (crontab -l | grep -F "* * pgrep -x \"hysteria-server\" > /dev/null || ${CRON_HYSTERIA}") || (crontab -l; echo "*/12 * * * * pgrep -x \"hysteria-server\" > /dev/null || ${CRON_HYSTERIA}") | crontab -
  elif [ -e "${WORKDIR}/start.sh" ]; then
    echo "添加 nezha 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $USER && ${CRON_NEZHA}") || (crontab -l; echo "@reboot pkill -kill -u $USER && ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "* * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") || (crontab -l; echo "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") | crontab -
  elif [ -e "${FILE_PATH}/config.json" ]; then
    echo "添加 socks5 的 crontab 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $USER && ${CRON_S5}") || (crontab -l; echo "@reboot pkill -kill -u $USER && ${CRON_S5}") | crontab -
    (crontab -l | grep -F "* * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") || (crontab -l; echo "*/12 * * * * pgrep -x \"s5\" > /dev/null || ${CRON_S5}") | crontab -
  fi
fi

echo "crontab 任务添加完成"
