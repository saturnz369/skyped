# Profile 640 FP16 Archery Target

This is the main real `prototype_v2` profile for the custom single-class `target_face` detector:

- `/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target`

Portable path rule:

- runtime scripts resolve their own paths relative to the checked-out repo
- the README command blocks use `/home/saturnzzz/skyed` as the reference clone path on this Jetson
- on another Jetson, either clone to `~/skyed` as the standard path, or replace that prefix with the local repo root before running the command

This README is the source-of-truth overview for:

- hardware setup
- current verified runtime state
- model / engine workflow
- launch modes
- run artifacts
- control / video architecture
- recording and post-run analysis

Sub-docs still exist, but they are operator-focused extensions:

- `streaming/README.md`
- `recordings/README.md`

If this README and the launch scripts ever disagree, trust the scripts first and then update this README immediately.

## Purpose

This profile is the custom archery-target version of the clean `prototype_v2` runtime.

Compared with the base `profile_640_fp16`:

- the detector is one-class `target_face`
- the infer config is wired for `TARGET_CLASS_ID=0`
- the runtime keeps the same split between:
  - metadata/control branch
  - monitoring/video branch

The goal is:

- use DeepStream + TensorRT for live CSI inference/tracking
- publish only lightweight target metadata into control
- send live MAVLink gimbal commands through PX4 to the SIYI gimbal
- allow preview / RTSP / recording to lag or drop without dragging control with it

## Repo And Machine-Local Runtime

Shared in git:

- code
- launch scripts
- shared configs
- shared docs
- shared model inputs:
  - `model/best.pt`
  - `model/target_face_v1_native_640.onnx`
  - `model/labels.txt`

Machine-local outside git:

- DeepStream / CUDA / TensorRT install state
- IMX412 driver / overlay install state
- bridge or export Python venvs
- compiled binaries
- TensorRT engines
- logs and run bundles
- per-Jetson env file:
  - `~/skyped_host_runtime/env/jetson.env`

Launcher behavior:

- profile launchers auto-load `~/skyped_host_runtime/env/jetson.env` when it exists
- set `HOST_RUNTIME_ROOT` or `HOST_RUNTIME_ENV_FILE` if your local runtime tree lives elsewhere
- you can still source the env file manually before launch if you prefer explicit control

## Fresh Jetson Bring-Up

Use this order on a new Jetson:

1. Clone the repo:
   - `git clone https://github.com/saturnz369/skyped.git ~/skyed`
2. Install the external system stack:
   - JetPack / L4T
   - DeepStream
   - CUDA / TensorRT
3. Complete IMX412 bring-up:
   - follow `vendor/e-CAM121_CUONX/e-CAM121_CUONX_driver_note.md`
4. Create the machine-local runtime env:
   - copy `~/skyed/jetson.env.example` to `~/skyped_host_runtime/env/jetson.env`
   - set the actual `DISPLAY`, `XAUTHORITY` if needed, `RTSP_HOST_IP`, `SERIAL_DEVICE`, and `PYTHON_BIN`
5. Build the local binaries:
   - `make -C ~/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target clean all`
6. Prepare the model inputs if needed:
   - run `~/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/prepare_prototype_v2_model.sh` after replacing `model/best.pt`
7. Let that Jetson use or rebuild its own local engine:
   - `model/model_b1_gpu0_fp16.engine`
8. Run the canonical launcher from this repo:
   - local-only, stream-only, or full PX4/SIYI path from the sections below

Update flow on an already-prepared Jetson:

1. `git pull`
2. rebuild local binaries if code changed
3. regenerate the local engine if the model or TensorRT compatibility changed
4. keep the same machine-local `~/skyped_host_runtime/env/jetson.env`

## Current Verified State

This is the current known-good state of the profile:

- main deployment camera is the e-con IMX412 setup
- current working camera path is `CAM1`
- current application default is `2028x1112 @ 60`
- YOLO inference stays `640x640`
- current MK15 RTSP path is:
  - `rtsp://<JETSON_ETH_IP>:8554/stream`
- current field example URL is:
  - `rtsp://192.168.144.100:8554/stream`
- current full-control launcher works again with:
  - IMX412
  - PX4
  - SIYI
  - MK15 RTSP
- the control path is latest-only and binary shared-memory based
- stale metadata is age-gated in the Python bridge
- monitoring branch errors are disposable by default
- run artifacts are bundled automatically under `RUNS_ROOT/<tag>/`
  - default is machine-local host runtime under `~/skyped_host_runtime/runs/profile_640_fp16_archery_target/yolo26n/<tag>/`
  - set `HOST_RUNTIME_RUNS_ROOT` or `RUNS_ROOT` only if you want a different local run root
- health printing / health log / latency summary are integrated
- Level 1 target memory is integrated in the Python bridge:
  - when visual target is lost briefly, hold/coast on the last trusted gimbal angle
  - after a short timeout, perform local search around that remembered angle
  - no geo/vehicle-pose recovery is enabled yet

Current active runtime files:

- `model/best.pt`
- `model/target_face_v1_native_640.onnx`
- `model/labels.txt`

Current machine-local runtime artifact:

- `model/model_b1_gpu0_fp16.engine`

Important note:

- the current accepted weight in `model/best.pt` is the active runtime model
- the current promoted runtime weight is `training_weight/v3/best.pt`
- `target_face_v1_native_640.onnx` is still the current ONNX filename for compatibility
- do not assume the `v1` string in that ONNX filename means the active model is still training `v1`

Training archives are preserved separately:

- `training_weight/v1/`
- `training_weight/v2/`
- `training_weight/v3/`

## Hardware And Runtime Stack

Current main stack:

- Jetson: Orin NX
- JetPack / L4T: JetPack `6.2.1`, L4T `36.4.4`
- DeepStream: `/opt/nvidia/deepstream/deepstream -> deepstream-7.1`
- CUDA: `/usr/local/cuda-12.6`
- main camera: e-con `e-CAM121_CUONX` / IMX412
- main camera connector: `CAM1`
- working FFC type: `22-pin`, `0.5 mm pitch`, `Type A`
- vendored DeepStream-Yolo parser:
  - `/home/saturnzzz/skyed/third_party/DeepStream-Yolo/nvdsinfer_custom_impl_Yolo/libnvdsinfer_custom_impl_Yolo.so`
