# pe_controller.ps1

### This tool is provided for educational and defensive purposes only. The author is not responsible for misuse or incorrect interpretation of the output. Always validate findings with additional tools and context.


A PowerShell script for **network connection analysis and threat hunting** on Windows systems.

The script parses active TCP connections, extracts **public remote IP addresses only**, maps them to local processes (PID and process name), and enriches the data using **ipinfo[.]io** to provide basic network intelligence.

This tool is designed for **situational awareness**, **baseline creation**, and **manual anomaly detection**.

---

## Features

- Parses `netstat -ano` output
- Extracts **only PUBLIC remote IPv4 addresses**
- Maps:
  - PID
  - Process name
  - Remote IP
- Enriches IP data via **ipinfo[.]io**:
  - Organization (ASN)
  - Hostname
  - Country
- Excludes:
  - Private IP ranges
  - Loopback and 0.0.0.0
  - PID 0 and idle/kernel artifacts
  - The PowerShell process executing the script itself
- Displays results in a **clean table**
- Optional output saving to file
- Built-in help

---

## Why this script exists

Modern malware, backdoors, and misbehaving software often communicate over HTTPS using legitimate cloud providers.

This script helps answer questions such as:
- *Which local process is talking to the internet?*
- *Is this process expected to have outbound connections?*
- *Which ASN / organization owns the remote endpoint?*
- *Are there unexpected countries or hosting providers involved?*

⚠️ This is **not an antivirus** and **not an IDS**.  
It is a **manual investigation and threat-hunting helper**.

---

## Requirements

- Windows
- PowerShell 5.1 or later
- `netstat` (built into Windows)
- Internet connectivity for `ipinfo[.]io` enrichment

No additional modules are required.

---

## External Service Usage (ipinfo[.]io)

This script queries **ipinfo[.]io** to enrich public IP addresses with:
- ASN / Organization
- Hostname
- Country

### Important notes:
- Only **public IP addresses** are sent
- No local, private, or personal data is transmitted
- Requests are unauthenticated and subject to ipinfo[.]io rate limits


---

## Usage

```powershell
.\pe_controller.ps1 [-o output.txt] [-h]
