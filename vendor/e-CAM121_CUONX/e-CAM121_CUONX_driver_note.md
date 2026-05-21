# e-CAM121_CUONX IMX412 Driver Bring-Up Note

Date updated: 2026-05-01

Machine: Jetson Orin NX

Camera: e-con Systems `e-CAM121_CUONX` / Sony IMX412

Working OS target:

- JetPack `6.2.1`
- L4T `36.4.4`
- kernel `5.15.148-tegra`

## Hardware Setup First

This camera must be connected correctly before software can work.

Required hardware setup:

- Connect the e-con camera to `CAM1` on the Jetson Orin NX carrier.
- Use the correct FFC/FPC cable: `22 pin`, `0.5 mm pitch`, `Type A`.
- Make sure the cable orientation is correct on both the Jetson CAM1 side and the e-con adapter board side.
- Lock the connector latches fully.
- Make sure the e-con camera module is seated properly on the e-con adapter board.

Important lesson from this bring-up:

- The wrong FFC/FPC cable or wrong cable orientation made the camera fail at I2C detection.
- Flipping the wrong cable did not fix detection and can risk electrical damage.
- When the correct `22 pin 0.5 mm Type A` cable was used, the camera was detected immediately after reboot.

The first real hardware pass condition is:

```bash
sudo i2cdetect -y -r 9
```

Expected after correct hardware connection:

- `0x22` appears as `UU`
- `0x42` appears as `UU`

Meaning:

- `0x22` is the `tca6424` / `pca953x` GPIO expander on the e-con camera path.
- `0x42` is the `eimx412` sensor device.
- `UU` means a Linux driver is already bound to that I2C address.

## References Used

Vendor folder:

```bash
/home/saturnzzz/skyed/vendor/e-CAM121_CUONX
```

Main package used:

```bash
/home/saturnzzz/skyed/vendor/e-CAM121_CUONX/e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05.tar.gz
```

Extracted package folder:

```bash
/home/saturnzzz/skyed/vendor/e-CAM121_CUONX/e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05
```

Most important practical reference:

```bash
/home/saturnzzz/skyed/vendor/e-CAM121_CUONX/e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05/install_binaries.sh
```

This script shows exactly what the vendor installer copies into `/boot`, `/lib/modules`, `/etc`, `/usr/local/bin`, and `/var/nvidia/nvcam/settings`.

Useful vendor documents now live in:

- `e-CAM121_CUONX_L4T36.4.4_Documents_R05.zip`

Main files inside that zip:

- `Hardware/e-CAM121_CUONX_Getting_Started_Manual_Rev_1_5.pdf`
- `Software/e-CAM121_CUONX_Release_Package_Manifest_Rev_1_3.pdf`
- `Software/e-CAM121_CUONX_Developer_Guide_Rev_1_7.pdf`
- `Software/e-CAM121_CUONX_GStreamer_Usage_Guide_Rev_1_4.pdf`

Useful pages checked:

- Getting Started Manual page 17: software quick setup.
- Getting Started Manual page 18: install commands and first checks.
- Getting Started Manual page 23: Orin Nano/NX supports this camera on `CAM1` for 4-lane mode.
- Developer Guide page 26: expected checks are `dmesg | grep "Detected eimx412 sensor"` and `ls /dev/video*`.
- Developer Guide page 27: unloading camera drivers can crash, so avoid manual unload unless necessary.

The Developer Guide source-build section was not used as the main flow because the available guide is for older `L4T35.4.1`, while this Jetson is `L4T36.4.4`. The correct path for this machine is the `R05` binary installer for `L4T36.4.4 / JP6.2.1`.

## Why The Old Package Was Not Used

Original old package in the folder:

```bash
e-CAM121_CUONX_JETSON_ONX_ONANO_L4T35.4.1_04-SEP-2023_R03.tar.gz
```

That package targets:

- JetPack `5.1.2`
- L4T `35.4.1`

This Jetson runs:

- JetPack `6.2.1`
- L4T `36.4.4`

So the old `R03 / L4T35.4.1` package should not be installed on this machine.

## Correct Package

Correct package:

```bash
e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05.tar.gz
```

The nested release package is:

```bash
e-CAM121_CUONX_L4T36.4.4_JP6.2.1_JETSON-ONX-ONANO_R05.tar.gz
```

Integrity check:

```bash
cd /home/saturnzzz/skyed/vendor/e-CAM121_CUONX/e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05
md5sum -c release_integrity.md5
```

