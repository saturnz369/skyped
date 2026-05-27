# YOLO26s Streaming Note

Use this file for the real MK15 stream/operator path under:

- `/home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target`

Portable path rule:

- the launch scripts themselves resolve paths from the repo checkout and do not require this exact home directory
- the command examples below use `/home/saturnzzz/skyed` as the reference clone path on this Jetson
- on another Jetson, either clone to `~/skyed` as the standard path, or replace that prefix with the local repo root before running the command

## Normal One-Shot Stream Launch

```bash
bash /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/streaming/run_mk15_yolo_gimbal_rtsp.sh
```

Normal meaning:

- this is the real full application launch
- it does **not** record by default
- the current default is `RAW_RECORD_ENABLE=0`

## Full Explicit Real Application Launch

Use this when you want every important stream/control setting visible in one place:

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
export RAW_RECORD_ENABLE=0
export METADATA_MAX_AGE_MS=150
export MONITORING_ERRORS_FATAL=0
export PRINT_HEALTH=1
export HEALTH_PRINT_INTERVAL_SEC=1.0
export RUN_ARTIFACTS_ENABLE=1
bash /home/saturnzzz/skyed/prototype_v2/YOLO26s/profile_640_fp16_archery_target/streaming/run_mk15_yolo_gimbal_rtsp.sh
```

Use only one model tree at a time when comparing against YOLO26n.
