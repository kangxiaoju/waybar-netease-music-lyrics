#!/bin/bash

jsonPath="$HOME/.cache/netease-cloud-music/StorageCache/webdata/file/queue"
playerName="netease-cloud-music"
playerShell="playerctl --player=$playerName"
lyricsPath="$HOME/.config/waybar/lyrics.lrc"
while [ true ]; do
  sleep 1s;
  # 歌曲标题
  title=$($playerShell metadata title)
  if [ -n "$title" ]; then
    songId=$(jq -r '.[]|.track.name,.track.id' $jsonPath | grep -A 1 "$title" | sed -n '2p')
    # 播放当前时间
    position=$($playerShell metadata --format '{{ duration(position) }}')
    # 音乐播放器当前状态
    status=$($playerShell status)
    # 歌曲总长度
    length=$($playerShell metadata --format '{{ duration(mpris:length) }}')
    # 歌曲名称
    oldTitle=$(head -n +1 $lyricsPath)
    if [ "$title" != "$oldTitle" ]; then
      # 演唱者
      artist=$($playerShell metadata artist)
      # 专辑名称
      album=$($playerShell metadata album)
      # 歌曲本地图片
      icon=$($playerShell metadata mpris:artUrl)
      # 弹出提示框
      dunstify -h string:x-dunst-stack-tag:music "$title-$artist" $album -t 5000 --icon $icon
      # 请求歌词
      echo "" > $lyricsPath
      echo "" >> $lyricsPath
      curl http://music.163.com/api/song/media?id=$songId | jq -r '.lyric' >> $lyricsPath
      sed -i "1 c $title" $lyricsPath
    fi
    # 写入歌词
    lyrics=$(cat $lyricsPath | grep "$position" | awk -F ']' '{print $NF}' | head -n 1)
    if [ -n "$lyrics" ]; then 
      sed -i "2 c ==>$lyrics" $lyricsPath
    fi
    echo "$status [$title]$(sed -n 2p $lyricsPath) $position|$length" 
  else
    echo ""
  fi
done