Expected:

```text
e-CAM121_CUONX_L4T36.4.4_JP6.2.1_JETSON-ONX-ONANO_R05.tar.gz: OK
```

## Clean Baseline Before Install

Before installing, the system should look like this:

```bash
cat /etc/nv_tegra_release
uname -r
grep -nE '^(DEFAULT|LABEL|[[:space:]]+OVERLAYS|[[:space:]]+FDT)' /boot/extlinux/extlinux.conf
cat /etc/modules
```

Expected baseline:

- `/etc/nv_tegra_release` shows `R36`, revision `4.4`.
- `uname -r` shows `5.15.148-tegra`.
- `/boot/extlinux/extlinux.conf` shows `DEFAULT primary`.
- `/etc/modules` does not contain `e_con_cam`.

Optional baseline absence checks:

```bash
ls -l /boot/tegra234-p3767-0000-p3768-0000-a0-4lane-imx412.dtbo
ls -l /lib/modules/$(uname -r)/updates/e-con_cam.ko
ls -l /usr/local/bin/eCAM_argus_camera
ls -l /var/nvidia/nvcam/settings/camera_overrides.isp
```

Before install, those can be missing.

## Install Flow

Run the vendor installer:

```bash
cd /home/saturnzzz/skyed/vendor/e-CAM121_CUONX
tar -xaf e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05.tar.gz
cd e-CAM121_CUONX_JETSON_ONX_ONANO_L4T36.4.4_07-NOV-2025_R05
sudo chmod +x ./install_binaries.sh
sudo -E ./install_binaries.sh
```

The installer should detect:

- platform: `jetson-onx`
- L4T: `L4T36.4.4`
- mode: `4lane`

The installer will reboot the Jetson at the end.

## What The Installer Changes

Kernel/camera modules:

```bash
/lib/modules/5.15.148-tegra/updates/e-con_cam.ko
/lib/modules/5.15.148-tegra/updates/drivers/media/platform/tegra/camera/tegra-camera.ko
/lib/modules/5.15.148-tegra/updates/drivers/platform/tegra/rtcpu/tegra-camera-rtcpu.ko
```

Boot overlay:

```bash
/boot/tegra234-p3767-0000-p3768-0000-a0-4lane-imx412.dtbo
/boot/extlinux/extlinux.conf
```

Expected boot entry after install:

```text
DEFAULT JetsonIO
OVERLAYS /boot/tegra234-p3767-0000-p3768-0000-a0-4lane-imx412.dtbo
```

Camera/Argus support files:

```bash
/var/nvidia/nvcam/settings/camera_overrides.isp
/etc/systemd/system/nvargus-daemon.service
/etc/modules
/usr/local/bin/eCAM_argus_camera
/usr/local/bin/v4l2-compliance
```

Expected `/etc/modules` camera section:

```text
# modules for camera HAL
e_con_cam
nvhost_vi
```

## Post-Reboot Checks

After reboot, check the overlay and loaded modules:

```bash
grep -nE '^(DEFAULT|LABEL|[[:space:]]+FDT|[[:space:]]+OVERLAYS)' /boot/extlinux/extlinux.conf
dtc -I fs -O dts /proc/device-tree 2>/dev/null | rg -i 'eimx412|tca6424|tegra-camera-platform|devname'
lsmod | rg 'e_con|tegra_camera|camera|video'
```

Expected:

- `DEFAULT JetsonIO`
- live device tree contains `eimx412_c@42`
- live device tree contains `tca6424@22`
- `lsmod` shows `e_con_cam`

Check kernel detection:

```bash
journalctl -k -b 0 --no-pager | rg -i 'eimx412|imx412|e_con|pca953|tca6424|camera'
```

Expected successful lines:

```text
e-con_cam 9-0042: Camera Device detected
e-con_cam 9-0042: Detected eimx412 sensor
```

Check device nodes:

```bash
ls -l /dev/video* /dev/v4l-subdev* /dev/media*
```

Expected:

```text
/dev/video0
/dev/v4l-subdev0
/dev/v4l-subdev1
/dev/media0
```

Check I2C:

```bash
sudo i2cdetect -y -r 9
```

Expected important entries:

```text
0x22 = UU
0x42 = UU
```

Check driver binding:

```bash
for d in /sys/bus/i2c/devices/9-0022 /sys/bus/i2c/devices/9-0042; do
  echo "### $d"
  cat "$d/name" 2>/dev/null
  readlink "$d/driver" 2>/dev/null || echo "no driver bound"
done
```

