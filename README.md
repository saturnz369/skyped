# skyed Workspace

This is the standalone Jetson workspace for the prototype_v2 archery-target stack.

Main profile:

- `prototype_v2/YOLO26n/profile_640_fp16_archery_target/README.md`

Vendored dependencies inside this workspace:

- `prototype_v2/ultralytics`
  - local Python package copy used by model export and detector-miss extraction
- `third_party/DeepStream-Yolo`
  - local DeepStream / Jetson integration tree used by the profile launch scripts
- `vendor/e-CAM121_CUONX`
  - local IMX412 vendor package and driver assets

Use the main profile README for the full system docs and launch matrix.
Use the streaming and recordings sub-docs for operator-specific launch variants.

Important:

- this workspace is intended to stand on its own on a fresh Jetson
- the original `/home/saturnzzz/ultralytics` checkout is not required once this workspace is in place
- the external Jetson system stack is still required:
  - JetPack / L4T
  - DeepStream runtime
  - CUDA / TensorRT
  - PX4 / SIYI hardware wiring
- the local DeepStream Python venv at `third_party/DeepStream-Yolo/.venv-yolo26-sys` is intentionally machine-local and is not meant to be tracked in git
- on a fresh Jetson, recreate that venv or export `PYTHON_BIN` to a compatible Python before running model-export helper scripts

Quick start:

```bash
cd /home/saturnzzz/skyed
```

Then follow the launch blocks in:

- `prototype_v2/YOLO26n/profile_640_fp16_archery_target/README.md`
