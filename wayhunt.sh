#!/usr/bin/env bash
set -e

# -------------------------
# Colors
# -------------------------
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# -------------------------
# Banner
# -------------------------
clear
cat << "EOF"
██╗    ██╗ █████╗ ██╗   ██╗██╗  ██╗██╗   ██╗███╗   ██╗████████╗
██║    ██║██╔══██╗╚██╗ ██╔╝██║  ██║██║   ██║████╗  ██║╚══██╔══╝
██║ █╗ ██║███████║ ╚████╔╝ ███████║██║   ██║██╔██╗ ██║   ██║   
██║███╗██║██╔══██║  ╚██╔╝  ██╔══██║██║   ██║██║╚██╗██║   ██║   
╚███╔███╔╝██║  ██║   ██║   ██║  ██║╚██████╔╝██║ ╚████║   ██║   
 ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   
EOF
echo -e "${CYAN}        WayHunt - Web Archive URL Hunter"
echo -e "              Author: whitenight${RESET}"
echo

# -------------------------
# Usage function
# -------------------------
usage() {
  echo -e "${CYAN}Usage:${RESET} wayhunt.sh [OPTIONS]"
  echo
  echo -e "Options:"
  echo -e "  -i, --input FILE           Input file with domains (one domain per line)"
  echo -e "  -d, --domain DOMAIN        Single domain to scan"
  echo -e "  --wildcard                 Use wildcard query (*.domain/*) for Wayback"
  echo -e "  --sensitive-urls           Categorize sensitive URLs into types"
  echo -e "  -h, --help                 Show this help message and exit"
  echo
  echo -e "Example:"
  echo -e "  ./wayhunt.sh -i domains.txt --wildcard --sensitive-urls"
  echo -e "  ./wayhunt.sh -d example.com --sensitive-urls"
  exit 0
}

# -------------------------
# Defaults
# -------------------------
INPUT=""
DOMAIN=""
WORKERS=5
DELAY=1
TIMEOUT=60
WILDCARD=0
MODE=""

# -------------------------
# Parse args
# -------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input) INPUT="$2"; shift 2 ;;
    -d|--domain) DOMAIN="$2"; shift 2 ;;
    --sensitive-urls) MODE="sensitive"; shift ;;
    --wildcard) WILDCARD=1; shift ;;
    -h|--help) usage ;;
    *) shift ;;
  esac
done

# -------------------------
# Domains
# -------------------------
DOMAINS=()
[[ -n "$DOMAIN" ]] && DOMAINS+=("$DOMAIN")
[[ -n "$INPUT" ]] && mapfile -t DOMAINS < "$INPUT"

