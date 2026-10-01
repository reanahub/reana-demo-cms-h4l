#!/usr/bin/env python3
"""Fetch the XRootD file list for a CERN Open Data record (recid).

Replacement for `cernopendata-client get-file-locations --recid <RECID>
--protocol xrootd`, which is not installable in this environment. Reads the
same `_file_indices` metadata that the official client uses, straight from
the public https://opendata.cern.ch/api/records/<recid> endpoint.

Usage:
    python3 fetch_file_index.py <recid> <output.txt>
"""
import json
import sys
import urllib.request

API = "https://opendata.cern.ch/api/records/{}"


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    recid, out_path = sys.argv[1], sys.argv[2]

    with urllib.request.urlopen(API.format(recid), timeout=60) as resp:
        record = json.load(resp)

    md = record.get("metadata", record)
    title = md.get("title", "<unknown>")
    groups = md.get("_file_indices") or []

    uris = []
    for group in groups:
        for f in group.get("files", []):
            uri = f.get("uri")
            if uri and uri.endswith(".root"):
                uris.append(uri)

    with open(out_path, "w", newline="\n") as f:
        f.write("\n".join(uris) + ("\n" if uris else ""))

    print(f"recid {recid}: {title}")
    print(f"  index groups: {len(groups)}, files: {len(uris)} -> {out_path}")


if __name__ == "__main__":
    main()
