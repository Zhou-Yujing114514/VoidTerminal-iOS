#!/usr/bin/env python3
"""打包 IPA：用标准 DEFLATE 压缩，确保自签工具兼容性"""
import zipfile
import os
import sys

app_path = sys.argv[1] if len(sys.argv) > 1 else "Payload/VoidTerminal.app"
output = sys.argv[2] if len(sys.argv) > 2 else "VoidTerminal.ipa"

with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as zf:
    zf.writestr('Payload/', '')
    zf.writestr('Payload/VoidTerminal.app/', '')
    for root, dirs, files in os.walk(app_path):
        for d in dirs:
            rel = os.path.relpath(os.path.join(root, d), os.path.dirname(app_path))
            zf.writestr(rel + '/', '')
        for f in files:
            fp = os.path.join(root, f)
            rel = os.path.relpath(fp, os.path.dirname(app_path))
            zf.write(fp, rel)

print(f'IPA packaged: {output} ({os.path.getsize(output)} bytes)')
