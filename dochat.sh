#!/usr/bin/env bash
#
# dochat.sh - Docker WeChat for Linux
#
#   Author: Huan (李卓桓) <zixia@zixia.net>
#   Copyright (c) 2020-now
#
#   License: Apache-2.0
#   GitHub: https://github.com/huan/docker-wechat
#
set -eo pipefail

function hello () {
  cat <<'EOF'

       ____         ____ _           _
      |  _ \  ___  / ___| |__   __ _| |_
      | | | |/ _ \| |   | '_ \ / _` | __|
      | |_| | (_) | |___| | | | (_| | |_
      |____/ \___/ \____|_| |_|\__,_|\__| (forked)

      https://github.com/lucunji/docker-wechat

                +--------------+
               /|             /|
              / |            / |
             *--+-----------*  |
             |  |           |  |
             |  |   盒装    |  |
             |  |   微信    |  |
             |  +-----------+--+
             | /            | /
             |/             |/
             *--------------*

      DoChat /dɑɑˈtʃæt/ (Docker-weChat) is:

      📦 a Docker image
      🤐 for running PC Windows WeChat
      💻 on your Linux desktop
      💖 by one-line of command

EOF
}

function main () {

  hello

  # fixes launching error (use xauth in the future for safety)
  xhost +local:root

  APPDATA_DIR="$HOME/DoChat/Application Data"
  USERFILE_DIR="$HOME/DoChat/WeChat Files"

  # backward compatibility after correcting the typo in directory
  if [[ -d "$HOME/DoChat/Applcation Data" ]]; then
      mv "$HOME/DoChat/Applcation Data" "$APPDATA_DIR"
  fi

  # prevents issue of not enough privilege if docker automatically create these folders
  mkdir -p "$APPDATA_DIR"
  mkdir -p "$USERFILE_DIR"

  # suppress issue of spamming crash reports when ALLOW_ERR_REPORTS is unset
  if [ -z ${ALLOW_ERR_REPORTS+x} ]; then
      rm -rf "$APPDATA_DIR/Tencent/WeChat/xweb/crash/Crashpad/reports"
      rm -rf "$APPDATA_DIR/Tencent/WeChat/log"
      mkdir -p "$APPDATA_DIR/Tencent/WeChat/xweb/crash/Crashpad"
      mkdir -p "$APPDATA_DIR/Tencent/WeChat"
      ln -s /dev/null "$APPDATA_DIR/Tencent/WeChat/xweb/crash/Crashpad/reports"
      ln -s /dev/null "$APPDATA_DIR/Tencent/WeChat/log"
  else
      # clean up soft link
      rm -rf "$APPDATA_DIR/Tencent/WeChat/xweb/crash/Crashpad/reports"
      rm -rf "$APPDATA_DIR/Tencent/WeChat/log"
  fi

  DEVICE_ARG=()
  # change /dev/video* to /dev/nvidia* for Nvidia
  for DEVICE in /dev/video* /dev/snd; do
    DEVICE_ARG+=('--device' "$DEVICE")
  done
  if [[ $(lshw -C display | grep vendor) =~ NVIDIA ]]; then
    DEVICE_ARG+=('--gpus' 'all' '--env' 'NVIDIA_DRIVER_CAPABILITIES=all')
  fi

  echo '🚀 Starting DoChat /dɑɑˈtʃæt/ ...'
  echo
  # Issue #111 - https://github.com/huan/docker-wechat/issues/111
  rm -f "$APPDATA_DIR/Tencent/WeChat/All Users/config/configEx.ini"

  #
  # --privileged: enable sound (/dev/snd/)
  # --ipc=host:   enable MIT_SHM (XWindows)
  #
  docker run \
    "${DEVICE_ARG[@]}" \
    --name DoChat \
    --rm \
    -i \
    \
    --cpus="${CPU_LIMIT:-2}" \
    --memory="${MEMORY_LIMIT:-2g}" \
    --memory-reservation="${MEMORY_RESERVATION:-512m}" \
    --memory-swap="${MEMORY_SWAP:-0}" \
    \
    -v "$USERFILE_DIR":'/home/user/WeChat Files/' \
    -v "$APPDATA_DIR":'/home/user/.wine/drive_c/users/user/Application Data/' \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    \
    -e DISPLAY \
    -e DOCHAT_DEBUG \
    -e DOCHAT_DPI \
    \
    -e XMODIFIERS \
    -e GTK_IM_MODULE \
    -e QT_IM_MODULE \
    \
    -e AUDIO_GID="$(getent group audio | cut -d: -f3)" \
    -e VIDEO_GID="$(getent group video | cut -d: -f3)" \
    -e GID="$(id -g)" \
    -e UID="$(id -u)" \
    \
    --ipc=host \
    \
    wechat:forked
#    zixia/wechat:3.3.0.115

    echo
    echo "📦 DoChat Exited with code [$?]"
    echo
    echo '🐞 Bug Report (current fork): https://github.com/lucunji/docker-wechat/issues'
    echo '🐞 Bug Report (root fork): https://github.com/huan/docker-wechat/issues'
    echo
}

main
