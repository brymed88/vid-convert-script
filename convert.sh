#!/bin/bash

#File Directory Parameter
m_path="$1"

#File Name Parameter
m_name="$2"

#File Category Parameter - ie (Adult Movie, Shows, etc..)
m_cat="$3"

#File Full Path Parameter
m_fpath="$4"

#Video File Save Folder. Alter this value to match your environment
m_saveFolder="/home/brymed/Videos/temp"

#Local Information
rsa_keyName="piplex.txt"

#Remote Server Information For SFTP Transfer. Alter these values to match your environment
enable_transfer=1
remote_ip="192.168.1.121"
remote_username="pi"
remote_saveFolder="/media/PIPLEX"

function transfer_file() {
      echo "in transfer"
      #Assign Argument to variable
      file="$1"
      echo $file
      #//TODO change key file to point to correct ssh key
      #scp -i ~/.ssh/$rsa_keyName $file $remote_username@$remote_ip:/$remote_saveFolder/$m_cat
}

function convert_file() {

      #Argument Passed From For Loop
      i=$1
      #GET FILE EXTENSION FROM FILE
      file_ext="${i##*.}"

      #GET FILE NAME FROM FILE
      file_name="${i%.*}"

      #If not a directory
      if [ ! -d "$i" ]; then
            if [[ $file_ext == "mp4" ]] || [[ $file_ext == "avi" ]] || [[ $file_ext == "mkv" ]] || [[ $file_ext == "wmv" ]] || [[ $file_ext == "flv" ]] || [[ $file_ext == "mov" ]]; then

                  #ASSIGN VIDEO CODECS TO VARIABLES
                  codecV=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")
                  codecA=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")

                  #IF H264 & MP4, TRANSFER FILE WITHOUT CONVERSION
                  if [[ "$codecV" == "h264" ]] && [[ $file_ext == "mp4" ]]; then
                        echo "Match - h264/mp4, mv file to folder to ftp"

                  #ELSE RECODE TO H264 & MP4
                  else
                        echo "Not h264 or .mp4 "
                        ffmpeg -i "$i" -c:v libx264 -preset fast -crf 22 -c:a aac "${i%.*}.mp4"
                        while pidof /usr/bin/ffmpeg; do sleep 10; done >/dev/null #sleep until movie is processed
                        chmod 777 "${i%.*}.mp4"
                        mv "${i%.*}.mp4" "$m_saveFolder"
                        rm "$i"

                        #If transfer is enabled then transfer file
                        if [ $enable_transfer -eq 1 ]; then
                              transfer_file "$m_saveFolder/${i%.*}.mp4"
                        fi
                  fi

            elif [ $file_ext == "srt" ]; then
                  echo "Exists - srt file"

                  mv "$i" "$m_saveFolder/$file_name.en.srt"

                  if [ $enable_transfer -eq 1 ]; then
                        transfer_file "$m_saveFolder/$file_name.en.srt"
                  fi
            else
                  rm "$i"
            fi
      fi
}

cd "$m_fpath"

#Loop through files in m_fpath location and send to convert_file function for processing
for i in *; do
      convert_file $i
done

#If the movie path does not equal the save folder path delete movie folder
if [ $m_fpath != $m_saveFolder ]; then
      rmdir $m_fpath
fi

#//TODO Remove when complete
read -n 1 -r -s -p $'Press enter to continue...\n'
