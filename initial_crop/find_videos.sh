#!/bin/bash

# Directory to search (current directory by default)
DIR="${1:-.}"

# Output CSV file
OUTPUT_FILE="video_info.csv"

# Write CSV header
echo "name,size,path,resolution,codec,fps,encoding" > "$OUTPUT_FILE"

# Find files containing "video" in their name (case-insensitive)
find "$DIR" -type f \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.wmv" \) -print0 | while IFS= read -r -d '' file; do
    size=$(stat -c %s "$file")
    parent_dir=$(dirname "$(realpath "$file")") # Get absolute path of the parent directory

    # Extract video metadata using ffprobe
    resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$file" 2>/dev/null | awk -F, '{print $1 "x" $2}')
    codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file" 2>/dev/null)
    frame_rate=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$file" 2>/dev/null | awk -F/ '{print $1/$2}')
    encoding_format=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$file" 2>/dev/null) # Gets the pixel format

    # Write to CSV file
    echo "\"$(basename "$file")\",$size,\"$parent_dir\",\"$resolution\",\"$codec\",\"$frame_rate\",\"$encoding_format\"" >> "$OUTPUT_FILE"
done

echo "CSV file generated: $OUTPUT_FILE"

