#!/bin/bash

#File Directory Parameter
m_path="$1"

#File Name Parameter
m_name="$2"

#File Category Parameter - ie (Adult Movie, Shows, etc..)
m_cat="$3"

#File Full Path Parameter
m_fpath="$4"

#echo "$m_path"
#echo "$m_name"
#echo "$m_cat"
#echo "$m_fpath"

#Converted File Save Folder
m_saveFolder="/home/brymed/Videos/temp"

#Local Information
rsa_keyName="piplex"

#Remote Server Information For SFTP Transfer
remote_ip="192.168.1.121"
remote_username="pi"
remote_saveFolder="/media/PIPLEX"

transfer_file() {
      #//TODO change key file to point to correct ssh key
      scp -i ~/.ssh/id_rsa.pubfile.txt $remote_username@$remote_ip:/$remote_saveFolder/$m_cat
}

convert_file() {

      for i in *; do

            #GET FILE EXTENSION FROM FILE
            file_ext="${i##*.}"

            #GET FILE NAME FROM FILE
            file_name="${i%.*}"

            # NOT EQUAL TO DIRECTORY THEN PROCEED
            if [ ! -d "$i" ]; then

                  
                  if [[ $file_ext == "mp4" ]] || [[ $file_ext == "avi" ]] || [[ $file_ext == "mkv" ]] || [[ $file_ext == "wmv" ]] || [[ $file_ext == "flv" ]] || [[ $file_ext == "mov" ]]; then

                        #ASSIGN VIDEO CODECS TO VARIABLES
                        codecV=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")
                        codecA=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")

                        echo "$codecV"
                        echo "$codecA"

                        #IF H264 & MP4, TRANSFER FILE WITHOUT CONVERSION
                        if [[ "$codecV" == "h264" ]] && [[ $file_ext == "mp4" ]]; then
                              echo "Match - h264/mp4, mv file to folder to ftp"

                        #ELSE RECODE TO H264 & MP4
                        else
                              echo "Not h264 or .mp4 "
                              #      ffmpeg -i "$i" -codec copy "${i%.*}.mp4"
                              #     while pidof /usr/bin/ffmpeg; do sleep 10; done >/dev/null #sleep until movie is processed
                              #    chmod 777 "${i%.*}.mp4"
                              #   mv "${i%.*}.mp4" "$m_saveFolder"
                              #  rm "$i"

                        fi

                  elif [ $file_ext == "srt" ]; then
                        echo "Exists - srt file"

                  #Functions - uncomment to enable
                  #mv "$i" "$m_saveFolder/$file_name.en.srt"

                  else
                  #rm "$i"

                  fi
            fi

      done

}

#If folder for video exists then CD to directory and process files
# IF PARENT FOLDER EXISTS, CD TO DIRECTORY AND PROCESS
if [ -d "$m_path" ]; then
      echo "Folder exists"
      cd "$m_path"
      convert_file

# ELSE CD TO PATH AND PROCESS FILE
elif [ -f "$m_path" ]; then
      echo "no folder, this is file"
      cd "$m_path"
      convert_file

fi

#//TODO Remove when complete
read -n 1 -r -s -p $'Press enter to continue...\n'
