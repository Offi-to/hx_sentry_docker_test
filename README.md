# Docker 开发环境

这是给 `ros2 humble` 导航仓库用的开发者调试镜像和容器内启动脚本。

## 构建镜像

```bash
docker build -t hx_sentry_nav -f docker/Dockerfile .
```

镜像会先把仓库里的 `src/Livox-SDK2` 安装到 `/usr/local`，这样 `livox_ros_driver2` 在构建时不会卡在 `liblivox_lidar_sdk_shared.so`。

## Compose 启动

这个仓库在 `docker/docker-compose.yml` 里放了场景化的 compose，可以直接按场景启动：

```bash
docker compose --profile dev up dev-shell
docker compose --profile real-mapping up real-mapping
docker compose --profile real-nav up real-nav
docker compose --profile sim-mapping up sim-mapping
docker compose --profile sim-nav up sim-nav
```

如果你想强制每次都重新编译：

```bash
AUTO_BUILD=1 docker compose --profile real-nav up real-nav
```

默认 compose 会打开 `QT_OPENGL=software` 和 `LIBGL_ALWAYS_SOFTWARE=1`，这样在 Windows + XLaunch 下跑 RViz/Gazebo 更稳。如果你本机 GPU / X Server 很稳定，可以在 `.env` 里覆盖掉这两个值。

## 运行容器

如果需要 RViz 或其它 GUI，记得把 X11 转发挂进去。下面是一个常用写法：

```bash
docker run -it --rm \
  --net=host \
  --ipc=host \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -v ${PWD}:/workspaces/hx_sentry_2025_docker \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  hx_sentry_nav
```

## 容器里启动

```bash
cd /workspaces/hx_sentry_2025_docker
bash docker/real_mapping_docker.sh
```

对应关系如下：

- `docker/real_mapping_docker.sh`
- `docker/real_nav_docker.sh`
- `docker/sim_mapping_docker.sh`
- `docker/sim_nav_docker.sh`

其中 `sim_mapping_docker.sh` 和 `sim_nav_docker.sh` 会把 `bringup` 里的 RViz 关掉，然后单独启动一份 `rm_nav_bringup/rviz_launch.py`，避免重复弹窗。

如果容器里缺少自定义插件包，`docker/common.sh` 会自动重新编译工作区，确保 `pb_nav2_plugins` 和 `pb_omni_pid_pursuit_controller` 被装进去。

## 调试建议

- 默认只在 `install/setup.bash` 不存在时自动编译
- 如果你想强制每次都编译，运行前加 `AUTO_BUILD=1`
- 如果你想切换编译类型，运行前加 `BUILD_TYPE=Debug` 或 `BUILD_TYPE=RelWithDebInfo`

例如：

```bash
AUTO_BUILD=1 BUILD_TYPE=Debug bash docker/real_nav_docker.sh
```
# hx_sentry_docker_test

开源源码，太原理工 https://github.com/yuzhuohao111/hx_Sentry_2025
