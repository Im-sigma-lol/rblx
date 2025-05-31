import os
import sys
import hashlib
import json
import requests
from urllib.parse import quote

HEADERS = {"User-Agent": "RobloxArchiver/1.0"}
SESSION = requests.Session()

def safe_filename(name):
    return "".join(c if c.isalnum() or c in " ._-()" else "_" for c in name).strip()

def download_json(url):
    resp = SESSION.get(url, headers=HEADERS)
    if resp.status_code == 200:
        return resp.json()
    return None

def get_file_extension(content, default="bin"):
    if content.startswith(b"<roblox"):
        return "rbxmx"
    elif content.startswith(b"<?xml"):
        return "xml"
    elif content.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    elif content.startswith(b"PK\x03\x04"):  # zip or rbxm sometimes
        return "rbxm"
    elif content.startswith(b"{") and b"}" in content:
        return "json"
    return default

def file_hash(data):
    return hashlib.sha256(data).hexdigest()

def save_file(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)

def save_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2)

def archive_asset(asset_id):
    asset_id = str(asset_id)
    economy = download_json(f"https://economy.roblox.com/v2/assets/{asset_id}/details")
    if not economy:
        print(f"[ERROR] Asset ID {asset_id} not found in Economy API.")
        return

    owner = economy.get("Creator", {}).get("Name", "UnknownOwner")
    name = economy.get("Name", f"Asset_{asset_id}")
    asset_dir = os.path.join(safe_filename(owner), f"{safe_filename(name)}_{asset_id}")
    os.makedirs(asset_dir, exist_ok=True)

    save_json(os.path.join(asset_dir, "economy.json"), economy)

    prev_hash = None
    last_folder = ""
    for version in range(100):  # Max 100 versions
        url = f"https://assetdelivery.roblox.com/v2/asset?id={asset_id}&version={version}"
        meta_url = f"https://assetdelivery.roblox.com/v2/assets/{asset_id}/versions/{version}"
        asset_resp = SESSION.get(url, headers=HEADERS)
        if asset_resp.status_code == 404:
            print(f"[INFO] Version {version} not found, stopping.")
            break
        elif asset_resp.status_code != 200:
            print(f"[WARN] Failed to download version {version}")
            continue

        data = asset_resp.content
        current_hash = file_hash(data)

        if prev_hash == current_hash:
            # Append to previous folder
            new_folder = last_folder
        else:
            # New version folder
            new_folder = str(version) if not last_folder else f"{last_folder}.{version}" if prev_hash else str(version)

        version_path = os.path.join(asset_dir, "version", new_folder)
        os.makedirs(version_path, exist_ok=True)

        ext = get_file_extension(data)
        file_path = os.path.join(version_path, f"asset.{ext}")
        if not os.path.exists(file_path):
            save_file(file_path, data)
            print(f"[OK] Saved version {version} as {file_path}")
        else:
            print(f"[SKIP] Version {version} already saved.")

        # Save version-specific JSON too
        version_meta = download_json(meta_url)
        if version_meta:
            save_json(os.path.join(version_path, f"{asset_id}.json"), version_meta)

        prev_hash = current_hash
        last_folder = new_folder

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python rbx_asset_archiver.py <assetid>")
        sys.exit(1)

    archive_asset(sys.argv[1])
