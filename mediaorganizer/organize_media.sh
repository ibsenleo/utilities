#!/bin/bash

# Configurable extensions
IMAGE_EXTS="jpg jpeg png gif heic heif bmp tiff webp raw cr2 nef arw dng"
VIDEO_EXTS="mp4 mov avi mkv m4v 3gp wmv flv webm"

# Parse arguments
while getopts "d:o:i:v:" opt; do
    case $opt in
        d) INPUT_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        i) IMAGE_EXTS="$OPTARG" ;;
        v) VIDEO_EXTS="$OPTARG" ;;
        *) echo "Usage: $0 -d <input_dir> -o <output_dir> [-i <image_exts>] [-v <video_exts>]"; exit 1 ;;
    esac
done

# Validate arguments
if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Error: Both -d and -o are required"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build find pattern
pattern=""

for ext in $IMAGE_EXTS $VIDEO_EXTS; do
    pattern="$pattern -o -iname *.$ext"
done

# Remove leading ' -o '
pattern="${pattern# -o }"

# Process files
find "$INPUT_DIR" -type f \( $pattern \) | while read -r file; do
    
    # Get file date
    if [[ "$OSTYPE" == "darwin"* ]]; then
        date_taken=$(stat -f "%SB" -t "%Y-%m" "$file" 2>/dev/null)
    else
        date_taken=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1 | cut -d'-' -f1,2)
    fi
    
    if [[ -z "$date_taken" ]]; then
        continue
    fi
    
    year=$(echo "$date_taken" | cut -d'-' -f1)
    month=$(echo "$date_taken" | cut -d'-' -f2)
    filename=$(basename "$file")
    ext="${filename##*.}"
    
    # Check if it's a video
    is_video=false
    for video_ext in $VIDEO_EXTS; do
        if [[ "${ext,,}" == "${video_ext,,}" ]]; then
            is_video=true
            break
        fi
    done
    
    # Set destination
    if $is_video; then
        dest_dir="$OUTPUT_DIR/$year/$month/videos"
    else
        dest_dir="$OUTPUT_DIR/$year/$month"
    fi
    
    # Create directory and copy file
    mkdir -p "$dest_dir"
    cp "$file" "$dest_dir/$filename"
    echo "Processed: $filename -> $dest_dir"
done

echo "Organization complete!"