- Python runtime for model export and bridge:
  - usually set with `PYTHON_BIN`
  - current repo-local fallback is `/home/saturnzzz/skyed/third_party/DeepStream-Yolo/.venv-yolo26-sys/bin/python`
- normal MAVLink serial device:
  - `/dev/ttyUSB0`
- normal USB-UART converter identity:
  - CP2102 / Silicon Labs style adapter

Physical system around this profile:

- CSI camera -> Jetson
- Jetson USB-UART -> PX4 / gimbal serial path
- PX4 -> SIYI gimbal through MAVLink gimbal-manager path
- Jetson Ethernet -> MK15 air unit for RTSP monitoring
- optional Jetson local preview over HDMI / DP / desktop session

Current practical wiring detail:

- IMX412 camera:
  - physically connected to Jetson `CAM1`
  - uses the working `22-pin`, `0.5 mm`, `Type A` FFC path above
- Jetson -> PX4 control serial link:
  - Jetson side normally appears as `/dev/ttyUSB0`
  - current USB-UART adapter is CP2102 / Silicon Labs style
  - current launcher default baud is `921600 8N1`
  - current launcher identity defaults are:
    - `MAV_SOURCE_SYSTEM=42`
    - `MAV_SOURCE_COMPONENT=191`
    - `MAV_TARGET_SYSTEM=1`
    - `MAV_TARGET_COMPONENT=154`
    - `GIMBAL_DEVICE_ID=154`
  - in the current field setup this is `TELEM2 / MAV_1`
  - `MAV_1` is configured as the Jetson companion link
  - `MAV_1` uses `Onboard` mode with flow control forced off
  - PX4 `TELEM2` baud must match the Jetson side:
    - `921600 8N1`
- PX4 -> SIYI gimbal serial link:
  - this is a separate PX4 UART from the Jetson bridge UART
  - in the current field setup this is `TELEM3 / MAV_2`
  - `MAV_2` is configured as the SIYI gimbal link
  - `MAV_2` uses `Gimbal` mode with forwarding enabled and flow control forced off
  - current baud is `115200 8N1`
  - this repo does not directly open that gimbal UART from Jetson
  - the repo assumes PX4 already exposes the SIYI gimbal through the MAVLink gimbal-manager path
- MK15 air unit -> PX4 telemetry/control side:
  - `TELEM1` stays reserved for the MK15 / normal telemetry side
  - current practical setup keeps the MK15 air unit on PX4 `TELEM1`
  - `MAV_0` is the normal telemetry / GCS side
  - current baud is `57600 8N1`
  - practical meaning:
    - `TELEM1` is reserved for MK15
    - do not reuse that port for the Jetson bridge or the SIYI gimbal
- Jetson Ethernet -> MK15:
  - Jetson Ethernet goes to the MK15 air unit network side
  - current stream URL pattern is `rtsp://<JETSON_ETH_IP>:8554/stream`
  - current field example URL is `rtsp://192.168.144.100:8554/stream`
- local Jetson operator view:
  - optional local preview comes from the active desktop display session

Current PX4 serial map summary:

- `TELEM1 / MK15 air unit`
  - `57600 8N1`
- `TELEM2 / Jetson bridge`
  - `921600 8N1`
- `TELEM3 / SIYI gimbal`
  - `115200 8N1`

Verified PX4 MAVLink instance mapping for this field setup:

- `MAV_0 -> TELEM1 -> normal GCS / telemetry side`
- `MAV_1 -> TELEM2 -> Jetson companion link`
- `MAV_2 -> TELEM3 -> SIYI gimbal link`

Working parameter sequence:

```text
1. TELEM1 stays reserved for the MK15 / normal telemetry side
   - MAV_0_CONFIG = TELEM1
   - MAV_0_MODE = Normal
   - SER_TEL1_BAUD = 57600 8N1

2. Jetson companion link uses TELEM2
   - MAV_1_CONFIG = TELEM2
   - MAV_1_MODE = Onboard
   - MAV_1_FLOW_CTRL = Force off
   - SER_TEL2_BAUD = 921600 8N1

3. SIYI gimbal link uses TELEM3
   - MAV_2_CONFIG = TELEM3
   - MAV_2_MODE = Gimbal
   - MAV_2_FORWARD = Enabled
   - MAV_2_FLOW_CTRL = Force off
   - SER_TEL3_BAUD = 115200 8N1

4. Mount / gimbal-manager side
   - MNT_MODE_IN = MAVLink gimbal protocol v2
   - MNT_MODE_OUT = MAVLink gimbal protocol v2
   - MNT_MAV_SYSID = 1
   - MNT_MAV_COMPID = 154

5. Gimbal control identity
   - target_system = 1
   - target_component = 154
   - SIYI gimbal device component ID = 154

6. Critical SIYI-side control bit
   - component 154 -> set_att_en = 1
```

Practical meaning:

- telemetry can be visible in QGC without necessarily moving the gimbal
- gimbal motion only started working once the SIYI-side attitude-enable flag was set on component `154`
- when control is healthy, the Jetson bridge talks to PX4 on `TELEM2`, and PX4 forwards the gimbal-manager commands to `TELEM3`
- if `MAVLINK: OK` but `GIMBAL: BAD` and the SIYI does not move, check the physical `TELEM3` / SIYI serial connector first
- do not reuse `TELEM1` for the Jetson bridge or SIYI gimbal

If serial or USB naming changes after reconnecting hardware, check:

```bash
ls -l /dev/ttyUSB* /dev/serial/by-id 2>/dev/null
```

## MK15 And Operator View Setup

This main README should carry the shared MK15/operator setup, while the deeper launch variants and stream-specific troubleshooting stay in:

- [streaming/README.md](/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/streaming/README.md)

### Plain Meaning

Current monitoring path:

```text
CSI camera -> Jetson -> H.264 RTSP -> MK15 air unit -> MK15 handheld FPV app
```

For the full combined runtime:

```text
CSI camera -> DeepStream / YOLO / tracker / control metadata -> PX4 / SIYI gimbal
                                         -> H.264 RTSP -> MK15 FPV
```

Important separation:

- the `RTSP stream` is the monitoring/video branch
- the `gimbal control` path is separate and uses metadata/MAVLink, not the RTSP video itself

### Jetson Ethernet To MK15

Current working convention:

- Jetson internet/Codex link stays on Wi-Fi
- Jetson Ethernet `enP8p1s0` goes to the MK15 air unit LAN side
- the Jetson RTSP address exposed to MK15 is:
  - `rtsp://<JETSON_ETH_IP>:8554/stream`
