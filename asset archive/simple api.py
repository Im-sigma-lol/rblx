import os
import requests
import hashlib
import mimetypes
from urllib.parse import urlparse

def get_extension_from_headers(headers):
    content_type = headers.get("Content-Type", "").split(";")[0].strip()
    return mimetypes.guess_extension(content_type) or ".bin"

def save_asset_file(asset_url, dest_folder):
    try:
        response = requests.get(asset_url, stream=True)
        response.raise_for_status()

        # Get hash from the URL
        parsed = urlparse(asset_url)
        rbx_hash = os.path.basename(parsed.path)

        # Get extension from Content-Type
        ext = get_extension_from_headers(response.headers)
        filename = f"{rbx_hash}{ext}"
        filepath = os.path.join(dest_folder, filename)

        # Deduplication check
        counter = 1
        while os.path.exists(filepath):
            filepath = os.path.join(dest_folder, f"{rbx_hash} ({counter}){ext}")
            counter += 1

        # Save file
        with open(filepath, "wb") as f:
            for chunk in response.iter_content(4096):
                f.write(chunk)

        print(f"[+] Downloaded asset to {filepath}")
        return filepath
    except Exception as e:
        print(f"[!] Failed to download asset: {e}")
        return None
