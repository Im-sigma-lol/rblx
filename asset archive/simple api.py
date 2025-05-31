import os
import re
import sys
import json
import time
import argparse
import hashlib
import requests

# Base headers (set Roblox-style User-Agent)
DEFAULT_HEADERS = {
    "User-Agent": "Roblox/WinInet",
    "Accept": "*/*",
    "Connection": "keep-alive"
}

# Auto-detect file extension based on binary content
def detect_extension(content: bytes):
    if content.startswith(b'\x89PNG'):
        return ".png"
    elif content[:2] == b'BM':
        return ".bmp"
    elif content.startswith(b'\xff\xd8'):
        return ".jpg"
    elif b'<roblox' in content.lower():
        return ".rbxmx"
    elif content[:2] == b'\x1f\x8b':
        return ".rbxm"
    return ".bin"

# Extract asset IDs from file
def extract_ids_from_file(filename):
    ids = set()
    with open(filename, 'r', encoding='utf-8') as f:
        text = f.read()
        ids.update(re.findall(r'rbxassetid://(\d+)', text))
    return list(ids)

# Save content with auto-hashing + deduplication
def save_file(content, path, filename):
    os.makedirs(path, exist_ok=True)
    full_path = os.path.join(path, filename)
    base, ext = os.path.splitext(full_path)
    counter = 1
    while os.path.exists(full_path):
        full_path = f"{base} ({counter}){ext}"
        counter += 1
    with open(full_path, 'wb') as f:
        f.write(content)
    return full_path

# Main function to download asset
def download_asset(asset_id, cookie=None):
    print(f"[#] Processing Asset ID: {asset_id}")
    headers = DEFAULT_HEADERS.copy()
    if cookie:
        headers["Cookie"] = f".ROBLOSECURITY={cookie.strip()}"

    # 1. Get metadata from economy API
    econ_url = f"https://economy.roblox.com/v2/assets/{asset_id}/details"
    econ = requests.get(econ_url, headers=headers)
    if econ.status_code != 200:
        print(f"[!] Failed economy API {asset_id} ({econ.status_code})")
        return
    econ_data = econ.json()
    name = econ_data.get("Name", "UnknownName").replace("/", "_")
    creator = econ_data.get("Creator", {}).get("Name", "UnknownCreator")
    base_path = f"/storage/emulated/0/log/{creator}/{name}_{asset_id}/"

    # Save economy.json
    with open(os.path.join(base_path, "economy.json"), "w", encoding="utf-8") as f:
        json.dump(econ_data, f, indent=2)

    version = 1
    while True:
        # 2. Get asset delivery metadata (asset.json)
        asset_url = f"https://assetdelivery.roblox.com/v2/asset?id={asset_id}&version={version}"
        asset_res = requests.get(asset_url, headers=headers)

        if asset_res.status_code == 401:
            print("[!] Unauthorized (401): Check your .ROBLOSECURITY")
            return
        elif asset_res.status_code == 429:
            print("[!] Rate-limited! Waiting 5s...")
            time.sleep(5)
            continue
        elif asset_res.status_code != 200:
            print(f"[*] No more versions after v{version - 1}")
            break

        asset_data = asset_res.json()
        version_dir = os.path.join(base_path, str(version))
        os.makedirs(version_dir, exist_ok=True)

        # Save asset.json
        with open(os.path.join(version_dir, "asset.json"), "w", encoding="utf-8") as f:
            json.dump(asset_data, f, indent=2)

        # 3. Download actual asset
        locations = asset_data.get("locations", [])
        if not locations:
            print(f"[!] No asset location for v{version}")
        else:
            raw_url = locations[0]["location"]
            asset_bin = requests.get(raw_url, headers=headers)
            if asset_bin.status_code == 200:
                data = asset_bin.content
                file_hash = hashlib.sha256(data).hexdigest()
                ext = detect_extension(data)
                saved = save_file(data, version_dir, f"{file_hash}{ext}")
                print(f"[+] Saved {asset_id} v{version} as {saved}")
            else:
                print(f"[!] Failed to download binary: {raw_url}")

        version += 1
        time.sleep(0.25)  # cooldown to prevent rate-limits

# CLI runner
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Roblox Asset Downloader")
    parser.add_argument("ids", nargs="*", help="Asset IDs")
    parser.add_argument("-r", metavar="file", help="File to parse rbxassetid:// IDs from")
    parser.add_argument("-auth", help="Your .ROBLOSECURITY cookie")

    args = parser.parse_args()
    all_ids = set(args.ids)

    if args.r:
        file_ids = extract_ids_from_file(args.r)
        all_ids.update(file_ids)

    for aid in all_ids:
        download_asset(aid, args.auth)
