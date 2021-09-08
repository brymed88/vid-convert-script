#!/bin/bash

#Directory
m_path="$1" 

#Name
m_name="$2" 

#Category
m_cat="$3" 

#Full Path
m_fpath="$4" 

#echo "$m_path"
#echo "$m_name"
#echo "$m_cat"
#echo "$m_fpath"

#Folder to save converted movies
m_saveFolder="/media/brymed/Backup/VideoConvert/Converted"


transfer_file () {
echo "transfer"
}

convert_file () {

for i in *;
do

#Get file extension
file_ext="${i##*.}"

#Get file name 
file_name="${m_name%.*}"

##
#If not a directory then proceed
##

if [ ! -d "$i" ] 
then

##
#If a movie file extension
##

if [[ $file_ext == "mp4" ]] || [[ $file_ext == "avi" ]] || [[ $file_ext == "mkv" ]] || [[ $file_ext == "wmv" ]] || [[ $file_ext == "flv" ]] || [[ $file_ext == "mov" ]] 
then

##
#PULL VIDEO AND AUDIO CODECS FROM THE MOVIE FILE
##

codecV=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")
codecA=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$i")

echo "$codecV"
echo "$codecA"

##
#If h264 codec and mp4, transfer file without converting
##

if [[ "$codecV" == "h264" ]] && [[ $file_ext == "mp4" ]]
then
echo "Match - h264/mp4, mv file to folder to ftp"

##
#Else recode codec and file ext to h264/.mp4
##

else
echo "Not h264 or .mp4 "
#      ffmpeg -i "$i" -codec copy "${i%.*}.mp4"
   #     while pidof /usr/bin/ffmpeg; do sleep 10; done >/dev/null #sleep until movie is processed
    #    chmod 777 "${i%.*}.mp4"
     #   mv "${i%.*}.mp4" "$m_saveFolder"
      #  rm "$i"

fi
  


##       
#If srt file change ext to .en.srt and move to converted folder
##

elif [ $file_ext == "srt" ]
then 
echo "Exists - srt file"

#Functions - uncomment to enable
#mv "$i" "$m_saveFolder/$file_name.en.srt"

##
#Delete any file that is not a movie file or .srt file
##

else
rm "$i" 

fi
fi

done


}

##
#If folder for video exists then CD to directory and process files
##

if [ -d "$m_path" ] 
then 
echo "Folder exists"
cd "$m_path"
convert_file 

##
#If no folder exists check for video files within m_fpath location
##

elif [ -f "$m_path" ] 
then
echo "no folder, this is file"
cd "$m_path"
convert_file

fi

#//TODO Remove when complete
read -n 1 -r -s -p $'Press enter to continue...\n'