- if this Jetson uses the old static address convention, that becomes:
  - `rtsp://192.168.144.100:8554/stream`

Always check the actual Ethernet IP before typing the MK15 URL:

```bash
ip -br addr show enP8p1s0
```

If the MK15 Ethernet profile is not already created on this Jetson, use:

```bash
sudo nmcli con add type ethernet ifname enP8p1s0 con-name mk15 \
  ipv4.method manual ipv4.addresses 192.168.144.100/24 \
  ipv4.never-default yes ipv6.method ignore
sudo nmcli con up mk15
```

Quick check:

```bash
ip -br addr show enP8p1s0
ping -I enP8p1s0 -c 2 192.168.144.11
```

Expected Jetson Ethernet address:

```text
192.168.144.100/24
```

### MK15 FPV App Side

On the MK15 handheld:

1. Open the `FPV` app.
2. Set `Camera A` to the canonical MK15 URL:
   - `rtsp://192.168.144.100:8554/stream`
3. If this Jetson intentionally overrides `RTSP_HOST_IP` in `~/skyped_host_runtime/env/jetson.env`, use that IP instead.
4. Reopen the stream view after the Jetson launcher is running.

Practical meaning:

- camera-only RTSP, YOLO-overlay RTSP, and the full YOLO+gimbal launch all reuse the same MK15 URL
- `QGroundControl` is not required for video-only MK15 stream testing

### Local Jetson Preview

The optional local preview window is separate from the MK15 stream.

Current working convention:

- local preview uses the active Jetson desktop session
- that can be `DISPLAY=:0` on one Jetson and `DISPLAY=:1` on another
- the launchers now honor the current `DISPLAY` or load it from `~/skyped_host_runtime/env/jetson.env`
- if you do not want the local preview window, use `SHOW=0`

Practical note:

- local preview requires an active Jetson GUI session
- MK15 RTSP can still run with `SHOW=0`

### Stream Size Meaning

Do not mix up these 3 things:

1. camera capture size into the pipeline
2. YOLO inference size
3. RTSP output shown on MK15

Current profile defaults:

- camera capture: `2028x1112 @ 60`
- YOLO inference: `640x640`
- MK15 RTSP path in this profile also runs from the same `2028x1112 @ 60` capture mode unless you intentionally override the launch vars

So `profile_640_fp16` describes the inference profile, not the MK15 stream resolution.

## IMX412 Driver Setup And Recovery Workflow

This profile is built around the e-con `e-CAM121_CUONX` / IMX412 stack. If the IMX412 side stops working, this is the driver workflow that got it working on this Jetson.

Important path note:

- the absolute paths in this section, such as `/home/saturnzzz/...`, are the paths from this working Jetson
- on another identical Jetson, replace `/home/saturnzzz/...` with the correct path for that machine and user
- practical example:
- if the new machine uses user `ubuntu`, then `/home/saturnzzz/skyed` becomes `/home/ubuntu/skyed`

Vendor reference folder:

```bash
/home/saturnzzz/skyed/vendor/e-CAM121_CUONX
```

Correct vendor package for this machine:

```bash
/home/saturnzzz/skyed/vendor/e-CAM121_CUONX/e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05.tar.gz
```

Important:

- this Jetson is on `JetPack 6.2.1 / L4T 36.4.4 / kernel 5.15.148-tegra`
- do **not** install the old `L4T35.x` e-con package on this machine
- the working physical connection is:
  - camera on `CAM1`
  - `22-pin`, `0.5 mm pitch`, `Type A` FFC
  - correct cable orientation on both ends

### IMX412 Base System Check

Before installing the IMX412 driver on another Jetson, confirm the OS baseline matches:

```bash
cat /etc/nv_tegra_release
uname -r
```

Expected baseline for this profile:

- JetPack `6.2.1`
- L4T `36.4.4`
- kernel `5.15.148-tegra`

If the new Jetson does not match this baseline, do not assume this exact camera-driver workflow will behave the same way.

### IMX412 Fresh Install

Use this when bringing up IMX412 on a clean or repaired Jetson image:

```bash
cd /home/saturnzzz/skyed/vendor/e-CAM121_CUONX
tar -xaf e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05.tar.gz
cd e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05
sudo chmod +x ./install_binaries.sh
sudo -E ./install_binaries.sh
```

What that installer changes:

- installs the e-con camera driver module
- installs the matching NVIDIA camera support modules
- installs the IMX412 device-tree overlay
- updates `/boot/extlinux/extlinux.conf`
- installs the e-con Argus ISP tuning file:
  - `/var/nvidia/nvcam/settings/camera_overrides.isp`

Expected boot state after install:

```text
DEFAULT JetsonIO
MENU LABEL Custom Header Config: <CSI Jetson camera EIMX412 4lane>
OVERLAYS /boot/tegra234-p3767-0000-p3768-0000-a0-4lane-imx412.dtbo
```

The vendor installer reboots the Jetson at the end.

### IMX412 Post-Reboot Verification

After reboot, verify the stack with:

```bash
grep -nE "^DEFAULT|^LABEL|MENU LABEL|OVERLAYS" /boot/extlinux/extlinux.conf
lsmod | grep -E "e_con_cam|tegra_camera"
ls -l /dev/video* /dev/media* /dev/v4l-subdev* 2>/dev/null
v4l2-ctl --list-devices
media-ctl -p -d /dev/media0
```

Expected signs of success:

- `DEFAULT JetsonIO` is active
- `/boot/tegra234-p3767-0000-p3768-0000-a0-4lane-imx412.dtbo` is the active overlay
- `e_con_cam` is loaded
- `/dev/video0` exists
- `v4l2-ctl --list-devices` shows:
  - `vi-output, e-con_cam 9-0042`
- `media-ctl` shows:
  - `e-con_cam 9-0042`

Argus / CSI smoke test:

```bash
gst-launch-1.0 -q nvarguscamerasrc sensor-id=0 num-buffers=1 ! 'video/x-raw(memory:NVMM),width=2028,height=1112,framerate=60/1' ! fakesink
```

### IMX412 If Color Or ISP Looks Wrong

The IMX412 image quality on this profile depends on the e-con ISP override being active.

Working active file:

```bash
/var/nvidia/nvcam/settings/camera_overrides.isp
```

Known-good vendor source:

