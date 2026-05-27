# YOLO26s Profile

This is the separate YOLO26s sibling profile for:

- `/home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target`

Portable path rule:

- runtime scripts resolve their own paths relative to the checked-out repo
- the README command blocks use `/home/saturnzzz/skyed` as the reference clone path on this Jetson
- on another Jetson, either clone to `~/skyed` as the standard path, or replace that prefix with the local repo root before running the command

Use this tree when you want to compare YOLO26s against the current YOLO26n profile on the same Jetson.

Rule:

- keep YOLO26n work inside `prototype_v2/YOLO26n/`
- keep YOLO26s work inside `prototype_v2/YOLO26s/`
- launch one model tree at a time
- do not run YOLO26n and YOLO26s together on the same camera / gimbal path

Run all commands from:

```bash
cd /home/saturnzzz/skyed
```

## Current Tree State

Current runtime files in this YOLO26s tree:

- `model/best.pt`
- `model/target_face_v1_native_640.onnx`
- `model/labels.txt`
- `model/model_b1_gpu0_fp16.engine`

Training archives:

- `training_weight/v1/best.pt`
- `training_weight/v1/best.onnx`

Important note:

- the first accepted YOLO26s checkpoint is now archived at `training_weight/v1/best.pt`
- the current YOLO26s engine was built successfully from this tree
- filenames like `target_face_v1_native_640.onnx` stay generic for compatibility
- the tree path is what separates YOLO26s from YOLO26n, not the filename text
- on this Jetson, shared host-runtime runs now drop under `/home/saturnzzz/skyped_host_runtime/runs/profile_640_fp16_archery_target/yolo26s/`
- run directories in that `yolo26s/` root use plain timestamp names, so `latest/` sorts the same way as `YOLO26n`

Use `performance_summary.txt` for run-to-run comparison. It is the run-level aggregate for FPS, latency, metadata age, dropped frames, and carried timestamps. The live `CAMERA: ... | YOLO: ... | CONTROL: ...` health line is for operator monitoring only; it is a snapshot, not the summary.

## 1. Rebuild The App

```bash
make -C /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target clean all
```

## 2. Promote `training_weight/v1` To Active Runtime Model

Use this when `training_weight/v1/best.pt` is the accepted YOLO26s weight for testing:

```bash
cp /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/training_weight/v1/best.pt /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/model/best.pt
bash /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/prepare_prototype_v2_model.sh
```

That step exports a fresh:

- `model/target_face_v1_native_640.onnx`

and removes old local engines so the next DeepStream run or manual `trtexec` build uses the promoted YOLO26s model.

Optional archive step after export:

```bash
cp /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/model/target_face_v1_native_640.onnx /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/training_weight/v1/best.onnx
```

## 3. Preview Only, No PX4, No Gimbal

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
bash /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/run_deepstream_yolo26_rtsp_target_control.sh
```

Short smoke-test version:

```bash
export SHOW=0
export RTSP_ENABLE=0
export ALLOW_MAX_FRAMES=1
export MAX_FRAMES=120
export SENSOR_ID=0
export CAMERA_WIDTH=2028
export CAMERA_HEIGHT=1112
export CAMERA_FPS_N=60
export CAMERA_FPS_D=1
export TARGET_CLASS_ID=0
export SELECTION='center'
bash /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/run_deepstream_yolo26_rtsp_target_control.sh
```

## 4. Real Full Control, Local Only

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
bash /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/run_deepstream_px4_siyi_bridge.sh
```

## 5. Real Full Control With MK15

Normal one-shot flight/test launcher:

```bash
bash /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/streaming/run_mk15_yolo_gimbal_rtsp.sh
```

Normal meaning:

- this does **not** record by default
- current default is `RAW_RECORD_ENABLE=0`

## 6. Real Full Control With Clean Dataset Recording

One-shot recording launcher:

```bash
bash /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/recordings/run_mk15_yolo_gimbal_rtsp_record.sh
```

That wrapper keeps the normal full-control defaults, but forces `RAW_RECORD_ENABLE=1`.

## 7. Serious Final Engine Build

This tree is still `640x640` and `FP16`, same as the current YOLO26n runtime format:

```bash
/usr/src/tensorrt/bin/trtexec --onnx=/home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/model/target_face_v1_native_640.onnx --saveEngine=/home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/model/model_b1_gpu0_fp16.engine --fp16 --memPoolSize=workspace:1024 --builderOptimizationLevel=5 --skipInference
```

If you want to force a clean rebuild first:

```bash
rm -f /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/model/model_b1_gpu0_fp16.engine
```

## 8. Compare Workflow

1. Keep the current YOLO26n profile as-is under `prototype_v2/YOLO26n/`.
2. Promote and export the YOLO26s weight in this tree.
3. Build the YOLO26s engine in this tree.
4. Launch YOLO26n, test, stop it.
5. Launch YOLO26s, test, stop it.
6. Compare run artifacts, recordings, FPS, latency, and field behavior.
