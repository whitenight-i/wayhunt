# WayHunt 🕵️‍♂️

**WayHunt** is a fetches archived URLs for target domains and can automatically categorize **sensitive files** for faster analysis.

---

## ✨ Features

- 📜 Fetch URLs from the Internet Archive (Wayback Machine)
- 🌐 Supports wildcard mode (`*.domain/*`)
- 🔎 Optional sensitive file categorization
- 📂 Auto-creates structured output folders
- ⚡ Lightweight Bash script (no heavy dependencies)
- 🧠 Clean summary with final URL counts

---

## 🧑‍💻 Author

- **Tool Name:** WayHunt  
- **Author:** whitenight

---

## 📦 Requirements

- `bash`
- `curl`
- `grep`
- `sort`
- Linux / Kali / Parrot / Termux

✅ No extra installations required.

---

## 🚀 Installation

```bash
git clone https://github.com/whitenight-i/WayHunt.git
cd WayHunt
chmod +x wayhunt.sh

📄 Usage
Basic usage
./wayhunt.sh -i domains.txt

With wildcard mode
./wayhunt.sh -i domains.txt --wildcard

With sensitive URL filtering
./wayhunt.sh -i domains.txt --sensitive-urls

Full mode (recommended)
./wayhunt.sh -i domains.txt --wildcard --sensitive-urls

Help menu
./wayhunt.sh -h


📁 Output Structure
WayHunt/
├── wayback_urls.txt
└── sensitiveurls/
    ├── database_backup_urls.txt
    ├── config_urls.txt
    ├── logs_urls.txt
    ├── pdf_urls.txt
    ├── text_urls.txt
    ├── data_urls.txt
    ├── cloud_infrastructure.txt
    └── archive_urls.txt

