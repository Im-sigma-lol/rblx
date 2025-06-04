import os
import re
import sys
import json
import time
import hashlib
import argparse
import requests
from urllib.parse import urlparse

# Constants
HEADERS = {
    "User-Agent": "Roblox/WinInet",
    "Accept": "application/json",
}

# Argument parser
parser = argparse.ArgumentParser()
parser.add_argument("-auth", help="ROBLOSECURITY cookie")
parser.add_argument("-r", action="store_true", help="Enable recursive asset ID scan mode")
parser.add_argument("-D", help="Directory (relative) to scan recursively for asset IDs")
parser.add_argument("-DA", help="Directory (absolute) to scan recursively for asset IDs")
parser.add_argument("-p", help="Output base path for downloads")
args = parser.parse_args()

# Sanitize filenames
# Sanitize filenames
def sanitize(name):
    name = re.sub(r'[\\/:*?"<>|\t\r\n]', '_', name)
    return name.strip()
# Default save directory is current working directory
BASE_SAVE_DIR = os.path.abspath(args.p) if args.p else os.getcwd()

# Extract all asset IDs from text
def extract_ids_from_text(content):
    ids = set()
    ids.update(re.findall(r"rbxassetid://(\d+)", content))
    ids.update(re.findall(r"[?&]id=(\d+)", content))
    return ids

# Recursively scan directory for asset IDs
def scan_directory(path):
    found_ids = set()
    for root, _, files in os.walk(path):
        for file in files:
            try:
                full_path = os.path.join(root, file)
                with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                    found_ids.update(extract_ids_from_text(f.read()))
            except Exception as e:
                print(f"[!] Failed reading {file}: {e}")
    return found_ids

# HTTP rate-limited request
def safe_get(url, headers, cookies=None, stream=False):
    retries = 0
    while retries < 5:
        r = requests.get(url, headers=headers, cookies=cookies, stream=stream)
        if r.status_code == 429:
            print(f"[!] Rate limited: {url}")
            time.sleep(2 ** retries)
            retries += 1
        else:
            return r
    raise Exception(f"Failed after 5 retries: {url}")

# SHA256 hash for content
def hash_content(data):
    return hashlib.sha256(data).hexdigest()

# Download single asset
def download_asset(asset_id, auth_cookie=None):
    print(f"[#] Processing Asset ID: {asset_id}")
    cookies = {}
    if auth_cookie:
        cookies[".ROBLOSECURITY"] = auth_cookie

    # Get economy metadata
    econ_url = f"https://economy.roblox.com/v2/assets/{asset_id}/details"
    econ_resp = safe_get(econ_url, HEADERS, cookies)
    if econ_resp.status_code != 200:
        print(f"[!] Failed to fetch economy for {asset_id}")
        return

    econ_data = econ_resp.json()
    name = sanitize(econ_data.get("Name", "Unknown"))
    creator = sanitize(econ_data.get("Creator", {}).get("Name", "Unknown"))
    base_path = os.path.join(BASE_SAVE_DIR, creator, f"{name}_{asset_id}")
    os.makedirs(base_path, exist_ok=True)

    with open(os.path.join(base_path, "economy.json"), "w", encoding="utf-8") as f:
        json.dump(econ_data, f, indent=2)

    # Versioning loop
    version = 1
    while True:
        version_path = os.path.join(base_path, "version", str(version))
        os.makedirs(version_path, exist_ok=True)

        asset_url = f"https://assetdelivery.roblox.com/v2/asset?id={asset_id}&version={version}"
        asset_resp = safe_get(asset_url, HEADERS, cookies)
        if asset_resp.status_code == 404:
            print(f"[*] No more versions for {asset_id}")
            break
        elif asset_resp.status_code == 401:
            print(f"[!] HTTP 401: {asset_url}")
            break

        asset_data = asset_resp.json()
        with open(os.path.join(version_path, "asset.json"), "w", encoding="utf-8") as f:
            json.dump(asset_data, f, indent=2)

        locations = asset_data.get("locations", [])
        if not locations:
            print(f"[!] No downloadable location for {asset_id} v{version}")
            version += 1
            continue

        download_url = locations[0]["location"]
        file_resp = safe_get(download_url, HEADERS, cookies, stream=True)
        if file_resp.status_code != 200:
            print(f"[!] Failed to download file for {asset_id} v{version}")
            version += 1
            continue

        raw = file_resp.content
        sha = hash_content(raw)

        # Guess file extension
        parsed = urlparse(download_url)
        ext = os.path.splitext(parsed.path)[1].split("?")[0] or ".bin"
        filename = f"{sha}{ext}"
        filepath = os.path.join(version_path, filename)

        # Deduplication check
        if not os.path.exists(filepath):
            with open(filepath, "wb") as f:
                f.write(raw)
            print(f"[+] Saved {asset_id} v{version} as {filepath}")
        else:
            print(f"[=] Duplicate found for {asset_id} v{version}, skipped")

        version += 1

# Main logic
asset_ids = set()

if args.r:
    if args.D:
        scan_path = os.path.abspath(os.path.join(os.getcwd(), args.D))
        if os.path.isdir(scan_path):
            asset_ids.update(scan_directory(scan_path))
        else:
            print(f"[!] -D path not found: {scan_path}")
    if args.DA:
        if os.path.isdir(args.DA):
            asset_ids.update(scan_directory(args.DA))
        else:
            print(f"[!] -DA path not found: {args.DA}")

if not asset_ids:
    print("[!] No asset IDs found. Use -r with -D or -DA to scan directories.")
    sys.exit(1)

for aid in asset_ids:
    try:
        download_asset(aid, args.auth)
    except Exception as e:
        print(f"[!] Error processing {aid}: {e}")
