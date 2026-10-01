#!/usr/bin/env python3
import json
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("input_file")
parser.add_argument("output_json")
parser.add_argument("--chunk-size", type=int, default=8)
parser.add_argument("--lists-dir", default="workflow/chunk_lists")
args = parser.parse_args()

with open(args.input_file) as f:
    files = [line.strip() for line in f if line.strip()]

os.makedirs(args.lists_dir, exist_ok=True)

chunks = {}
for i in range(0, len(files), args.chunk_size):
    chunk_id = f"chunk_{i // args.chunk_size:04d}"
    chunk_files = files[i:i + args.chunk_size]
    chunks[chunk_id] = chunk_files
    with open(os.path.join(args.lists_dir, chunk_id + ".txt"), "w", newline="\n") as cf:
        cf.write("\n".join(chunk_files) + "\n")

with open(args.output_json, "w", newline="\n") as f:
    json.dump(chunks, f, indent=2)
    f.write("\n")  # keep the file prettier-clean (CI runs `prettier -c .`)

print(f"Файлів: {len(files)}, чанків: {len(chunks)}")
print(f"Списки чанків записано у {args.lists_dir}/")
