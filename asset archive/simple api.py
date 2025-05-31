import httpx, os, argparse, re, hashlib, json, asyncio
from pathlib import Path

def get_ext(data):
    if data.startswith(b"<roblox"): return ".rbxmx"
    if data.startswith(b"<?xml"): return ".xml"
    if data[1:4] == b"PNG": return ".png"
    if data[:2] == b"\xFF\xD8": return ".jpg"
    if data.startswith(b"{") or data.startswith(b"["): return ".json"
    return ".bin"

def get_hash(data): return hashlib.sha256(data).hexdigest()

async def fetch(client, url):
    while True:
        res = await client.get(url)
        if res.status_code == 429:
            print("[!] Rate limited, retrying...")
            await asyncio.sleep(2)
            continue
        return res

async def download_asset(asset_id, client, base_path):
    eid = str(asset_id)
    economy_url = f"https://economy.roblox.com/v2/assets/{eid}/details"
    econ = await fetch(client, economy_url)
    if econ.status_code != 200:
        print(f"[!] Economy failed {eid} ({econ.status_code})")
        return
    data = econ.json()
    creator = data.get("Creator", {}).get("Name", "UnknownCreator")
    name = data.get("Name", "UnknownName").replace("/", "_")
    base = base_path / f"{creator}/{name}_{eid}"
    base.mkdir(parents=True, exist_ok=True)
    with open(base / "economy.json", "w") as f: json.dump(data, f, indent=2)

    meta_url = f"https://assetdelivery.roblox.com/v2/asset?id={eid}"
    meta = await fetch(client, meta_url)
    if meta.status_code == 401:
        print(f"[!] HTTP 401 Unauthorized for asset {eid}")
        return
    if meta.status_code != 200:
        print(f"[!] Asset meta failed {eid} ({meta.status_code})")
        return
    meta_json = meta.json()
    with open(base / "asset.json", "w") as f: json.dump(meta_json, f, indent=2)

    version, prev_hash = 0, None
    while True:
        version_url = f"https://assetdelivery.roblox.com/v2/asset?id={eid}&version={version}"
        ver_res = await fetch(client, version_url)
        if ver_res.status_code == 404:
            print(f"[*] No more versions for {eid}")
            break
        if ver_res.status_code != 200:
            print(f"[!] Error version {version} ({ver_res.status_code})")
            break
        content = ver_res.content
        hash_now = get_hash(content)
        ext = get_ext(content)

        version_folder = base / f"{version}"
        version_folder.mkdir(parents=True, exist_ok=True)

        asset_path = version_folder / f"{hash_now}{ext}"
        if not asset_path.exists():
            with open(asset_path, "wb") as f: f.write(content)
            print(f"[+] Saved {eid} v{version} as {asset_path}")
        else:
            print(f"[-] Already exists: {asset_path}")
        version += 1

async def run_main(ids, cookie):
    headers = {
        "User-Agent": "Roblox/WinInet",
        "Accept": "*/*",
        "Referer": "https://www.roblox.com"
    }
    if cookie: headers["Cookie"] = f".ROBLOSECURITY={cookie.strip()}"
    base = Path.cwd()
    async with httpx.AsyncClient(headers=headers, timeout=30) as client:
        for aid in ids:
            try: await download_asset(aid, client, base)
            except Exception as e: print(f"[!] Fail {aid}: {e}")

def extract_ids_from_file(filename):
    with open(filename, "r") as f: text = f.read()
    return re.findall(r"rbxassetid://(\d+)", text)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("assetid", nargs="?", help="Asset ID")
    parser.add_argument("-r", "--readfile", help="Read file for rbxassetid://")
    parser.add_argument("-auth", help="ROBLOSECURITY cookie")
    args = parser.parse_args()

    ids = []
    if args.assetid: ids.append(args.assetid)
    if args.readfile: ids.extend(extract_ids_from_file(args.readfile))
    if not ids: return print("No assetid given.")
    asyncio.run(run_main(ids, args.auth))

if __name__ == "__main__": main()
