# realsense_yolo_hailo
Camera sensor for wheelchair group

This project runs YOLOv8n instance segmentation using a Raspberry Pi 5 and an Intel RealSense D435i/D455 camera. It achieves high-speed inference by leveraging the Hailo-8 AI accelerator (NPU).

Please note that this repository only provides a Dockerfile. Additional configuration on the host machine is required to run the project.

# Host setup
### Docker Engine install
See: https://docs.docker.com/engine/install/debian/#install-using-the-repository

Next Step: https://docs.docker.com/engine/install/linux-postinstall/

### Hailo install
See: https://www.raspberrypi.com/documentation/accessories/ai-kit.html
```
sudo apt update && sudo apt full-upgrade
sudo rpi-eeprom-update
sudo apt install hailo-all -y
```
Reboot:
```
sudo reboot
```
Check Hailo software correctly installed:
```
hailortcli fw-control identify
```
You can see this (Firmware may be different depending on the case):
```
Executing on device: 0001:01:00.0
Identifying board
Control Protocol Version: 2
Firmware Version: 4.20.0 (release,app,extended context switch buffer)
Logger Version: 0
Board Name: Hailo-8
Device Architecture: HAILO8
Serial Number: <N/A>
Part Number: <N/A>
Product Name: <N/A>
```

### USB rules configuration for realsense device
```
git clone https://github.com/IntelRealSense/librealsense.git
cd ~/librealsense
sudo cp config/99-realsense-libusb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```
Reboot:
```
sudo reboot
```

### Build container image
In your folder existed Dockerfile, execute:
```
docker build -t realsense_yolo_hailo .
docker run -it -d --net=host --privileged --device=/dev/hailo0:/dev/hailo0 --device=/dev/bus/usb --device-cgroup-rule='c 189:* rmw' -v /tmp/.X11-unix:/tmp/.X11-unix -v /lib/firmware:/lib/firmware -v /lib/udev/rules.d:/lib/udev/rules.d -v /lib/modules:/lib/modules -v /dev:/dev realsense_yolo_hailo
```

# Usage
* This command is valid into the container.
* Before executing inference, make sure `ROS_DOMAIN_ID` is correct in .bashrc.

`infer`: Execute inference
