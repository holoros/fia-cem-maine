#!/usr/bin/env python3
"""zenodo_draft_upload.py  (stdlib only; Bearer-auth; DRAFT by default)
Creates a Zenodo deposition, uploads files, and sets metadata. Does NOT publish unless
--publish is passed (publishing mints a permanent public DOI). The token is read from a
file and sent ONLY in the Authorization header, never in a URL or printed anywhere.
Usage:
  python3 zenodo_draft_upload.py --token-file ~/.zenodo_token \
      --metadata zenodo_metadata.json --files-list files_to_upload.txt [--sandbox] [--publish]
"""
import argparse, json, os, sys, urllib.request, urllib.error

def req(method, url, token, data=None, ctype=None):
    h = {"Authorization": "Bearer " + token}
    if ctype: h["Content-Type"] = ctype
    r = urllib.request.Request(url, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(r, timeout=300) as resp:
            body = resp.read()
            return resp.status, (json.loads(body) if body else {})
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")
        # never include the token; body is the API error only
        raise SystemExit(f"HTTP {e.code} on {method} {url.split('?')[0]}\n{body[:1500]}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--token-file", default=os.path.expanduser("~/.zenodo_token"))
    ap.add_argument("--metadata", required=True)
    ap.add_argument("--files-list", required=True)
    ap.add_argument("--sandbox", action="store_true")
    ap.add_argument("--publish", action="store_true")
    a = ap.parse_args()
    base = "https://sandbox.zenodo.org/api" if a.sandbox else "https://zenodo.org/api"
    with open(a.token_file) as f: token = f.read().strip()
    meta = json.load(open(a.metadata))
    files = [l.strip() for l in open(a.files_list) if l.strip() and not l.startswith("#")]

    # 1. create deposition
    st, dep = req("POST", base + "/deposit/depositions", token, data=b"{}", ctype="application/json")
    dep_id = dep["id"]; bucket = dep["links"]["bucket"]; html = dep["links"].get("html","")
    print(f"created draft deposition id={dep_id}")

    # 2. upload files to the bucket (PUT bucket/<filename>)
    for p in files:
        if not os.path.exists(p):
            print(f"  WARN missing, skipped: {p}"); continue
        name = os.path.basename(p)
        with open(p, "rb") as fh: payload = fh.read()
        req("PUT", f"{bucket}/{name}", token, data=payload, ctype="application/octet-stream")
        print(f"  uploaded {name} ({len(payload)} bytes)")

    # 3. set metadata
    req("PUT", f"{base}/deposit/depositions/{dep_id}", token,
        data=json.dumps(meta).encode(), ctype="application/json")
    print("metadata set")

    if a.publish:
        st, pub = req("POST", f"{base}/deposit/depositions/{dep_id}/actions/publish", token)
        doi = pub.get("doi") or pub.get("metadata",{}).get("doi","")
        print(f"PUBLISHED. DOI: {doi}")
    else:
        print(f"DRAFT (not published). Review/publish at: {html}")
        print(f"edit_api: {base}/deposit/depositions/{dep_id}")

if __name__ == "__main__":
    main()