Expected:

```text
9-0022 -> pca953x
9-0042 -> e-con_cam
```

Check V4L2/media topology:

```bash
v4l2-ctl --list-devices
v4l2-ctl -d /dev/video0 --all
media-ctl -p -d /dev/media0
```

Expected:

- `vi-output, e-con_cam 9-0042`
- `/dev/video0`
- media graph link from `e-con_cam 9-0042` to `nvcsi` to `vi-output`

## Argus / GStreamer Tests

Restart Argus:

```bash
sudo systemctl restart nvargus-daemon
```

Short fakesink test:

```bash
gst-launch-1.0 -e nvarguscamerasrc sensor-id=0 num-buffers=10 ! fakesink
```

Expected success:

```text
GST_ARGUS: Available Sensor modes
GST_ARGUS: Done Success
```

Do not expect `sensor-id=1` to work unless a second camera is connected. With one camera, Argus uses index `0`.

Preview stream:

```bash
DISPLAY="${DISPLAY:-:0}" gst-launch-1.0 -e nvarguscamerasrc sensor-id=0 ! 'video/x-raw(memory:NVMM),width=2028,height=1112,framerate=60/1' ! nvvidconv ! 'video/x-raw,width=1280,height=720,format=I420' ! xvimagesink sync=false
```

Expected:

- a live preview window appears
- if the window is closed, GStreamer may print `Output window was closed`
- clean shutdown still shows `GST_ARGUS: Done Success`

## Working Status Observed

After replacing the wrong cable with the correct `22 pin 0.5 mm Type A` FFC/FPC cable and rebooting:

Kernel detection succeeded:

```text
e-con_cam 9-0042: Camera Device detected
e-con_cam 9-0042: Detected eimx412 sensor
```

Device nodes appeared:

```text
/dev/video0
/dev/v4l-subdev0
/dev/v4l-subdev1
/dev/media0
```

I2C looked correct:

```text
0x22 = UU
0x42 = UU
```

Argus/GStreamer fakesink test succeeded:

```text
GST_ARGUS: Available Sensor modes
GST_ARGUS: Done Success
```

Preview stream also worked on `sensor-id=0`.

## Failure Pattern From The Wrong Cable

When the cable/hardware path was wrong, the software install still looked mostly correct, but the camera did not work.

Failure symptoms:

```text
pca953x 9-0022: failed writing register
pca953x: probe of 9-0022 failed with error -121
```

I2C scan showed all addresses as `--`:

```bash
sudo i2cdetect -y -r 9
```

No video nodes appeared:

```text
no /dev/video0
no /dev/v4l-subdev*
only /dev/media0
```

GStreamer failed:

```text
No cameras available
```

Meaning:

- The driver package can be installed correctly and still fail if the cable path is wrong.
- The decisive test is whether bus `9` sees `0x22` and `0x42`.

## Quick Recovery / Undo Notes

If the install needs to be undone, return to stock boot and remove e-con autoload:

```bash
sudo cp /boot/extlinux/extlinux.conf.jetson-io-backup /boot/extlinux/extlinux.conf
sudo sed -i '/^e_con_cam$/d' /etc/modules
```

Then remove e-con-specific files if needed:

```bash
sudo rm -f /boot/tegra234-p3767-0000-p3768-0000-a0-4lane-imx412.dtbo
sudo rm -f /lib/modules/$(uname -r)/updates/e-con_cam.ko
sudo rm -f /usr/local/bin/eCAM_argus_camera
sudo rm -f /var/nvidia/nvcam/settings/camera_overrides.isp
sudo depmod -a
```

Avoid manually unloading `e_con_cam` while the system is running unless necessary. The vendor Developer Guide notes that unloading camera drivers can cause a kernel crash. Reboot is the cleaner boundary.

## Bottom Line

The correct driver package is `R05` for `L4T36.4.4 / JP6.2.1`.

The camera works when:

- the `R05` package is installed
- the JetsonIO IMX412 overlay is active
- the camera is connected to `CAM1`
- the correct `22 pin 0.5 mm Type A` FFC/FPC cable is used
- I2C bus `9` shows `0x22` and `0x42` as `UU`

The most reliable final test is:

```bash
gst-launch-1.0 -e nvarguscamerasrc sensor-id=0 num-buffers=10 ! fakesink
```

Expected final result:

```text
GST_ARGUS: Done Success
```
