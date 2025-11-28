#!/usr/bin/env bash

################################################################################
# MAKEMAN
################################################################################

makeman() {
  local file=""
  local output_dir="$HOME/Documents/grymms_grimoires/99000_other/99500_command_manuals"
  local command=""
  local remove_unlisted=false

  # Reset OPTIND to 1 to ensure option parsing starts correctly
  OPTIND=1

  # Parse options
  usage() {
    cbc_style_box "$CATPPUCCIN_MAUVE" "Description:" \
      "  Generate PDF manuals from man pages, optionally from a list."

    cbc_style_box "$CATPPUCCIN_BLUE" "Usage:" \
      "  makeman [-h] [-f <file>] [-o <dir>] [-r] <command>"

    cbc_style_box "$CATPPUCCIN_TEAL" "Options:" \
      "  -h           Display this help message" \
      "  -f <file>    Specify a file with a list of commands" \
      "  -o <dir>     Specify an output directory" \
      "  -r           Remove unlisted files from the output directory"

    cbc_style_box "$CATPPUCCIN_PEACH" "Examples:" \
      "  makeman ls" \
      "  makeman -f commands.txt -r"
  }

  while getopts ":hf:o:r" opt; do
    case ${opt} in
    h)
      usage
      return 0
      ;;
    f)
      file=$OPTARG
      ;;
    o)
      output_dir=$OPTARG
      ;;
    r)
      remove_unlisted=true
      ;;
    \?)
      cbc_style_message "$CATPPUCCIN_RED" "Invalid option: -$OPTARG"
      usage
      return 1
      ;;
    :)
      cbc_style_message "$CATPPUCCIN_RED" "Option -$OPTARG requires an argument."
      usage
      return 1
      ;;
    esac
  done

  shift $((OPTIND - 1))

  # Process remaining arguments as the command
  if [ -z "$file" ]; then
    if [ $# -eq 0 ]; then
      usage
      return 1
    fi
    command=$1
  fi

  # Function to process a single command
  process_command() {
    local cmd=$1
    local output_file="${output_dir}/${cmd}.pdf"
    mkdir -p "$output_dir"
    if ! man -w "$cmd" &>/dev/null; then
      echo "Error: No manual entry for command '$cmd'"
      return 1
    fi
    if ! man -t "$cmd" | ps2pdf - "$output_file"; then
      echo "Error: Failed to convert man page to PDF for command '$cmd'"
      return 1
    fi
    echo "PDF file created at: $output_file"
  }

  # Process commands from file or single command
  if [ -n "$file" ]; then
    if [ ! -f "$file" ]; then
      echo "Error: File '$file' not found"
      return 1
    fi

    local cmd_list=()
    while IFS= read -r cmd; do
      [ -z "$cmd" ] && continue # Skip empty lines
      cmd_list+=("$cmd")
      process_command "$cmd"
    done <"$file"

    if $remove_unlisted; then
      for existing_file in "$output_dir"/*.pdf; do
        local basename=$(basename "$existing_file" .pdf)
        if [[ ! " ${cmd_list[@]} " =~ " ${basename} " ]]; then
          echo "Removing unlisted file: $existing_file"
          rm "$existing_file"
        fi
      done
    fi
  else
    process_command "$command"
  fi
}
