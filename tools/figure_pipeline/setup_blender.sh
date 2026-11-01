#!/usr/bin/env bash
# Blender'ı (bpy 5.0.1, Python 3.11 ister) ve MPFB 2.0.17'yi kurar. Her bulut
# oturumu sıfırdan başladığı için figür render'ından önce bir kez çalıştırılır.
# Betikler sonra `/root/bpyenv/bin/python <betik>` ile koşar (bkz. SETUP.md).
set -euo pipefail
[ -x /root/bpyenv/bin/python ] || uv venv -q -p /usr/bin/python3.11 /root/bpyenv
/root/bpyenv/bin/python -c "import bpy" 2>/dev/null || uv pip install -q -p /root/bpyenv/bin/python bpy==5.0.1 numpy
if ! /root/bpyenv/bin/python -c "import bpy; bpy.ops.preferences" -c "" 2>/dev/null || [ ! -d ~/.config/blender/5.0/extensions/user_default/mpfb ]; then
  curl -sS -L -o /tmp/mpfb.zip "https://extensions.blender.org/download/sha256:4f0a879d64a39bf646fbf5f53601ac678855da329d650617dca5737548239a87/add-on-mpfb-v2.0.17.zip"
  /root/bpyenv/bin/python -c 'import bpy; bpy.ops.extensions.package_install_files(filepath="/tmp/mpfb.zip", repo="user_default", enable_on_install=True)'
fi
/root/bpyenv/bin/python -c "import bpy; print('bpy', bpy.app.version_string)"
