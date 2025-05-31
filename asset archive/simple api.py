import os
import sys
import re
import json
import time
import hashlib
import mimetypes
import requests

auth_token = None

def get_json(url, headers=None, tries=5):
    if headers is None:
        headers = {}
    if auth_token:
        headers["Authorization"] = f"Bearer {auth_token}"
    for i in range(tries):
        r = requests.get(url, headers=headers)
        if r.status_code == 200:
            return r.json()
        elif r.status_code == 429:
            print(f"[!] Rate limited (429): {url} (retry {i + 1})")
            time.sleep(2 ** i)
        else:
            print(f"[!] HTTP {r.status_code}: {url}")
            break
    return None

def get_extension(content, url):
    if content[:2] == b'PK':
        return 'rbxlx'
    if content.startswith(b'<'):
        return 'rbxmx'
    try:
        head = requests.head(url)
        content_type = head.headers.get("Content-Type", "")
    except:
        content_type = ""
    ext = mimetypes.guess_extension(content_type.split(";")[0])
    return ext.replace('.', '') if ext else 'bin'

def hash_content(content):
    return hashlib.sha256(content).hexdigest()[:12]

def save_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(content)

def robust_get(url, tries=5):
    headers = {}
    if auth_token:
        headers["Authorization"] = f"Bearer {auth_token}"
    for i in range(tries):
        r = requests.get(url, headers=headers)
        if r.status_code == 200:
            return r.content
        elif r.status_code == 429:
            print(f"[!] Rate limited (429): {url} (retry {i + 1})")
            time.sleep(2 ** i)
    print(f"[!] Failed to fetch binary: {url}")
    return None

def process_asset(asset_id):
    economy_url = f"https://economy.roblox.com/v2/assets/{asset_id}/details"
    economy_data = get_json(economy_url)
    if not economy_data or 'Name' not in economy_data:
        print(f"[!] Not found or missing name: {asset_id}")
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
        content = robust_get(asset_url)
        if content is None:
            break
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

def extract_asset_ids(file_path):
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    return list(set(re.findall(r'rbxassetid://(\d+)', content)))

def main():
    global auth_token
    args = sys.argv[1:]
    i = 0
    asset_ids = []

    while i < len(args):
        arg = args[i]
        if arg == "-auth":
            auth_token = args[i + 1]
            i += 2
        elif arg == "-r":
            file_path = args[i + 1]
            asset_ids.extend(extract_asset_ids(file_path))
            i += 2
        elif arg.isdigit():
            asset_ids.append(arg)
            i += 1
        else:
            print(f"[!] Unknown argument: {arg}")
            i += 1

    if not asset_ids:
        print("Usage:")
        print("  python script.py <asset_id>")
        print("  python script.py -r <file> [-auth <token>]")
        sys.exit(1)

    asset_ids = list(set(asset_ids))
    for aid in asset_ids:
        process_asset(aid)

if __name__ == "__main__":
    main()
