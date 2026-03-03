# Simple DeGirum PySDK + HailoRT Dockerfile
FROM ubuntu:22.04

ENV TZ=Asia/Tokyo
ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

ARG HAILORT_DEB=hailort_4.20.0_arm64.deb
COPY src/${HAILORT_DEB} /tmp/hailort.deb

# Base software install
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    git \
    gnupg \
    nano \
    vim \
    openssh-server \
    sudo \
    tzdata \
    udev \
    wget \
    python3 python3-pip python3-dev python3-venv libusb-1.0-0 ca-certificates \
    libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev \
    cmake pkg-config libssl-dev libusb-1.0-0-dev \
    software-properties-common && \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    add-apt-repository universe && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" > /etc/apt/sources.list.d/ros2.list && \
    apt-get update && \
    apt install -y ros-humble-desktop ros-dev-tools && \
    apt install -y ros-humble-diagnostic-updater && \
    rm -rf /var/lib/apt/lists/*

ENV VIRTUAL_ENV=/root/.venv
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

RUN python3 -m venv ${VIRTUAL_ENV}

RUN pip install --upgrade pip && \
    pip install \
        catkin_pkg \
        colcon-common-extensions \
        setuptools && \
    pip uninstall -y empy && \
    pip install empy==3.3.4 && \
    pip install lark-parser

RUN pip install \
        "numpy<2" \
        "opencv-python<4.9" \
        "pillow>=9.2,<11.0" \
        matplotlib

RUN pip install degirum==0.18.0

RUN cd && \
    # Install Hailo model
    git clone https://github.com/g2481008/hailo_model.git && \
    wget https://hailo-model-zoo.s3.eu-west-2.amazonaws.com/ModelZoo/Compiled/v2.16.0/hailo8/yolov8n_seg.hef \
        -O hailo_model/model_zoo/yolov8n_seg/yolov8n_seg.hef && \
    # Install librealsense
    # v2.55.1
    git clone --branch v2.55.1 --depth 1 https://github.com/IntelRealSense/librealsense && \
    cd librealsense && \
    mkdir build && cd build && \
    cmake ../ \
        -DCMAKE_BUILD_TYPE=Release \
        -DFORCE_RSUSB_BACKEND=ON \
        -DBUILD_PYTHON_BINDINGS=ON \
        -DPYTHON_EXECUTABLE=${VIRTUAL_ENV}/bin/python3 \
        -DPYTHON_INSTALL_DIR=${VIRTUAL_ENV}/lib/python3.10/site-packages && \
    make -j$(nproc) && \
    make install && \
    # Clone ROS2 pkgs
    mkdir -p /root/ros2_ws/src && \
    cd /root/ros2_ws/src && \
    # 4.54.1
    git clone --branch 4.54.1 --depth 1 https://github.com/IntelRealSense/realsense-ros.git && \
    git clone -b humble https://github.com/ros-perception/vision_opencv.git && \
    git clone -b humble-devel https://github.com/ros-visualization/rqt_image_view.git && \
    git clone https://github.com/g2481008/hailo_yolo.git && \
    git clone https://github.com/g2481008/yolo_msgs.git && \
    # librealsense は cmake ビルド版を使うため realsense-ros の依存パッケージを除去
    cd ~/ros2_ws/src/ && rm -rf librealsense2* && \
    rm -rf ~/ros2_ws/build/librealsense2 && \
    rm -rf ~/ros2_ws/install/librealsense2 && \
    source /opt/ros/humble/setup.bash && \
    apt-get update && \
    cd ~/ros2_ws && \
    rosdep init && rosdep update && rosdep fix-permissions && rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y && \
    rm -rf /var/lib/apt/lists/*

# Install Hailo module
RUN ln -s /bin/true /usr/local/bin/systemctl && \
    apt-get update && \
    dpkg --unpack /tmp/hailort.deb && \
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a || true && \
    rm -f /tmp/hailort.deb && \
    rm -rf /var/lib/apt/lists/*

RUN cd ~/ros2_ws && \
    source /opt/ros/humble/setup.bash && \
    colcon build --symlink-install && \
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && \
    echo "source ~/ros2_ws/install/setup.bash" >> ~/.bashrc && \
    echo "export ROS_DOMAIN_ID=11" >> ~/.bashrc

ENV PYTHONPATH="/root/librealsense/build/Release:${VIRTUAL_ENV}/lib/python3.10/site-packages"
ENV LD_LIBRARY_PATH="/usr/local/lib"

# Create Alias
COPY src/aliases.txt /root/.bash_aliases