```bash
/home/saturnzzz/skyed/vendor/e-CAM121_CUONX/e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05/misc/camera_overrides_jetson-onx.isp
```

Quick integrity check:

```bash
sha256sum /var/nvidia/nvcam/settings/camera_overrides.isp \
  /home/saturnzzz/skyed/vendor/e-CAM121_CUONX/e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05/misc/camera_overrides_jetson-onx.isp
```

Expected current good hash:

```text
0ce06fc106f550fd555a3749c9ae6de625b15ad4325a6a38e07f923de6fd8643
```

If the hashes do not match and the IMX412 image looks wrong, restore the vendor ISP file, restart Argus, and reboot if needed.

## Backup Camera Workflow: ArduCam IMX477

Normal deployment camera is still IMX412. The ArduCam IMX477 is the backup plan only.

Use this backup path only when:

- IMX412 hardware is unavailable
- you intentionally want to test the ArduCam path
- you accept that this is a separate camera stack from the main profile

Important:

- do **not** assume NVIDIA stock `imx477-A` or `imx477-C` overlays are enough here
- on this Jetson, stock overlay probing failed with:
  - `imx477 9-001a: i2c read probe (-121)`
- the working path was ArduCam's own installer

### ArduCam IMX477 Install Flow

Power off, physically swap to the ArduCam, then run:

```bash
cd ~
wget https://github.com/ArduCAM/MIPI_Camera/releases/download/v0.0.3/install_full.sh
chmod +x install_full.sh
./install_full.sh -m imx477
sudo depmod -a
sudo reboot
```

Practical note:

- during the original install, the script printed:
  - `mv: cannot stat '/boot/arducam/arducam_csi2.ko': No such file or directory`
- despite that message, the IMX477 stack worked after `depmod -a` and reboot

What the installer changes:

- installs ArduCam camera modules
- installs ArduCam boot image / DTB assets under `/boot/arducam`
- updates boot to use the ArduCam camera stack

### ArduCam Post-Reboot Verification

After reboot, verify with:

```bash
ls -l /dev/video* /dev/media* /dev/v4l-subdev* 2>/dev/null
v4l2-ctl --list-devices
media-ctl -p -d /dev/media0
journalctl -k --no-pager | grep -Ei "imx477|arducam|camera|camrtc|nvargus|csi|probe|i2c" | tail -n 120
gst-launch-1.0 -q nvarguscamerasrc sensor-id=0 num-buffers=1 ! 'video/x-raw(memory:NVMM),width=1920,height=1080,framerate=60/1' ! fakesink
```

Expected signs of success:

- `/dev/video0` exists
- `/dev/v4l-subdev0..2` exist
- `media-ctl` shows:
  - `imx477 9-001a`
- Argus capture succeeds at:
  - `1920x1080 @ 60`

### Returning From ArduCam Back To IMX412

Before using this main profile again:

1. restore the IMX412 boot path:
   - `DEFAULT JetsonIO`
   - `OVERLAYS /boot/tegra234-p3767-0000-p3768-0000-a0-4lane-imx412.dtbo`
2. physically swap the camera back to the e-con IMX412 on `CAM1`
3. make sure the e-con ISP file is active again:
   - `/var/nvidia/nvcam/settings/camera_overrides.isp`
4. reboot and rerun the IMX412 verification steps above

## Camera Modes

Main profile default:

- `SENSOR_ID=0`
- `CAMERA_WIDTH=2028`
- `CAMERA_HEIGHT=1112`
- `CAMERA_FPS_N=60`
- `CAMERA_FPS_D=1`

Meaning:

- raw CSI input is `2028x1112 @ 60`
- YOLO inference is still `640x640`
- RTSP / preview operate from the full pipeline capture mode, not from `640x640`

Known alternate modes:

- lighter fallback:
  - `1280x720 @ 60`
- high-speed candidate:
  - `2028x1112 @ 240`

Use `2028x1112 @ 60` as the normal source-of-truth deployment mode unless a specific test needs something else.

## Operator Notes

Use these rules when testing or flying:

- do not confuse RTSP smoothness with control latency
- local preview and MK15 stream can lag a little while control is still fresh
- if you want the cleanest real control test, reduce monitoring load first
- if you want reproducible comparisons, keep:
  - same power mode
  - same camera mode
  - same model
  - same gains
  - same launch path

Useful mental model:

- camera/input quality affects detection quality
- TensorRT / DeepStream / tracker affect metadata quality and timing
- RTSP / display mostly affect what the operator sees

## Repository Layout

This profile now lives inside the standalone `skyed` workspace, not inside the old `ultralytics` checkout.

Top-level workspace map:

- `/home/saturnzzz/skyed/`
  - workspace root
- `/home/saturnzzz/skyed/README.md`
  - top-level workspace note
- `/home/saturnzzz/skyed/prototype_v2/`
  - main project area for this prototype generation
- `/home/saturnzzz/skyed/prototype_v2/ultralytics/`
  - vendored Python `ultralytics` package copy used by helper scripts
- `/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/`
  - this active runtime profile
- `/home/saturnzzz/skyed/third_party/DeepStream-Yolo/`
  - vendored DeepStream / Jetson integration tree
- `/home/saturnzzz/skyed/vendor/e-CAM121_CUONX/`
  - vendored IMX412 driver package, docs, and recovery note

Inside this active profile, the main files that matter are:

- `deepstream_yolo26_rtsp_target_control.c`
  - main DeepStream application
- `deepstream_px4_siyi_bridge.py`
  - live bridge from latest metadata to control commands
- `px4_siyi_live_bridge.py`
  - MAVLink backend for PX4 / SIYI control
- `run_deepstream_yolo26_rtsp_target_control.sh`
  - direct DeepStream app launcher
- `run_deepstream_px4_siyi_bridge.sh`
  - full combined live launcher
- `streaming/run_mk15_yolo_gimbal_rtsp.sh`
  - one-shot full MK15 + gimbal launcher
- `prepare_prototype_v2_model.sh`
  - ONNX preparation from `model/best.pt`
- `config/config_infer_primary_yolo26.txt`
  - infer config
- `config/tracker_config.txt`
  - tracker config
- `tools/bridge_latency_report.py`
  - latency summary

Practical rule:

- if it is about the live field runtime, start from this profile README
- if it is about vendored dependencies, look one level up into `prototype_v2/ultralytics`, `third_party/DeepStream-Yolo`, and `vendor/e-CAM121_CUONX`

