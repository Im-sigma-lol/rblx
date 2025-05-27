import os

class AXKeyPayloadInterceptor:
    def __init__(self):
        self.payload_dir = "./payload/"
        self.target = "spdmteam.com/api/isauth"
        self.filename = "AX-auth-bypass.txt"
        self.content_type = "text/plain"

    def done(self): pass

    def response(self, flow):
        url = flow.request.pretty_url
        if '?' in url and self.target in url:
            print(f"[DEBUG] Query match: {url}")
            full_path = os.path.join(self.payload_dir, self.filename)
            try:
                with open(full_path, "rb") as f:
                    payload = f.read()
            except Exception as e:
                print(f"[!] Failed to read {self.filename}: {e}")
                return

            print(f"[+] Intercepted and injecting {self.filename} into {url}")
            flow.response.content = payload
            flow.response.headers["content-type"] = self.content_type
            flow.response.status_code = 200

addons = [AXKeyPayloadInterceptor()]
