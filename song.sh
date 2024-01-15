#!/bin/bash

playerName=$(playerctl --list-all |  head -n 1)
#playerName="feeluown"
playerShell="playerctl --player=$playerName"
lyricsPath="$HOME/.config/waybar/lyrics.lrc"
songIcons="$HOME/.config/waybar/scripts/songIcon"
songSt=$($playerShell status)

song(){
  # 歌曲标题
  title=$($playerShell metadata title)
  if [[ $title != "" ]]; then
    songId=$(getSongId)
    # 播放当前时间
    position=$($playerShell metadata --format '{{ duration(position) }}')
    # 音乐播放器当前状态
    status=$($playerShell status)
    # 歌曲总长度
    length=$($playerShell metadata --format '{{ duration(mpris:length) }}')
    # 歌曲名称
    oldTitle=$(head -n +1 $lyricsPath)
    if [ "$title" != "$oldTitle" ]; then
      # 删除上首歌的图片
      rm -rf $songIcons/*
      echo "" > $lyricsPath
      echo "" >> $lyricsPath
      sed -i "1 c $title" $lyricsPath
      getSongMedia $songId
      notifySongInfo $songId
    fi
    # 写入歌词
    lyrics=$(cat $lyricsPath | grep "$position" | awk -F ']' '{print $NF}' | head -n 1)
    if [ -n "$lyrics" ]; then 
      sed -i "2 c $lyrics" $lyricsPath
    fi
    echo "$(sed -n 2p $lyricsPath)" 
  fi
}

getSongId() {
  if [[ $playerName == "ElectronNCM" ]];then
    echo $($playerShell metadata mpris:trackid | cut -d "/" -f5 | cut -d "'" -f1)
  elif [[ $playerName == "feeluown" ]]; then
    echo $($playerShell metadata mpris:trackid | cut -d "/" -f7)
  elif [[ $playerName == "netease-cloud-music" ]]; then
    jsonPath="$HOME/.cache/netease-cloud-music/StorageCache/webdata/file/queue"
    echo $(jq -r '.[]|.track.name,.track.id' $jsonPath | grep -A 1 "$title" | sed -n '2p')
  fi
}

getSongMedia(){
  songId=$1
  # 请求歌词
  curl -s http://music.163.com/api/song/media?id=$songId | jq -r '.lyric' >> $lyricsPath
}

# 下载歌曲图片
notifySongInfo(){
  # 演唱者
  artist=$($playerShell metadata artist)
  # 专辑名称
  album=$($playerShell metadata album)
  songId=$1
  # 歌曲本地图片
  icon=$($playerShell metadata mpris:artUrl)
  # 获取图片后缀名
  iconSu=$(echo "${icon##*.}")
  # 下载图片
  curl -s -L $icon -o "$songIcons/$songId.$iconSu"
  # 弹出提示框
  notify-send -h string:x-dunst-stack-tag:music "$title-$artist" $album -t 800 --icon "$songIcons/$songId.$iconSu"
}

title(){
  if [[ $songSt == "Playing" ]];then
  	echo "$($playerShell metadata title) ";
  fi
}

post() {
  if [[ $songSt == "Playing" ]];then
	  dp=$($playerShell metadata --format '{{ duration(position) }}')
	  if [[ $dp != "" ]]; then
      duration=$(feeluown status | grep 'duration' | sed 's/duration:  //' | bc)
      le="$(date -u -d @${duration} +"%M:%S")"
	    if [[ $le != "" ]]; then
	      echo " [$dp|$le] "
	    else
	      echo " [$dp] "
	    fi
	  fi
  fi
	
}

songStatus(){
  # 音乐播放器当前状态
  if [[ $songSt == "Playing" ]];then
    echo "♫ ♪ ♫ ♪ ♥  "
  else
    echo "_ z Z Z ♥  "
  fi
}


case "$1" in
	"songStatus")
		songStatus
		;;
	"post")
		post
		;;
	"title")
		title
		;;
	"songId")
		getSongId
		;;
	*)
		song
		;;
esac
