Deep Recon - Automated Reconnaissance Script
![github deep-recon](https://github.com/user-attachments/assets/9b6fab63-74ea-4cc8-a45b-abf803d45823)

Author: @k1lluax

Version: 1.0.0

License: MIT

Introduction

Deep Recon is an automated reconnaissance and enumeration script designed for bug bounty programs and pentesting engagements. It leverages a variety of tools to gather comprehensive information about a target domain, including subdomains, endpoints, parameters, and more.

Features

Subdomain Enumeration: Uses sublist3r and subfinder to find subdomains.

Endpoint Collection: Gathers endpoints using katana, theHarvester, and Google Dorks.

Alive URL Checking: Verifies live URLs with httprobe.

Fuzzing and Scanning: Performs fuzzing on subdomains and scans IPs using nmap.

Organized Output: Stores results in a directory structure for easy navigation.

Installation
Clone the repository to your local machine:
git clone https://github.com/k1lluax/Deep-recon
cd Deep-recon
Make the script executable:
chmod +x Deep-recon.sh
Usage
Run the script with:
./Deep-recon.sh 
Enter the target domain: example.com

Script Workflow
Information Gathering:
The script first gathers information using theHarvester.
Subdomain Enumeration:
Subdomains are enumerated using sublist3r and subfinder.
Endpoint Collection:
Endpoints and parameters are collected using katana and Google Dorks.
Alive URL Checking:
The script checks which URLs are alive with httprobe.
Fuzzing and Scanning:
Subdomains are fuzzed, and IPs are scanned using nmap.
Requirements
Kali Linux or any Linux-based distribution.
Bash 4.0+
Installed Tools:
sublist3r
subfinder
theHarvester
katana
httprobe
nmap
waybackurls
paramspider
Configuration
Edit the script to modify default settings, such as the wordlists or directories used for storing results. Example:
WORDLIST="/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt"
OUTPUT_DIR="results"
Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the issues page and submit a pull request.

License
This project is licensed under the MIT License - see the LICENSE file for details.

