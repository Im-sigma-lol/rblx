import os
import sys
import json
import time
import hashlib
import mimetypes
import requests

def get_json(url, headers=None, tries=5):
    for i in range(tries):
        r = requests.get(url, headers=headers)
        if r.status_code == 200:
            return r.json()
        elif r.status_code == 429:
            print("[!] Rate limited. Sleeping...")
            time.sleep(2 ** i)
        else:
            print(f"[!] Failed to get JSON from {url} (status {r.status_code})")
            break
    return None

def get_extension(content, url):
    if content[:2] == b'PK':
        return 'rbxlx'
    if content.startswith(b'<'):
        return 'rbxmx'
    content_type = requests.head(url).headers.get("Content-Type", "")
    ext = mimetypes.guess_extension(content_type.split(";")[0])
    return ext.replace('.', '') if ext else 'bin'

def hash_content(content):
    return hashlib.sha256(content).hexdigest()[:12]

def save_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(content)

def main(asset_id):
    economy_url = f"https://economy.roblox.com/v2/assets/{asset_id}/details"
    economy_data = get_json(economy_url)
    if not economy_data or 'Name' not in economy_data:
        print("[!] Asset not found in Economy API.")
        return

    name = economy_data["Name"].strip().replace("/", "_").replace("\\", "_")
    creator = economy_data.get("Creator", {}).get("Name", "Unknown")
    base_dir = f"{creator}/{name}_{asset_id}"
    os.makedirs(base_dir, exist_ok=True)
    with open(os.path.join(base_dir, "economy.json"), "w") as f:
        json.dump(economy_data, f, indent=2)

    version = 0
    last_hash = None
    current_group = []
    while True:
        meta_url = f"https://assetdelivery.roblox.com/v2/asset?id={asset_id}&version={version}"
        meta = get_json(meta_url)
        if not meta or "locations" not in meta:
            break
        with open(os.path.join(base_dir, f"{asset_id}.json"), "w") as f:
            json.dump(meta, f, indent=2)

        asset_url = meta["locations"][0]["location"]
        content = requests.get(asset_url).content
        file_hash = hash_content(content)

        if last_hash and file_hash == last_hash:
            current_group.append(version)
        else:
            if current_group:
                vname = f"{current_group[0]}-{current_group[-1]}" if len(current_group) > 1 else str(current_group[0])
                group_path = os.path.join(base_dir, vname)
                os.makedirs(group_path, exist_ok=True)
                save_file(os.path.join(group_path, f"{last_hash}.{last_ext}"), last_content)
            current_group = [version]
            last_hash = file_hash
            last_content = content
            last_ext = get_extension(content, asset_url)
        version += 1

    if current_group:
        vname = f"{current_group[0]}-{current_group[-1]}" if len(current_group) > 1 else str(current_group[0])
        group_path = os.path.join(base_dir, vname)
        os.makedirs(group_path, exist_ok=True)
        save_file(os.path.join(group_path, f"{last_hash}.{last_ext}"), last_content)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python roblox_asset_downloader.py <asset_id>")
        sys.exit(1)
    main(sys.argv[1])
