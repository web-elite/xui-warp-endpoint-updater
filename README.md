[🇮🇷](https://github.com/web-elite/xui-warp-endpoint-updater/blob/main/README-fa.md) | [🇺🇸](https://github.com/web-elite/xui-warp-endpoint-updater/blob/main/README.md)

# What is it ?
This script will automatically find the best Warp endpoint IP and place it in your x-ui panel and finally restart the xray core.
After the script has been run, you can choose how many hours it will automatically run and update the Warp endpoint IP.
This script will not interfere with your existing Warp settings.
Please make sure you have a backup of your Warp settings before running this script.

> Thanks Ptech From https://github.com/Ptechgithub/warp
> 
> Script By Me https://github.com/Web-Elite

### Installation Guide for X-UI Warp Endpoint Updater

This guide provides instructions for installing and configuring the X-UI Warp Endpoint Updater script. The script automatically finds the best Warp endpoint IP, updates your X-UI panel, and restarts the Xray core. It also allows you to set a cron job to run the script at regular intervals.

---

## Table of Contents
1. [English Installation Guide](https://github.com/web-elite/xui-warp-endpoint-updater/blob/main/README.md)
2. [راهنمای نصب به فارسی](https://github.com/web-elite/xui-warp-endpoint-updater/blob/main/README-fa.md)

---

## English Installation Guide

### Prerequisites
- A server running X-UI panel.
- `curl`, `cron`, `sqlite3`, and `jq` installed on your system.

### Step 1: Download and Run the Installer
1. Connect to your server via SSH.
2. Run the following command to download and execute the installation script:

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/install.sh)
   ```

### Step 2: Configure Warp Outbound Names
- During the installation, you will be prompted to enter the outbound names for Warp (comma-separated). For example:
  ```
  warp1,warp2,warp3
  ```
- These outbound names will be saved in the configuration file.

### Step 3: Set Cron Job Interval
- Choose how often you want the script to run:
  - Every 6 hours
  - Every 12 hours
  - Every 24 hours
  - Custom interval (e.g., every 4 hours)
- The script will automatically add the cron job based on your selection.

### Step 4: Complete Installation
- The script will:
  - Install required packages (`curl`, `cron`, `sqlite3`, `jq`).
  - Create the installation directory (`/root/x-ui-warp-endpoint-updater`).
  - Download the necessary scripts.
  - Make the scripts executable.

### Step 5: Verify Installation
- Check the installation directory for the downloaded scripts:
  ```
  /root/x-ui-warp-endpoint-updater/
  ```
- Verify the cron job is set up correctly:
  ```
  crontab -l
  ```

### Step 6: Run the Script Manually (Optional)
- You can manually run the script to test it:
  ```bash
  /root/x-ui-warp-endpoint-updater/xui-warp-endpoint-updater.sh
  ```

---
