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

  # backward compatibility after correcting the typo in directory
  if [[ -d "$HOME/DoChat/Applcation Data" ]]; then
      mv "$HOME/DoChat/Applcation Data" "$HOME/DoChat/Application Data"
  fi

  # prevents issue of not enough privilege if docker automatically create these folders
  mkdir -p "$HOME/DoChat/Application Data"
  mkdir -p "$HOME/DoChat/WeChat Files"

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
  rm -f "$HOME/DoChat/Application Data/Tencent/WeChat/All Users/config/configEx.ini"

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
    -v "$HOME/DoChat/WeChat Files/":'/home/user/WeChat Files/' \
    -v "$HOME/DoChat/Application Data":'/home/user/.wine/drive_c/users/user/Application Data/' \
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

    echo
    echo "📦 DoChat Exited with code [$?]"
    echo
    echo '🐞 Bug Report (current fork): https://github.com/lucunji/docker-wechat/issues'
    echo '🐞 Bug Report (root fork): https://github.com/huan/docker-wechat/issues'
    echo
}

main
