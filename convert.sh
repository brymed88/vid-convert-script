#!/bin/bash

## Author:Brycen Medart
## URL:https://treantlabs.com
## Version: 1.0
## License: MIT License

##--------------
# Argument Variables - Do not change unless use case is understood
##--------------------

#File Directory Parameter
path="$1"

#File Category Parameter - ie (Adult Movie, Shows, etc..)
cat="$2"

#File Full Path Parameter
f_path="$3"

#Array of Movie ext types
ext_array=("srt" "avi" "flv" "mkv" "mov" "mp4" "wmv")

##-------------
#Global change variables - Change to configure for your environment.
##--------------------

#Enable file name rewrite to remove certain characters programmatically
name_rewrite=1
old_char=" "
new_char="."

#Remove converted local file after transfer 0=no 1=yes
remove_file=1

#Video File Save Folder, alter to save converted movies to new location.
m_saveFolder="/home/brymed/Videos/tmp/"

#SSH Key file location/name
rsa_keyName=".ssh/id_rsa.pub"

#Remote Server Information For SFTP Transfer. Alter these values to match your environment.
enable_transfer=1
remote_ip="192.168.1.121"
remote_username="pi"
remote_saveFolder="/media/PIPLEX"

##
## For all files in specified directory, rename file to remove spaces and replace with '.' character
##
function rename_files(){
      
      for f in *; do 
            if [ ! -d "$i" ]; then
            echo "renaming : $f to ${f//$old_char/$new_char}"
            mv "$f" "${f//$old_char/$new_char}";
            fi
      done 
}

function transfer_file() {

      #Assign Argument to variable
      i=$1
      echo "Transferring - $i"
      scp -i ~/$rsa_keyName "$i" $remote_username@$remote_ip:/$remote_saveFolder/$cat

      #Remove file after transfer if $remove_file is set
      sleep 1
      if [ $remove_file -eq 1 ]; then
            echo "Transfer complete - Removing file - $i"
            rm "$i"
            echo "Removed File - $i"
      fi
}

function convert_file() {

#Argument Passed From For Loop
i=$1

#GET FILE EXTENSION FROM FILE
file_ext="${i##*.}"

#GET FILE NAME FROM FILE
file_name="${i%.*}"

if [ $file_ext == "srt" ]; then
      mv "$i" "$f_path/$file_name.en.srt"
      rm $i
            if [ $enable_transfer -eq 1 ]; then
                  transfer_file "$f_path/$file_name.en.srt"
            fi
else

#Assign Video/Audio codecs to variables
codecV=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")
codecA=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")

      
#RECODE TO H264 & MP4 and reduce size
#Use ffmpeg to convert video, see https://ffmpeg.org/ffmpeg.html for alternate values

echo "Converting File - $i"
ffmpeg -i "$i" -c:v libx264 -preset medium -crf 24 -c:a aac "$file_name.mp4"

#Sleep until movie is processed !important
while pidof /usr/bin/ffmpeg; do sleep 10; done >/dev/null

chmod 777 "$file_name.mp4"
rm "$i"

      #If transfer is enabled then transfer file
      if [ $enable_transfer -eq 1 ]; then
            transfer_file "$f_path/$file_name.mp4"
      fi
     
fi
}

#CD into directory to avoid unwanted actions
cd $f_path

#If rename is enabled, loop files and remove characters specified by above variables old_char and new_char
if [ $name_rewrite -eq 0 ]; then
      rename_files
fi

#Loop through files in f_path location and send to convert_file function for processing
for i in *; do

 #If not a directory
if [ ! -d "$i" ]; then

#GET FILE EXTENSION FROM FILE
file_ext="${i##*.}"
            
      # Search array for video ext
      if [[ " ${ext_array[*]} " =~ " ${file_ext} " ]]; then
            convert_file "$i"
      else
            #make sure it is a file
            if [ -f $i ]; then
                  rm $i
                  echo "$i has been removed"
            fi
      fi
fi
done

#If the movie path does not equal the save folder and is empty delete movie folder
if [[ "$f_path" != "$path" ]] && [[ -d "$f_path" ]] && [[ -z "$(ls -A $f_path)" ]]; then
      rmdir "$f_path"
fi

read -n 1 -r -s -p $'Press enter to continue...\n'
