import os
import sys
import hashlib
import json
import requests

HEADERS = {"User-Agent": "RobloxArchiver/1.0"}
SESSION = requests.Session()

def safe_filename(name):
    return "".join(c if c.isalnum() or c in " ._-()" else "_" for c in name).strip()

def download_json(url):
    resp = SESSION.get(url, headers=HEADERS)
    return resp.json() if resp.status_code == 200 else None

def get_file_extension(data):
    if data.startswith(b"\x89PNG"):
        return "png"
    elif data.startswith(b"<?xml") or b"<roblox" in data[:200]:
        return "rbxmx"
    elif data.startswith(b"PK\x03\x04"):
        return "rbxm"
    elif data.startswith(b"{"):
        return "json"
    return "bin"

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def save_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(content)

def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

def archive_asset(asset_id):
    asset_id = str(asset_id)
    economy = download_json(f"https://economy.roblox.com/v2/assets/{asset_id}/details")
    if not economy:
        print(f"[ERROR] Asset ID {asset_id} not found in Economy API.")
        return

    creator = safe_filename(economy.get("Creator", {}).get("Name", "Unknown"))
    name = safe_filename(economy.get("Name", f"Asset_{asset_id}"))
    asset_base = os.path.join(creator, f"{name}_{asset_id}")
    os.makedirs(asset_base, exist_ok=True)
    save_json(os.path.join(asset_base, "economy.json"), economy)

    last_hash = None
    version_group = ""
    for version in range(100):
        print(f"[INFO] Checking version {version}")
        url = f"https://assetdelivery.roblox.com/v2/asset?id={asset_id}&version={version}"
        delivery_json = download_json(url)
        if not delivery_json or "locations" not in delivery_json or not delivery_json["locations"]:
            print(f"[END] Version {version} unavailable (likely 404)")
            break

        location = delivery_json["locations"][0]["location"]
        asset_data = SESSION.get(location).content
        asset_hash = sha256(asset_data)

        if last_hash == asset_hash:
            print(f"[SKIP] Duplicate version {version}, using folder: {version_group}")
        else:
            version_group = str(version) if not version_group else f"{version_group}.{version}"
            print(f"[OK] New version hash, creating folder {version_group}")

        version_path = os.path.join(asset_base, "version", version_group)
        os.makedirs(version_path, exist_ok=True)

        ext = get_file_extension(asset_data)
        filename = f"{asset_hash}.{ext}"
        save_file(os.path.join(version_path, filename), asset_data)
        save_json(os.path.join(version_path, f"{asset_id}.json"), delivery_json)

        last_hash = asset_hash

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python rbx_asset_archiver.py <assetid>")
        sys.exit(1)

    archive_asset(sys.argv[1])
