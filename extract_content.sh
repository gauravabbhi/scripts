#!/bin/bash

# Default values
OUTPUT_DIR="project_$(date +%Y%m%d_%H%M%S)"
CHUNK_SIZE_KB=40
DEFAULT_EXTENSIONS=".ts,.js,.tsx,.jsx,.py,html"
DEFAULT_IGNORE_DIRS="node_modules,dist,build,coverage,venv,logs,output"
CURRENT_CHUNK_FILE=""
CURRENT_CHUNK_SIZE=0
CHUNK_NUMBER=1

# Function to print usage
print_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --directory     Source directory to scan (required)"
    echo "  -e, --extensions    File extensions to include (comma-separated, default: $DEFAULT_EXTENSIONS)"
    echo "  -i, --ignore        Directories to ignore (comma-separated, default: $DEFAULT_IGNORE_DIRS)"
    echo "  -c, --chunk-size    Chunk size in KB (default: 400)"
    echo "  -o, --output        Output directory (default: project_YYYYMMDD_HHMMSS)"
    echo "  -h, --help          Show this help message"
}

# Function to create a new chunk file
create_new_chunk() {
    CURRENT_CHUNK_FILE="${OUTPUT_DIR}/${CHUNK_NUMBER}.txt"
    CURRENT_CHUNK_SIZE=0
    touch "$CURRENT_CHUNK_FILE"
    ((CHUNK_NUMBER++))
}

# Function to append file content to current chunk
append_to_chunk() {
    local file="$1"
    local file_content
    local file_size
    local header

    # Create file header
    header="================================================================================\n"
    header+="File: $file\n"
    header+="================================================================================\n\n"

    # Get file content and size
    file_content=$(cat "$file")
    file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
    header_size=${#header}
    total_size=$((file_size + header_size + 2))  # +2 for newlines

    # If current chunk would exceed size limit, create new chunk
    if [ $((CURRENT_CHUNK_SIZE + total_size)) -gt $((CHUNK_SIZE_KB * 1024)) ]; then
        create_new_chunk
    fi

    # If no current chunk file exists, create first one
    if [ -z "$CURRENT_CHUNK_FILE" ]; then
        create_new_chunk
    fi

    # Append content to current chunk
    printf "%b" "$header" >> "$CURRENT_CHUNK_FILE"
    echo "$file_content" >> "$CURRENT_CHUNK_FILE"
    echo -e "\n" >> "$CURRENT_CHUNK_FILE"

    CURRENT_CHUNK_SIZE=$((CURRENT_CHUNK_SIZE + total_size))
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -e|--extensions)
            EXTENSIONS="$2"
            shift 2
            ;;
        -i|--ignore)
            IGNORE_DIRS="$2"
            shift 2
            ;;
        -c|--chunk-size)
            CHUNK_SIZE_KB="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Check if source directory is provided and exists
if [ -z "$SOURCE_DIR" ]; then
    echo "Error: Source directory is required"
    print_usage
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Directory '$SOURCE_DIR' does not exist"
    exit 1
fi

# Set default values if not provided
EXTENSIONS=${EXTENSIONS:-$DEFAULT_EXTENSIONS}
IGNORE_DIRS=${IGNORE_DIRS:-$DEFAULT_IGNORE_DIRS}

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Scanning directory: $SOURCE_DIR"
echo "Looking for files with extensions: $EXTENSIONS"

# Create find pattern for all extensions
IFS=',' read -ra ext_array <<< "$EXTENSIONS"
find_pattern=""
for ext in "${ext_array[@]}"; do
    # Remove any leading dot if present
    ext=${ext#.}
    find_pattern="$find_pattern -o -name \"*.$ext\""
done
find_pattern=${find_pattern:4}  # Remove initial "-o "

# Process files
eval "find \"$SOURCE_DIR\" -type f \( $find_pattern \)" | while read -r file; do
    # Check if file is in ignored directory
    skip=false
    for ignore_dir in ${IGNORE_DIRS//,/ }; do
        if [[ "$file" == *"/$ignore_dir/"* ]]; then
            skip=true
            break
        fi
    done
    [ "$skip" = true ] && continue

    # Print processing message
    echo "Processing: $file"

    # Append file to current chunk
    append_to_chunk "$file"
done

# Check if any files were processed
if [ ! -f "${OUTPUT_DIR}/1.txt" ]; then
    echo "No matching files found in $SOURCE_DIR"
    rm -r "$OUTPUT_DIR"
    exit 1
fi

echo "Content extraction complete. Output files are in $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
