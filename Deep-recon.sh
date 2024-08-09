#!/bin/bash

# Banner
cat << 'EOF'
 (                               (                                
  )\ )                            )\ )                              
 (()/(      (      (             (()/(     (                       
  /(_))    ))\    ))\   `  )      /(_))   ))\    (     (     (     
 (_))_    /((_)  /((_)  /(/(     (_))    /((_)   )\    )\    )\ )  
  |   \  (_))   (_))   ((_)_\    | _ \  (_))    ((_)  ((_)  _(_/(  
  | |) | / -_)  / -_)  | '_ \)   |   /  / -_)  / _|  / _ \ | ' \)) 
  |___/  \___|  \___|  | .__/    |_|_\  \___|  \__|  \___/ |_||_|  
                     |_|                                          
                               +-+-+-+-+-+-+-+-+
                               |@|k|1|l|l|u|a|x|
                               +-+-+-+-+-+-+-+-+
EOF

# Get the target domain from the user
read -p "Enter the target domain: " domain

# Set the base directory
timestamp=$(date +"%Y%m%d_%H%M%S")
base_dir="${timestamp}_${domain//./_}"
mkdir -p "$base_dir"

# Function to run a command, show output on screen, and save the output to a file
run_command() {
    command=$1
    output_file=$2
    echo "Running: $command"
    $command | tee "$output_file"
}

# Function to check if a URL is alive
check_alive_urls() {
    input_file=$1
    output_file=$2
    echo "Checking alive URLs from $input_file"
    cat "$input_file" | httprobe -s -p https:80,443 | tee "$output_file"
}

# Step 1: Information Gathering with theHarvester
info_gather_dir="${base_dir}/information_gathering"
mkdir -p "$info_gather_dir"
run_command "theHarvester -d $domain -b all" "${info_gather_dir}/theHarvester_results.txt"

# Extract IPs from theHarvester results for nmap scanning
grep -oP '(?<=IP: )[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "${info_gather_dir}/theHarvester_results.txt" | sort -u > "${info_gather_dir}/extracted_ips.txt"

# Step 2: Subdomain Enumeration
subdomain_dir="${base_dir}/subdomain_discovery"
mkdir -p "$subdomain_dir"
run_command "amass enum -d $domain" "${subdomain_dir}/amass_results.txt"
run_command "subfinder -d $domain" "${subdomain_dir}/subfinder_results.txt"
run_command "assetfinder --subs-only $domain" "${subdomain_dir}/assetfinder_results.txt"

# Step 3: DNS Enumeration
dns_enum_dir="${base_dir}/dns_enumeration"
mkdir -p "$dns_enum_dir"
run_command "dnsrecon -d $domain" "${dns_enum_dir}/dnsrecon_results.txt"
run_command "dnsenum $domain" "${dns_enum_dir}/dnsenum_results.txt"

# Extract IPs from DNS enumeration results
grep -oP '([0-9]{1,3}\.){3}[0-9]{1,3}' "${dns_enum_dir}/dnsenum_results.txt" | sort -u > "${dns_enum_dir}/dns_enum_ips.txt"

# Step 4: Port Scanning on extracted IPs (from theHarvester and DNS enumeration)
port_scan_dir="${base_dir}/port_scanning"
mkdir -p "$port_scan_dir"
for ip in $(cat "${info_gather_dir}/extracted_ips.txt" "${dns_enum_dir}/dns_enum_ips.txt" | sort -u); do
    run_command "nmap -p- -sV --script vuln $ip" "${port_scan_dir}/nmap_results_$ip.txt"
done

# Step 5: Web Application Enumeration
web_enum_dir="${base_dir}/web_application_enumeration"
mkdir -p "$web_enum_dir"
run_command "whatweb https://$domain" "${web_enum_dir}/whatweb_results.txt"
run_command "gobuster dir -u https://$domain -w /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt" "${web_enum_dir}/gobuster_results.txt"
run_command "dirsearch -u https://$domain -w /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt -e * -x 404" "${web_enum_dir}/dirsearch_results.txt"

# Step 6: URL and Endpoint Collection
url_enum_dir="${base_dir}/url_endpoint_collection"
mkdir -p "$url_enum_dir"
run_command "waybackurls $domain" "${url_enum_dir}/waybackurls_results.txt"
run_command "gau $domain" "${url_enum_dir}/gau_results.txt"
run_command "hakrawler -depth 3 -scope subs -plain -usewayback -d https://$domain" "${url_enum_dir}/hakrawler_results.txt"

# Combine all URLs found and check for alive URLs
cat "${url_enum_dir}/waybackurls_results.txt" "${url_enum_dir}/gau_results.txt" "${url_enum_dir}/hakrawler_results.txt" | sort -u > "${url_enum_dir}/all_urls_combined.txt"
check_alive_urls "${url_enum_dir}/all_urls_combined.txt" "${url_enum_dir}/all_urls_alive.txt"

# Step 7: Parameter Discovery
param_discovery_dir="${base_dir}/parameter_discovery"
mkdir -p "$param_discovery_dir"
run_command "paramspider -d $domain -o ${param_discovery_dir}/paramspider_results.txt" "${param_discovery_dir}/paramspider_log.txt"
run_command "arjun -u https://$domain -o ${param_discovery_dir}/arjun_results.txt" "${param_discovery_dir}/arjun_results.txt"

# Step 8: Hidden Parameter Discovery
hidden_param_dir="${base_dir}/hidden_parameter_discovery"
mkdir -p "$hidden_param_dir"
run_command "ffuf -u https://$domain/FUZZ -w /usr/share/wordlists/seclists/Discovery/Web-Content/burp-parameter-names.txt -o ${hidden_param_dir}/ffuf_results.txt" "${hidden_param_dir}/ffuf_log.txt"

# Step 9: Google Dork Queries
google_dork_dir="${base_dir}/google_dorks"
mkdir -p "$google_dork_dir"

queries=(
    "site:$domain"
    "site:$domain filetype:pdf"
    "site:$domain filetype:doc"
    "site:$domain intitle:index.of"
    "site:$domain inurl:login"
    "site:$domain inurl:admin"
    "site:$domain 'Powered by WordPress'"
    "site:$domain 'Django'"
    "site:$domain inurl:error"
    "site:$domain 'exception'"
    "site:$domain filetype:conf"
    "site:$domain filetype:bak"
    "site:$domain filetype:sql"
    "site:$domain intext:password"
    "site:$domain intext:username"
    "site:$domain intext:secret"
)

perform_google_dork() {
    query=$1
    output_file=$2
    echo "Running Google dork query: $query"
    encoded_query=$(echo "$query" | sed 's/ /%20/g')
    curl -s "https://www.google.com/search?q=${encoded_query}&num=100" | grep -oP '(?<=href=")/url\?q=[^"&]+' | sed 's@^/url?q=@@;s/&amp.*$//' | tee "$output_file"
}

for query in "${queries[@]}"; do
    output_file="${google_dork_dir}/$(echo "$query" | sed 's/://g;s/ //g;s/\./_/g').txt"
    perform_google_dork "$query" "$output_file"
    echo "Completed dork query: $query"
done

# Final Step: Organize all alive URLs
all_urls_dir="${base_dir}/all_urls"
mkdir -p "$all_urls_dir"
mv "${url_enum_dir}/all_urls_alive.txt" "${all_urls_dir}/all_alive_urls.txt"

echo "Reconnaissance completed. Results saved in $base_dir"

