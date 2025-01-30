# Code Content Extractor

A bash script to extract and chunk source code files from a project directory. The script preserves file integrity by ensuring that files are never split across chunks.

## Features

- Processes multiple file types (TypeScript, JavaScript, Python, HTML, etc.)
- Creates size-limited chunks with complete files
- Preserves file content with clear headers
- Ignores specified directories (node_modules, dist, etc.)
- Sequential chunk naming (1.txt, 2.txt, etc.)

## Prerequisites

- Bash shell (version 4.0 or later)
- Unix-like environment (Linux, macOS, WSL)

## Installation

1. Download the script:

2. Make it executable:
   ```bash
   chmod +x extract_content.sh
   ```

## Usage

### Basic Usage

```bash
./extract_content.sh -d ./src
```

This will process all supported files in the `./src` directory using default settings.

### Path Guidelines

- Use relative paths when possible
- Avoid paths with spaces (or use quotes)
- Examples of good paths:
  ```bash
  ./extract_content.sh -d ./src
  ./extract_content.sh -d ../project/src
  ./extract_content.sh -d "/path/with spaces/src"
  ```
- Examples of paths to avoid:
  ```bash
  ./extract_content.sh -d /very/long/path/to/deeply/nested/directory/structure/src
  ./extract_content.sh -d ./src////code
  ```

### Full Options

```bash
./extract_content.sh [options]

Options:
  -d, --directory     Source directory to scan (required)
  -e, --extensions    File extensions to include (default: .ts,.js,.tsx,.jsx,.py,html)
  -i, --ignore        Directories to ignore (default: node_modules,dist,build,coverage,venv,logs,output)
  -c, --chunk-size    Chunk size in KB (default: 40)
  -o, --output        Output directory (default: project_YYYYMMDD_HHMMSS)
  -h, --help         Show help message
```

### Examples

1. Process TypeScript files only:
   ```bash
   ./extract_content.sh -d ./src -e .ts
   ```

2. Custom chunk size and output directory:
   ```bash
   ./extract_content.sh -d ./src -c 100 -o ./output
   ```

3. Custom ignore directories:
   ```bash
   ./extract_content.sh -d ./src -i "node_modules,temp,cache"
   ```

## Output Format

- Each chunk file is numbered sequentially (1.txt, 2.txt, etc.)
- File contents include headers:
  ```
  ================================================================================
  File: ./src/example.ts
  ================================================================================

  [file content]
  ```

## Error Handling

The script will:
- Validate the source directory exists
- Skip ignored directories
- Create new chunks when size limits would be exceeded
- Clean up empty output directories if no files are processed

## Limitations

- File sizes are calculated using `stat` command
- Designed for text-based source code files
- All output is in plain text format

## Contributing

Feel free to open issues or submit pull requests for improvements.

## License

MIT License - Feel free to use and modify as needed.