## Launch Matrix

Run all commands from:

```bash
cd /home/saturnzzz/skyed
```

### 1. Rebuild The App

```bash
make -C /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target clean all
```

### 2. Prepare ONNX From The Active Weight

Use this after replacing `model/best.pt` with a new accepted weight:

```bash
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/prepare_prototype_v2_model.sh
```

This refreshes:

- `model/target_face_v1_native_640.onnx`
- `model/labels.txt`

and removes any old engine so the next run rebuilds or reloads cleanly.

### 3. Preview Only, No PX4, No Gimbal

Use this for first visual validation:

```bash
export SHOW=1
export RTSP_ENABLE=0
export SENSOR_ID=0
export CAMERA_WIDTH=2028
export CAMERA_HEIGHT=1112
export CAMERA_FPS_N=60
export CAMERA_FPS_D=1
export TARGET_CLASS_ID=0
export SELECTION='center'
export MAX_FRAMES=0
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/run_deepstream_yolo26_rtsp_target_control.sh
```

### 4. Bridge Dry-Run

Use this before PX4/SIYI is involved:

```bash
export DRY_RUN_MAVLINK=1
export PRINT_STATE=1
export PRINT_HEALTH=1
export HEALTH_PRINT_INTERVAL_SEC=1.0
export SHOW=0
export RTSP_ENABLE=0
export MAX_FRAMES=90
export TARGET_CLASS_ID=0
export SELECTION='center'
export CONTROL_API=command
export LIVE_CONTROL_MODE=angle-target
export MAV_INVERT_PAN=0
export MAV_INVERT_TILT=0
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/run_deepstream_px4_siyi_bridge.sh
```

### 5. Real Full Control, Local Only

Use this when PX4/SIYI is connected and you want local preview but not MK15 RTSP:

```bash
export SHOW=1
export RTSP_ENABLE=0
export SENSOR_ID=0
export CAMERA_WIDTH=2028
export CAMERA_HEIGHT=1112
export CAMERA_FPS_N=60
export CAMERA_FPS_D=1
export TARGET_CLASS_ID=0
export SELECTION='center'
export CONTROL_API=command
export LIVE_CONTROL_MODE=angle-target
export INITIAL_YAW_DEG=0.0
export INITIAL_PITCH_DEG=0.0
export MIN_YAW_ANGLE_DEG=-100.0
export MAX_YAW_ANGLE_DEG=100.0
export MIN_PITCH_ANGLE_DEG=-90.0
export MAX_PITCH_ANGLE_DEG=25.0
export MAX_YAW_RATE_DPS=90
export MAX_PITCH_RATE_DPS=90
export YAW_LOCK=0
export PITCH_LOCK=0
export PAN_GAIN=0.91
export TILT_GAIN=0.55
export DEADZONE=0.048
export SMOOTH_ALPHA=0.39
export FAST_SMOOTH_ALPHA=0.81
export FAST_ERROR_ZONE=0.15
export TILT_DEADZONE=0.10
export TILT_SMOOTH_ALPHA=0.18
export TILT_FAST_SMOOTH_ALPHA=0.45
export TILT_FAST_ERROR_ZONE=0.35
export COMMAND_BOOST_ZONE=0.095
export MIN_ACTIVE_COMMAND=0.20
export RESPONSE_GAMMA=0.63
export PAN_FEEDFORWARD_GAIN=0.18
export TILT_FEEDFORWARD_GAIN=0.04
export FEEDFORWARD_ALPHA=0.40
export FEEDFORWARD_LIMIT=0.14
export FEEDFORWARD_ACTIVATION_ZONE=0.07
export TARGET_MEMORY_ENABLE=1
export TARGET_MEMORY_LEVEL=1
export SEARCH_PITCH_DEFAULT=-45.0
export CANDIDATE_STABLE_FRAMES=3
export SHORT_LOST_TIMEOUT_MS=450
export PREDICT_TIMEOUT_MS=1200
export LOCAL_SEARCH_TIMEOUT_MS=3000
export WIDE_SEARCH_TIMEOUT_MS=5000
export LOCAL_SEARCH_INITIAL_DEG=3.0
export LOCAL_SEARCH_MAX_DEG=10.0
export LOCAL_SEARCH_PITCH_SCALE=0.35
export SEARCH_RATE_DEG_S=18.0
export UNCERTAINTY_GROWTH_RATE=0.35
export CONFIDENCE_THRESHOLD=0.35
export EDGE_MARGIN_THRESHOLD=0.82
export TRACKING_UNSTABLE_THRESHOLD=0.70
export MAV_INVERT_PAN=0
export MAV_INVERT_TILT=0
export SERIAL_DEVICE='/dev/ttyUSB0'
export SERIAL_BAUD=921600
export MAV_SOURCE_SYSTEM=42
export MAV_SOURCE_COMPONENT=191
export MAV_TARGET_SYSTEM=1
export MAV_TARGET_COMPONENT=154
export GIMBAL_DEVICE_ID=154
export PRINT_HEALTH=1
export HEALTH_PRINT_INTERVAL_SEC=1.0
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/run_deepstream_px4_siyi_bridge.sh
```

Preflight hold-angle note:

- `INITIAL_PITCH_DEG` and `INITIAL_YAW_DEG` set the first angle-target hold setpoint before live tracking starts
- if you want the camera to start slightly looking down before flight, change for example:
  - `INITIAL_PITCH_DEG=-12.0`
- `PITCH_LOCK=1` and `YAW_LOCK=1` are optional MAVLink gimbal-manager lock flags
- keep them at `0` unless you intentionally want lock mode

Level 1 target-memory note:

- `TARGET_MEMORY_ENABLE=1` enables the current last-angle recovery layer
- if YOLO/tracker misses briefly, the bridge stays in `LOST_COAST` and keeps the last trusted angle
- after `PREDICT_TIMEOUT_MS`, it enters `LOCAL_SEARCH` around the remembered yaw/pitch
- after local search timeout, it enters `WIDE_SEARCH`
- if `FINAL_SWEEP_ENABLE=1`, it then runs one last test-only `FINAL_SWEEP`: pitch to `FINAL_SWEEP_PITCH_DEG`, yaw to left limit, then yaw across to right limit
- if final sweep is disabled or still fails, it reports `MISSION_RETRY_OR_FAIL`
- set `TARGET_MEMORY_ENABLE=0` to return to the old pure visual-control behavior
- if recovery fully fails, `MISSION_RETRY_OR_FAIL` recenters the gimbal to neutral instead of leaving it parked on the last lost angle
- keep `FINAL_SWEEP_ENABLE=0` for the current baseline prototype; enable it only when you intentionally want the late-stage reacquisition sweep during testing

