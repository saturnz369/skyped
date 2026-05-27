# Recording Workflow

This file is the recording-only operator note for:

- `/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target`

Portable path rule:

- the launch scripts themselves resolve paths from the repo checkout and do not require this exact home directory
- the command examples below use `/home/saturnzzz/skyed` as the reference clone path on this Jetson
- on another Jetson, either clone to `~/skyed` as the standard path, or replace that prefix with the local repo root before running the command

Use this README only when you intentionally want:

- the normal full MK15 + gimbal application launch with clean recording enabled
- run-bundled recording artifacts
- failure-frame extraction
- detector-miss fallback extraction

Important separation:

- the normal launch in the main README does **not** record
- the normal launch in the streaming README does **not** record
- this recording README is the place where the recording-enabled launch lives

## Recording-Enabled Full Application Launch

This is the same real MK15 + gimbal application as the normal stream/operator path, but with recording intentionally turned on.

It still uses one terminal for the main run.

Machine-local launch note:

- the launchers auto-load `~/skyped_host_runtime/env/jetson.env` when it exists
- use that file for `DISPLAY`, `SERIAL_DEVICE`, `PYTHON_BIN`, and optional `HOST_RUNTIME_RUNS_ROOT`

```bash
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/recordings/run_mk15_yolo_gimbal_rtsp_record.sh
```

Wrapper meaning:

- same defaults as the normal MK15 full-control launcher
- recording is forced on here with `RAW_RECORD_ENABLE=1`
- env overrides still work before launch, same as the normal wrapper

## Recording-Enabled Full Explicit Launch

Use this when you want every important recording/control setting visible in one place before launching the same recording wrapper:

```bash
cd /home/saturnzzz/skyed
export SHOW=1
export RTSP_ENABLE=1
export RTSP_PORT=8554
export RTSP_MOUNT='/stream'
export SENSOR_ID=0
export CAMERA_WIDTH=2028
export CAMERA_HEIGHT=1112
export CAMERA_FPS_N=60
export CAMERA_FPS_D=1
export MAX_FRAMES=0
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
export RAW_RECORD_ENABLE=1
export METADATA_MAX_AGE_MS=150
export MONITORING_ERRORS_FATAL=0
export PRINT_HEALTH=1
export HEALTH_PRINT_INTERVAL_SEC=1.0
export RUN_ARTIFACTS_ENABLE=1
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/recordings/run_mk15_yolo_gimbal_rtsp_record.sh
```

Preflight hold-angle note:

- this recording launch uses the same live gimbal-control path as the normal stream/operator launch
- `INITIAL_PITCH_DEG` and `INITIAL_YAW_DEG` let you start from a chosen hold angle before flight
- example:
  - `export INITIAL_PITCH_DEG=-12.0`
- `PITCH_LOCK=1` and `YAW_LOCK=1` are optional lock-mode flags; keep them at `0` unless you intentionally want that behavior
- `TARGET_MEMORY_ENABLE=1` enables Level 1 last-angle recovery during visual dropouts
- set `TARGET_MEMORY_ENABLE=0` only when you intentionally want old behavior for an A/B comparison

What this means:

- same real application as the normal full MK15 + gimbal launch
- local preview stays on in this explicit block because `SHOW=1`
- MK15 RTSP can still stay on
- control still uses the same latest-only metadata path
- the clean recording branch is enabled in parallel

## Default Recording Output

By default the launcher creates a run bundle here:

```text
RUNS_ROOT/YYYYMMDD-HHMMSS/
```

and refreshes:

```text
RUNS_ROOT/latest/
```

The clean raw recording is normally:

```text
RUNS_ROOT/YYYYMMDD-HHMMSS/recording_clean.mkv
```

with matching:

```text
RUNS_ROOT/YYYYMMDD-HHMMSS/config_used.yaml
RUNS_ROOT/YYYYMMDD-HHMMSS/detection_log.jsonl
RUNS_ROOT/YYYYMMDD-HHMMSS/health_log.jsonl
RUNS_ROOT/YYYYMMDD-HHMMSS/deepstream.log
RUNS_ROOT/YYYYMMDD-HHMMSS/performance_summary.txt
```

For comparison across runs, use `performance_summary.txt`. It is the aggregated run summary for FPS, latency, metadata age, dropped frames, and carried timestamps. The live `CAMERA: ... | YOLO: ... | CONTROL: ...` lines are just operator snapshots and should not be copied into the README as if they were run averages.

Stop the run with `Ctrl+C`.

## Extract Failure Frames After The Run

After stopping the test:

```bash
bash /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/tools/extract_latest_failure_frames.sh
```

The extractor creates:

```text
RUNS_ROOT/YYYYMMDD-HHMMSS/recording_clean_failure_frames/
RUNS_ROOT/YYYYMMDD-HHMMSS/recording_clean_failure_frames.zip
```

Use the `.zip` for labeling on the PC.

## Manual Fallback Extractor For A Specific Recording

If the live bridge-based extractor is not available for that run, use the detector-miss fallback on one recording at a time.

Recommended on Jetson: keep it on CPU.

```bash
source ~/skyped_host_runtime/env/jetson.env
cd /home/saturnzzz/skyed

"${PYTHON_BIN:-/home/saturnzzz/skyed/third_party/DeepStream-Yolo/.venv-yolo26-sys/bin/python}" \
/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/tools/extract_detector_miss_frames_from_video.py \
--video "${RUNS_ROOT:-/home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/runs}/latest/recording_clean.mkv" \
--weights /home/saturnzzz/skyed/prototype_v2/YOLO26n/profile_640_fp16_archery_target/model/best.pt \
--class-id 0 \
--conf 0.10 \
--imgsz 640 \
--min-miss-frames 6 \
--max-miss-frames 600 \
--frames-per-segment 4 \
--progress-every 300 \
--device cpu
```

This fallback creates:

```text
RUNS_ROOT/YYYYMMDD-HHMMSS/recording_clean_detector_miss_frames/
RUNS_ROOT/YYYYMMDD-HHMMSS/recording_clean_detector_miss_frames.zip
```

Keep:

```bash
--device cpu
```

unless you intentionally want to test the faster GPU replay path again.

## Old Loose-File Behavior

If you want the old non-bundled behavior:

```bash
export RUN_ARTIFACTS_ENABLE=0
```

## Terminal Count

For the real flight/test launch, use one terminal for the main command.

After the run is stopped, use the same terminal or a new terminal to run the extractor.

Do not run the extractor while the main tracking command is still recording.

For fallback extraction, run only one video at a time and wait for the first zip to finish before starting the second.
