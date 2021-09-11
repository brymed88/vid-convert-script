#!/bin/bash

## Author:Brycen Medart
## URL:https://treantlabs.com
## Version: 1.0
## License: MIT License

##--------------
# Argument Variables - Do not change unless use case is understood
##--------------------

#File Directory Parameter
m_path="$1"

#File Category Parameter - ie (Adult Movie, Shows, etc..)
m_cat="$2"

#File Full Path Parameter
m_fpath="$3"

#Array of Movie ext types
ext_array=("avi" "flv" "mkv" "mov" "mp4" "wmv")

##-------------
#Global change variables - Change to configure for your environment.
##--------------------

#Remove converted local file after transfer 0=no 1=yes
remove_file=1

#Video File Save Folder, alter to save converted movies to new location.
m_saveFolder="/home/brymed/Videos/temp"

#SSH Key file location/name
rsa_keyName=".ssh/id_rsa.pub"

#Remote Server Information For SFTP Transfer. Alter these values to match your environment.
enable_transfer=1
remote_ip="192.168.1.121"
remote_username="pi"
remote_saveFolder="/media/PIPLEX"

function transfer_file() {

      #Assign Argument to variable
      file=$1
      scp -i ~/$rsa_keyName "$file" $remote_username@$remote_ip:/$remote_saveFolder/$m_cat

      #Remove file after transfer if $remove_file is set
      sleep 1
      if [ $remove_file -eq 1 ]; then
            rm "$file"
      fi
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

            # Search array for video ext
            if [[ " ${ext_array[@]} " =~ " ${file_ext} " ]]; then

                  #Assign Video/Audio codecs to variables
                  codecV=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")
                  codecA=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")

                  #IF H264 & MP4, transfer without conversion
                  if [[ "$codecV" == "h264" ]] && [[ $file_ext == "mp4" ]]; then
                        chmod 777 "$i"
                       
                        mv "$i" "$m_saveFolder"

                        #If transfer is enabled then transfer file
                        if [ $enable_transfer -eq 1 ]; then
                              transfer_file "$m_saveFolder/$i"
                        fi

                  #RECODE TO H264 & MP4
                  else

                        #Use ffmpeg to convert video, see https://ffmpeg.org/ffmpeg.html for alternate values
                        ffmpeg -i "$i" -c:v libx264 -preset fast -crf 22 -c:a aac "${i%.*}.mp4"

                        #Sleep until movie is processed !important
                        while pidof /usr/bin/ffmpeg; do sleep 10; done >/dev/null

                        chmod 777 "${i%.*}.mp4"
                        mv "${i%.*}.mp4" "$m_saveFolder"
                        rm "$i"

                        #If transfer is enabled then transfer file
                        if [ $enable_transfer -eq 1 ]; then
                              transfer_file "$m_saveFolder/${i%.*}.mp4"
                        fi
                  fi

            elif [ $file_ext == "srt" ]; then
                  mv "$i" "$m_saveFolder/$file_name.en.srt"

                  if [ $enable_transfer -eq 1 ]; then
                        transfer_file "$m_saveFolder/$file_name.en.srt"
                  fi
            else
           
                  rm "$i"
            fi
      fi
}

#Loop through files in m_fpath location and send to convert_file function for processing
cd "$m_fpath"
for i in *; do
      convert_file "$i"
done

#If the movie path does not equal the save folder path delete movie folder
if [ "$m_fpath" != "$m_saveFolder" ]; then
      rmdir "$m_fpath"
fi

read -n 1 -r -s -p $'Press enter to continue...\n'