Future target-memory levels to come back to:

- Level 2: attitude-compensated recovery
  - use drone attitude and gimbal feedback to keep the remembered line of sight stable through vehicle motion
- Level 3: velocity-compensated recovery
  - use drone velocity to predict how fast the target direction should drift while the aircraft keeps moving
- Level 4: ground-point recovery
  - estimate a ground-referenced target point from pose, altitude, and camera/gimbal geometry, then re-point from that estimate after loss

### 6. Real Full Control With MK15

This is the normal one-shot flight/test launcher:

```bash
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/streaming/run_mk15_yolo_gimbal_rtsp.sh
```

If you want the additional search before the gimbal reaches fail state, use these overrides before the same launcher:

```bash
export FINAL_SWEEP_ENABLE=1
export FINAL_SWEEP_PITCH_DEG=-45.0
export FINAL_SWEEP_YAW_RATE_DPS=90.0
export FINAL_SWEEP_PITCH_RATE_DPS=90.0
export FINAL_SWEEP_EDGE_DWELL_MS=0
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/streaming/run_mk15_yolo_gimbal_rtsp.sh
```

Normal meaning:

- this does **not** record by default
- current default is `RAW_RECORD_ENABLE=0`
- use [recordings/README.md](/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/recordings/README.md) when you intentionally want the same application launch with clean recording enabled

MK15 URL:

```text
rtsp://192.168.144.100:8554/stream
```

If this Jetson intentionally overrides `RTSP_HOST_IP` in `~/skyped_host_runtime/env/jetson.env`, use that IP instead.

### 7. Real Full Control With Clean Dataset Recording

One-shot recording launcher:

```bash
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/recordings/run_mk15_yolo_gimbal_rtsp_record.sh
```

If you want the additional search before the gimbal reaches fail state during a recording run, use these overrides before the same launcher:

```bash
export FINAL_SWEEP_ENABLE=1
export FINAL_SWEEP_PITCH_DEG=-45.0
export FINAL_SWEEP_YAW_RATE_DPS=90.0
export FINAL_SWEEP_PITCH_RATE_DPS=90.0
export FINAL_SWEEP_EDGE_DWELL_MS=0
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/recordings/run_mk15_yolo_gimbal_rtsp_record.sh
```

That wrapper keeps the normal full-control defaults, but forces `RAW_RECORD_ENABLE=1`.
Use the dedicated recording operator note for the rest of the recording workflow:

- [recordings/README.md](/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/recordings/README.md)

### 8. Extract Failure Frames After The Run

Use the recording README for the post-run recording and extraction flow:

- [recordings/README.md](/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/recordings/README.md)

## Model And Engine Workflow

Active runtime model files:

- `model/best.pt`
- `model/target_face_v1_native_640.onnx`
- `model/labels.txt`

Machine-local build artifact:

- `model/model_b1_gpu0_fp16.engine`

Training archives:

- `training_weight/v1/best.pt`
- `training_weight/v1/best.onnx`
- `training_weight/v2/best.pt`
- `training_weight/v2/best.onnx`
- `training_weight/v3/best.pt`
- `training_weight/v3/best.onnx`

Normal rule:

- copy the accepted weight into `model/best.pt`
- run `prepare_prototype_v2_model.sh`
- rebuild or reload the local engine on that Jetson
- test under the same runtime settings as the previous model

Current repo state:

- `model/best.pt` is now aligned to `training_weight/v3/best.pt`
- `model/target_face_v1_native_640.onnx` is the ONNX exported from that `v3` weight
- the engine filename stays `model/model_b1_gpu0_fp16.engine` for runtime compatibility

### Promote `training_weight/v3` To Active Runtime Model

Use this when `training_weight/v3/best.pt` is the next accepted weight:

```bash
cp /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/training_weight/v3/best.pt /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/model/best.pt
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/prepare_prototype_v2_model.sh
```

That step exports a fresh:

- `model/target_face_v1_native_640.onnx`

and removes the old local engine so the next DeepStream run or manual `trtexec` build uses the new model.
It keeps the compatibility runtime ONNX at `model/target_face_v1_native_640.onnx`; do not track a temporary `model/best.onnx`.

### Fast First-Pass Engine Build

```bash
/usr/src/tensorrt/bin/trtexec --onnx=/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/model/target_face_v1_native_640.onnx --saveEngine=/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/model/model_b1_gpu0_fp16.engine --fp16 --memPoolSize=workspace:256 --avgTiming=1 --builderOptimizationLevel=0 --skipInference
```

### Serious Final Engine Build

```bash
/usr/src/tensorrt/bin/trtexec --onnx=/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/model/target_face_v1_native_640.onnx --saveEngine=/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/model/model_b1_gpu0_fp16.engine --fp16 --memPoolSize=workspace:1024 --builderOptimizationLevel=5 --skipInference
```

If you want to force a clean rebuild:

```bash
rm -f /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/model/model_b1_gpu0_fp16.engine
```

## Run Artifacts

By default:

- `RUN_ARTIFACTS_ENABLE=1`

Each launcher creates:

```text
RUNS_ROOT/<tag>/
```

and refreshes:

```text
RUNS_ROOT/latest/
```

Typical files inside one run:

- `config_used.yaml`
- `detection_log.jsonl`
- `health_log.jsonl`
- `deepstream.log`
- `performance_summary.txt`
- `recording_clean.mkv` when `RAW_RECORD_ENABLE=1`

Use `performance_summary.txt` for run-to-run comparison. It is the run-level aggregate for FPS, latency, metadata age, dropped frames, and carried timestamps. The live `CAMERA: ... | YOLO: ... | CONTROL: ...` health line is for operator monitoring only; it is a snapshot, not the summary.

Current helper tool prefers `runs/latest/` automatically:

- `tools/bridge_latency_report.py`

Practical note:

- by default, launchers place run bundles under `~/skyped_host_runtime/runs/profile_640_fp16_archery_target/yolo26n/`
- if `HOST_RUNTIME_RUNS_ROOT` is set in `~/skyped_host_runtime/env/jetson.env`, that override becomes `RUNS_ROOT`
- on this Jetson, the verified run bundle path is under:
  - `/home/saturnzzz/skyped_host_runtime/runs/profile_640_fp16_archery_target/yolo26n/`

