FROM ros:humble-ros-base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG ROS_DISTRO=humble
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV QT_X11_NO_MITSHM=1
ENV QT_OPENGL=software
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV ROS_DOMAIN_ID=0
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ENV ROS_DISTRO=${ROS_DISTRO}
ENV ROS_SETUP=/opt/ros/${ROS_DISTRO}/setup.bash

WORKDIR /workspaces/hx_sentry_2025_docker

# -----------------------------------------------------------------------------
# Base system and locale
# -----------------------------------------------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends --fix-missing -o Acquire::Retries=5 \
    ca-certificates \
    curl \
    gnupg2 \
    lsb-release \
    locales \
    sudo \
    software-properties-common \
 && locale-gen en_US en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Development tools, GUI support and ROS packages
# -----------------------------------------------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends --fix-missing -o Acquire::Retries=5 \
    build-essential \
    cmake \
    dbus-x11 \
    gdb \
    git \
    gazebo \
    libeigen3-dev \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libglu1-mesa \
    libgazebo-dev \
    libomp-dev \
    libpcl-dev \
    libx11-6 \
    libxext6 \
    libxi6 \
    libxkbcommon-x11-0 \
    libxcb1 \
    libxcb-xinerama0 \
    libxrender1 \
    less \
    mesa-utils \
    nano \
    net-tools \
    iproute2 \
    pkg-config \
    python3-colcon-common-extensions \
    python3-pip \
    python3-rosdep \
    python3-vcstool \
    tmux \
    unzip \
    vim \
    x11-apps \
    xauth \
    ros-${ROS_DISTRO}-desktop \
    ros-${ROS_DISTRO}-gazebo-ros-pkgs \
    ros-${ROS_DISTRO}-navigation2 \
    ros-${ROS_DISTRO}-nav2-bringup \
    ros-${ROS_DISTRO}-pcl-conversions \
    ros-${ROS_DISTRO}-pcl-ros \
    ros-${ROS_DISTRO}-pointcloud-to-laserscan \
    ros-${ROS_DISTRO}-rviz2 \
    ros-${ROS_DISTRO}-slam-toolbox \
    ros-${ROS_DISTRO}-teleop-twist-keyboard \
    ros-${ROS_DISTRO}-tf-transformations \
    ros-${ROS_DISTRO}-xacro \
 && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# rosdep
# -----------------------------------------------------------------------------
RUN rosdep init 2>/dev/null || true \
 && rosdep update || true

# -----------------------------------------------------------------------------
# Livox SDK2 is required by livox_ros_driver2 in this workspace.
# Install it into /usr/local so find_library() can resolve the shared library.
# -----------------------------------------------------------------------------
COPY src/Livox-SDK2 /tmp/Livox-SDK2
RUN rm -rf /tmp/Livox-SDK2/build /tmp/Livox-SDK2/install /tmp/Livox-SDK2/log \
 && cmake -S /tmp/Livox-SDK2 -B /tmp/Livox-SDK2/build \
 && cmake --build /tmp/Livox-SDK2/build -j"$(nproc)" \
 && cmake --install /tmp/Livox-SDK2/build \
 && ldconfig \
 && rm -rf /tmp/Livox-SDK2

# -----------------------------------------------------------------------------
# Non-root user
# -----------------------------------------------------------------------------
RUN groupadd --gid ${USER_GID} ${USERNAME} \
 && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME}

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ${USERNAME}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
