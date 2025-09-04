# realsense_yolo_hailo
Camera sensor for wheelchair group

This project runs YOLOv8n instance segmentation using a Raspberry Pi 5 and an Intel RealSense D435i/D455 camera. It achieves high-speed inference by leveraging the Hailo-8 AI accelerator (NPU).

Please note that this repository only provides a Dockerfile. Additional configuration on the host machine is required to run the project.

# Host setup
### Hailo install
```
sudo apt get update
sudo apt install hailo-all -y
mkdir realsense && cd realsense
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

# USB bind for D455 (No need for D435/D435i)
```
echo 'options usbhid quirks=0x8086:0x0b5c:0x0004' | \
  sudo tee /etc/modprobe.d/realsense-hid.conf
sudo depmod -a
sudo sed -i 's/$/ usbhid.quirks=0x8086:0x0b5c:0x0004/' \
  /boot/firmware/cmdline.txt
sudo update-initramfs -u -k $(uname -r)
```
Reboot:
```
sudo reboot
```

# Build container image
In your folder existing Dockerfile, execute:
```
docker build -t realsense_yolo_hailo .
docker run -it -d --net=host --privileged --device=/dev/hailo0:/dev/hailo0 --device=/dev/bus/usb --device-cgroup-rule='c 189:* rmw' -v /tmp/.X11-unix:/tmp/.X11-unix -v /lib/firmware:/lib/firmware -v /lib/udev/rules.d:/lib/udev/rules.d -v /lib/modules:/lib/modules -v /dev:/dev realsense_yolo_hailo
```

# Usage
* This command is valid into the container.
* Before executing inference, make sure `ROS_DOMAIN_ID` is correct in .bashrc.

`infer`: Execute inference