[[ ${#DOMAINS[@]} -eq 0 ]] && { echo -e "${RED}No domains provided${RESET}"; usage; }

[[ $WILDCARD -eq 1 ]] && \
echo -e "${YELLOW}[*] Wildcard mode enabled${RESET}"

echo -e "${BLUE}[*] Starting WayHunt Web Archive URL fetcher${RESET}"
echo -e "${BLUE}[*] Domains:${RESET} ${GREEN}${#DOMAINS[@]}${RESET}"
echo -e "${BLUE}[*] Workers:${RESET} ${GREEN}$WORKERS${RESET}"
echo -e "${BLUE}[*] Delay:${RESET} ${GREEN}${DELAY}s${RESET}"
echo -e "${BLUE}[*] Filters:${RESET} Sensitive Files (Categorized)"

# -------------------------
# Initialize output
# -------------------------
> wayback_urls.txt
mkdir -p sensitiveurls

# -------------------------
# Ctrl+C Trap for skipping domains
# -------------------------
skip_current=0
trap '
if [[ $skip_current -eq 0 ]]; then
    echo -e "\n${YELLOW}[!] Skipping current domain...${RESET}"
    skip_current=1
else
    echo -e "\n${RED}[!] Exiting program...${RESET}"
    exit 1
fi
' SIGINT

# -------------------------
# Fetch URLs
# -------------------------
for d in "${DOMAINS[@]}"; do
  [[ -z "$d" ]] && continue
  skip_current=0  # reset skip flag for each domain

  echo -e "${CYAN}[i] Fetching URLs for ${GREEN}$d${RESET}"
  QUERY="*.$d/*"
  [[ $WILDCARD -eq 0 ]] && QUERY="$d/*"
  echo -e "${CYAN}[i] Wayback Query: ${RESET}${QUERY}"

  BEFORE=$(wc -l < wayback_urls.txt)

  curl -s --max-time "$TIMEOUT" \
    "https://web.archive.org/cdx/search/cdx?url=${QUERY}&output=text&fl=original&collapse=urlkey" \
    >> wayback_urls.txt || true

  AFTER=$(wc -l < wayback_urls.txt)
  FOUND=$((AFTER - BEFORE))

  echo -e "${GREEN}[✓] $d → Found $FOUND URLs${RESET}"

  sleep $DELAY
done

sort -u wayback_urls.txt -o wayback_urls.txt
TOTAL_URLS=$(wc -l < wayback_urls.txt)

# -------------------------
# Sensitive categorization
# -------------------------
grep -Ei '\.(sql|db|bak|backup)' wayback_urls.txt > sensitiveurls/database_backup_urls.txt
grep -Ei '\.(env|conf|config|ini|yaml|yml)' wayback_urls.txt > sensitiveurls/config_urls.txt
grep -Ei '\.log' wayback_urls.txt > sensitiveurls/logs_urls.txt
grep -Ei '\.(json|xml|csv)' wayback_urls.txt > sensitiveurls/data_urls.txt
grep -Ei '\.txt' wayback_urls.txt > sensitiveurls/text_urls.txt
grep -Ei '\.pdf' wayback_urls.txt > sensitiveurls/pdf_urls.txt
grep -Ei '\.(doc|docx)' wayback_urls.txt > sensitiveurls/doc_urls.txt
grep -Ei '\.(zip|rar|7z|tar|gz)' wayback_urls.txt > sensitiveurls/archive_urls.txt
grep -Ei '(aws|gcp|azure)' wayback_urls.txt > sensitiveurls/cloud_infrastructure.txt
grep -Ei '\.(xls|xlsx|ods)' wayback_urls.txt > sensitiveurls/spreadsheet_urls.txt
grep -Ei '(secret|token|key|password)' wayback_urls.txt > sensitiveurls/secret_urls.txt
grep -Ei '(swagger|openapi)' wayback_urls.txt > sensitiveurls/api_specs_urls.txt
grep -Ei '\.(bin|exe)' wayback_urls.txt > sensitiveurls/generic_files_urls.txt
grep -Ei '\.(ppt|pptx)' wayback_urls.txt > sensitiveurls/slides_urls.txt
grep -Ei '\.js' wayback_urls.txt > sensitiveurls/script_urls.txt

# -------------------------
# Final Summary
# -------------------------
echo
echo -e "${YELLOW}WAYHUNT SCAN SUMMARY${RESET}"
echo "-------------------------"
echo -e "Domains processed : ${GREEN}${#DOMAINS[@]}${RESET}"
echo -e "Total URLs found  : ${GREEN}$TOTAL_URLS${RESET}"

# Show counts for each sensitive file category
echo
echo -e "${YELLOW}SENSITIVE FILES FOUND${RESET}"
for f in sensitiveurls/*.txt; do
  printf "%-30s : %s\n" "$(basename "$f")" "$(wc -l < "$f")"
done

echo
echo -e "${GREEN}Results saved to:${RESET} wayback_urls.txt"
echo -e "${GREEN}Sensitive URLs saved to:${RESET} sensitiveurls/"
echo -e "${CYAN}Final URL List Count:${RESET} ${GREEN}$TOTAL_URLS${RESET}"
echo -e "${CYAN}Scan Complete ✅${RESET}"
