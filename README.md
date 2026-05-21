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

Machine-local runtime pattern:

- keep the shared repo in `~/skyed`
- keep per-Jetson runtime state outside git under `~/skyped_host_runtime`
- copy `jetson.env.example` to `~/skyped_host_runtime/env/jetson.env` and set:
  - active `DISPLAY` / optional `XAUTHORITY`
  - actual Jetson Ethernet IP for MK15 RTSP
  - serial device name
  - machine-local `PYTHON_BIN`
  - optional local runs / bin directories
- the profile launchers will auto-load that env file when it exists

Keep in git:

- code
- shared launchers
- shared docs
- model inputs like `best.pt`, `.onnx`, and labels

Keep local:

- DeepStream / CUDA / TensorRT install state
- IMX412 driver install state
- Python venvs
- compiled binaries
- TensorRT engines
- logs and run artifacts

Repo vs local map:

- In this git repo now:
  - `README.md`
  - `jetson.env.example`
  - `prototype_v2/`
  - `third_party/`
  - `vendor/`
- Meaning:
  - `prototype_v2/` = active code, launchers, configs, tools, model inputs
  - `third_party/` = shared vendored source trees such as `DeepStream-Yolo`
  - `vendor/` = shared vendor package archives and bring-up notes such as the IMX412 package
  - `jetson.env.example` = template only, not the real per-Jetson env file

Local Jetson items still required for a working system:

- machine-local env file:
  - `~/skyped_host_runtime/env/jetson.env`
- machine-local runs root:
  - `~/skyped_host_runtime/runs/profile_640_fp16_archery_target/`
- machine-local optional bin root:
  - `~/skyped_host_runtime/bin/profile_640_fp16_archery_target/`
- installed Jetson system stack:
  - `/opt/nvidia/deepstream/deepstream`
  - `/usr/local/cuda`
- installed IMX412 driver state:
  - `/boot/tegra234-p3767-0000-p3768-0000-a0-4lane-imx412.dtbo`
  - `/var/nvidia/nvcam/settings/camera_overrides.isp`
- machine-local Python runtime:
  - usually pointed to by `PYTHON_BIN`
- machine-local built binaries:
  - `prototype_v2/YOLO26n/profile_640_fp16_archery_target/deepstream_yolo26_rtsp_target_control`
  - `prototype_v2/YOLO26n/profile_640_fp16_archery_target/streaming/csi_h264_rtsp_server`
- machine-local TensorRT engine:
  - `prototype_v2/YOLO26n/profile_640_fp16_archery_target/model/model_b1_gpu0_fp16.engine`

Current working examples on this Jetson:

- repo root:
  - `/home/saturnzzz/skyed`
- local env file:
  - `/home/saturnzzz/skyped_host_runtime/env/jetson.env`
- local runs root:
  - `/home/saturnzzz/skyped_host_runtime/runs/profile_640_fp16_archery_target/`
- current display:
  - `DISPLAY=:1`
- current bridge serial device:
  - `/dev/ttyUSB0`

Fresh Jetson bring-up checklist:

1. Clone this repo into `~/skyed`.
2. Install the required Jetson system stack:
   - JetPack / L4T
   - DeepStream
   - CUDA / TensorRT
3. Install the e-con IMX412 driver and overlay:
   - follow `vendor/e-CAM121_CUONX/e-CAM121_CUONX_driver_note.md`
4. Create the machine-local runtime env file:
   - copy `jetson.env.example` to `~/skyped_host_runtime/env/jetson.env`
   - set `DISPLAY`, `XAUTHORITY` if needed, `RTSP_HOST_IP`, `SERIAL_DEVICE`, and `PYTHON_BIN`
5. Build the local profile binaries:
   - `make -C ~/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target clean all`
6. Prepare or verify the shared model inputs and local engine:
   - run `prepare_prototype_v2_model.sh` if `best.pt` changed
   - let DeepStream deserialize or rebuild the local engine on that Jetson
7. Run the canonical repo launcher from the profile README.

Normal update flow after the first bring-up:

1. `git pull`
2. rebuild the local binary if code changed
3. regenerate the local engine if model/runtime compatibility changed
4. keep using the same `~/skyped_host_runtime/env/jetson.env`

Quick start:

```bash
export SKYED_ROOT="${SKYED_ROOT:-$HOME/skyed}"
cd "${SKYED_ROOT}"
```

Then follow the launch blocks in:

- `prototype_v2/YOLO26n/profile_640_fp16_archery_target/README.md`