If your run bundle has no detector rows, the helper reports can stop with:

- `No JSON rows found`

That usually means the main run never produced bridge metadata for that attempt, or you pointed the helper at the wrong `RUNS_ROOT/latest` bundle.

If you intentionally want the old loose-file behavior:

```bash
export RUN_ARTIFACTS_ENABLE=0
```

## Recording And Post-Run Analysis

The clean recording path is intentionally separate from overlays and RTSP:

```text
camera-side source tee
-> leaky raw-record queue
-> hardware H.264 encoder
-> local clean MKV
```

That means the recording is valid dataset material and does not include:

- OSD
- debug crosshair
- RTSP drawing
- preview artifacts

### Latency Summary

```bash
source ~/skyped_host_runtime/env/jetson.env
python3 /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/tools/bridge_latency_report.py
```

## Runtime Architecture

Actual live control flow:

```text
CSI camera
-> DeepStream / YOLO / tracker
-> tracker src pad-probe
-> latest-only binary shared-memory metadata snapshot
-> separate Python bridge loop
-> MAVLink / PX4 gimbal-manager
-> SIYI gimbal
```

Monitoring / operator path:

```text
tracker output
-> leaky video queue
-> nvvideoconvert
-> nvdsosd
-> tee
-> display queue -> local preview
-> rtsp queue -> H.264 -> RTSP
```

Dataset recording path:

```text
camera-side source tee
-> leaky raw-record queue
-> hardware H.264 encoder
-> clean MKV
```

### System-Level Flow

This is the conceptual `prototype_v2` workflow for this profile:

```text
CSI camera
-> GStreamer / DeepStream video pipeline
-> primary detector (YOLO)
-> multi-object tracker
-> target-selection + raw control-metadata stage
-> split into 2 logical branches:
   1. video / monitoring branch
   2. metadata / control branch
```

### Detailed Pipeline Meaning

1. `CSI camera -> DeepStream pipeline`
   - the image enters through the Jetson CSI path
   - in practice this is the live source for the full runtime
   - from the architecture point of view, this image path should stay inside the high-performance pipeline

2. `DeepStream pipeline -> primary inference stage`
   - YOLO is the primary object detector
   - this stage produces:
     - class id
     - confidence
     - bounding box
   - this is the detector / inference stage that feeds object metadata forward

3. `primary inference -> tracker`
   - tracking assigns persistent IDs to detections across frames
   - so the system is not only doing frame-by-frame detection
   - it is maintaining tracked targets over time
   - this is what makes single-target follow possible

4. `tracker -> target-selection + raw control-metadata stage`
   - one tracked target is selected for control
   - from that selected target, the profile computes the raw control-side quantities:
     - target center in image coordinates
     - normalized image-plane error:
       - `dx_norm`
       - `dy_norm`
   - that raw target state is published into the latest-only shared-memory snapshot
   - the final smoothed / shaped control output is then computed in the Python bridge, not in the DeepStream C callback

### The Important Branch Split

After detection, tracking, and target-control calculation, the profile is logically split into 2 branches.

```text
DeepStream detect/track/control source
-> Branch A: video / stream / monitoring
-> Branch B: metadata / control
```

#### Branch A: Video / Monitoring Branch

```text
DeepStream app
-> overlay / OSD / local preview / RTSP-style monitoring path
```

- this branch is for the operator / developer to see the result
- it is where you visually inspect:
  - detections
  - tracking IDs
  - selected target
  - crosshair / error line / control overlay
- this branch is **not** the control loop itself

#### Branch B: Metadata / Control Branch

```text
tracked target metadata
-> target position / bbox center
-> normalized image-center error
-> virtual pan_cmd / tilt_cmd stage
-> latest shared-memory snapshot
-> PX4 bridge
-> filtered / shaped pan_cmd / tilt_cmd
-> PX4 MAVLink gimbal-manager path
-> SIYI gimbal
```

- this is the real control branch
- this branch should use lightweight target metadata, not full exported video frames
- the important control variables are derived from tracked metadata, not from the RTSP stream and not from a second full-frame CPU-side image-processing path

So the real control chain is:

```text
detect
-> track
-> choose target
-> compute dx_norm / dy_norm
-> compute virtual pan_cmd / tilt_cmd intent
-> publish latest metadata snapshot
-> Python bridge computes final smoothed pan_cmd / tilt_cmd
-> Level 1 target memory may hold/search around last trusted angle during target loss
-> map into MAVLink gimbal commands
-> send through PX4
-> move SIYI
```

### Target Memory And Reacquisition

Current implemented level:

- `TARGET_MEMORY_LEVEL=1`
- last-angle recovery only
- no drone attitude compensation yet
- no velocity compensation yet
- no ground-point estimate yet

Level 1 behavior:

```text
LOCKED_VISUAL
-> target temporarily missing
-> LOST_COAST: keep last trusted yaw/pitch
-> LOST_POINT_TO_LAST_ANGLE: keep pointing at remembered direction
-> LOCAL_SEARCH: small smooth search around remembered yaw/pitch
-> WIDE_SEARCH: fallback search pitch and wider local yaw motion
-> optional FINAL_SWEEP: fixed downward pitch plus full yaw sweep for test-time reacquisition
-> MISSION_RETRY_OR_FAIL: tell logs/offboard that visual recovery failed
```

Why this belongs in Python:

- DeepStream C callback stays metadata-only
- memory / state-manager / recovery policy lives in the fixed-rate bridge loop
- MAVLink still receives only the latest intended command

Current recovery log fields in `detection_log.jsonl`:

- `target_memory_enabled`
- `target_memory_level`
- `target_memory_state`
- `tracking_quality`
- `target_memory_track_id`
- `memory_age_ms`
- `target_uncertainty`
- `predicted_yaw_deg`
- `predicted_pitch_deg`
- `local_search_offset_yaw_deg`
- `local_search_offset_pitch_deg`
- `reacquired`

Future levels need more PX4 telemetry before implementation:

- Level 2 attitude compensation needs vehicle attitude and decoded gimbal attitude
- Level 3 velocity compensation needs local/global velocity
- Level 4 ground-point recovery needs vehicle position, altitude, camera/gimbal calibration, and a ground-plane assumption

### What Is Clean Now

