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
BASE_SAVE_DIR = "/storage/emulated/0/log"

# Sanitize filenames
def sanitize(name):
    return re.sub(r'[\\/:*?"<>|]', '_', name)

# Argument parser
parser = argparse.ArgumentParser()
parser.add_argument("-auth", help="ROBLOSECURITY cookie")
parser.add_argument("-r", help="File containing rbxassetid:// references")
parser.add_argument("-D", "--directory", help="Folder containing multiple files to scan for asset IDs")
args = parser.parse_args()

# Load asset IDs from single file
asset_ids = set()
def extract_asset_ids_from_text(text):
    ids = set()
    ids.update(re.findall(r"rbxassetid://(\d+)", text))
    ids.update(re.findall(r"[?&]id=(\d+)", text))
    return ids

if args.r:
    with open(args.r, "r", encoding="utf-8") as f:
        asset_ids.update(extract_asset_ids_from_text(f.read()))

# Load from directory
if args.directory is not None:
    dir_path = args.directory
    if dir_path == "":
        dir_path = "."  # current directory
    dir_path = os.path.abspath(dir_path)
    if not os.path.isdir(dir_path):
        print(f"[!] Directory not found: {dir_path}")
        sys.exit(1)

    for fname in os.listdir(dir_path):
        fpath = os.path.join(dir_path, fname)
        if os.path.isfile(fpath):
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    asset_ids.update(extract_asset_ids_from_text(f.read()))
            except Exception as e:
                print(f"[!] Skipped {fname}: {e}")

# Function to handle rate limits
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

def hash_content(data):
    return hashlib.sha256(data).hexdigest()

def download_asset(asset_id, auth_cookie=None):
    print(f"[#] Processing Asset ID: {asset_id}")
    cookies = {}
    if auth_cookie:
        cookies[".ROBLOSECURITY"] = auth_cookie

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
        parsed = urlparse(download_url)
        ext = os.path.splitext(parsed.path)[1].split("?")[0] or ".bin"
        filename = f"{sha}{ext}"
        filepath = os.path.join(version_path, filename)

        if not os.path.exists(filepath):
            with open(filepath, "wb") as f:
                f.write(raw)
            print(f"[+] Saved {asset_id} v{version} as {filepath}")
        else:
            print(f"[=] Duplicate found for {asset_id} v{version}, skipped")

        version += 1

# Main logic
if not asset_ids:
    print("[!] No asset IDs found. Use -r or -D.")
    sys.exit(1)

for aid in asset_ids:
    try:
        download_asset(aid, args.auth)
    except Exception as e:
        print(f"[!] Error processing {aid}: {e}")