- live MAVLink send is not done in the DeepStream callback
- latest metadata handoff is binary, not per-frame JSON parsing
- Python bridge reads only the latest snapshot
- metadata older than `METADATA_MAX_AGE_MS` is treated as stale
- RTSP can be disabled independently with `RTSP_ENABLE=0`
- monitoring branch queues are leaky by design
- monitoring branch errors are non-fatal by default
- run health and latency proof are built into the runtime

### Current Default Hardening

Important runtime defaults now in effect:

- `METADATA_MAX_AGE_MS=150`
- `TARGET_MEMORY_ENABLE=1`
- `TARGET_MEMORY_LEVEL=1`
- `MONITORING_ERRORS_FATAL=0`
- `RUN_ARTIFACTS_ENABLE=1`
- `PRINT_HEALTH=1`

Useful debug overrides:

- `export METADATA_MAX_AGE_MS=0`
  - disables the stale-metadata age gate
- `export MONITORING_ERRORS_FATAL=1`
  - returns to strict fail-fast behavior if you want the whole app to stop on monitoring branch errors

### Current Residual Weak Point

The architecture is already in a good practical state, but one weak point still remains:

- the DeepStream tracker callback still owns target selection / target state extraction in C

That is acceptable for now. Do not casually refactor it unless there is a measured reason.

## Runtime Timing And Health Fields

The main bridge log is `detection_log.jsonl`.

Useful timing fields:

- `vision_latency_ms`
  - video pipeline timing from frame-side handoff into metadata publish
- `metadata_age_ms`
  - age of the latest metadata when Python uses it
- `mavlink_delay_ms`
  - Python control step to MAVLink send timing
- `feedback_delay_ms`
  - send-to-feedback timing when live feedback exists
- `display_frame_lag`
  - preview lag in frames
- `rtsp_frame_lag`
  - RTSP lag in frames
- `metadata_gap_frames`
  - missed metadata sequence gaps
- `video_frame_gap`
  - frame index gaps

Health print is optional and low-rate:

```bash
export PRINT_HEALTH=1
export HEALTH_PRINT_INTERVAL_SEC=1.0
```

It summarizes:

- camera status
- DeepStream status
- YOLO FPS
- target state / ID
- metadata age
- control Hz
- MAVLink status
- gimbal feedback status
- Jetson temperature
- video branch status
- recording status

## Current Control Preset

Current accepted live preset:

```text
TARGET_CLASS_ID=0
SELECTION=center
PAN_GAIN=0.91
TILT_GAIN=0.55
DEADZONE=0.048
SMOOTH_ALPHA=0.39
FAST_SMOOTH_ALPHA=0.81
FAST_ERROR_ZONE=0.15
TILT_DEADZONE=0.10
TILT_SMOOTH_ALPHA=0.18
TILT_FAST_SMOOTH_ALPHA=0.45
TILT_FAST_ERROR_ZONE=0.35
COMMAND_BOOST_ZONE=0.095
MIN_ACTIVE_COMMAND=0.20
RESPONSE_GAMMA=0.63
PAN_FEEDFORWARD_GAIN=0.18
TILT_FEEDFORWARD_GAIN=0.04
FEEDFORWARD_ALPHA=0.40
FEEDFORWARD_LIMIT=0.14
FEEDFORWARD_ACTIVATION_ZONE=0.07
MAX_YAW_RATE_DPS=90
MAX_PITCH_RATE_DPS=90
CONTROL_API=command
LIVE_CONTROL_MODE=angle-target
TARGET_MEMORY_ENABLE=1
TARGET_MEMORY_LEVEL=1
SHORT_LOST_TIMEOUT_MS=450
PREDICT_TIMEOUT_MS=1200
LOCAL_SEARCH_TIMEOUT_MS=3000
LOCAL_SEARCH_INITIAL_DEG=3.0
LOCAL_SEARCH_MAX_DEG=10.0
SEARCH_RATE_DEG_S=18.0
MAV_INVERT_PAN=0
MAV_INVERT_TILT=0
```

Use launcher defaults first. Override manually only when you are intentionally tuning.

## Quick Health Checks

### Camera

```bash
gst-launch-1.0 -q nvarguscamerasrc sensor-id=0 num-buffers=1 ! 'video/x-raw(memory:NVMM),width=2028,height=1112,framerate=60/1' ! fakesink
```

### Serial / Gimbal Adapter

```bash
ls -l /dev/ttyUSB* /dev/serial/by-id 2>/dev/null
```

### Local RTSP Check

```bash
ffprobe -rtsp_transport tcp -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate -of default=nw=1 rtsp://127.0.0.1:8554/stream
```

## Notes To Future Humans And Codex

Do not casually break these invariants:

- keep IMX412 as the normal deployment camera
- keep `2028x1112 @ 60` as the normal camera default unless testing says otherwise
- keep control metadata latest-only
- do not move live MAVLink send back into the DeepStream callback
- do not make RTSP or preview a required dependency for control
- do not assume RTSP lag means gimbal lag
- do not rename ONNX / engine files unless infer config and scripts are updated too
- when changing launch behavior, update this README and the sub-docs in the same pass

Required source pieces for this profile:

- this `skyed` workspace
- vendored `ultralytics` package copy in `prototype_v2/ultralytics`
- vendored DeepStream / Jetson integration tree in `third_party/DeepStream-Yolo`
- IMX412 vendor driver package in `vendor/e-CAM121_CUONX/e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05.tar.gz`
- optional backup camera package: ArduCam `install_full.sh -m imx477`

Important dependency note:

- the profile tree alone is not enough to bring the field stack up
- the `skyed` workspace now carries its own `ultralytics` package copy for model export
- the `skyed` workspace also carries a vendored `DeepStream-Yolo` tree and IMX412 vendor package copy
- the Jetson camera driver package must be present for IMX412
- the DeepStream-Yolo tree must be present for the current launch and bridge path
- if you move this profile to another Jetson, verify the `skyed` workspace path and the vendor package paths before launching

If you need more detail for the operator path:

- MK15 / RTSP specifics:
  - `streaming/README.md`
- clean recording / extraction specifics:
  - `recordings/README.md`

## Next Work

The basic runtime architecture is already in a good state.

Next work should mainly be:

1. model quality improvements under real scenes
2. controlled comparisons across power modes
3. dataset growth from real field video
4. only then deeper control-loop redesigns, if measurements justify them
