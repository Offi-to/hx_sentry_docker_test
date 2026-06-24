#!/usr/bin/env bash
set -euo pipefail

DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "${DOCKER_DIR}/.." && pwd)}"
ROS_SETUP="${ROS_SETUP:-/opt/ros/humble/setup.bash}"
BUILD_TYPE="${BUILD_TYPE:-RelWithDebInfo}"

source_ros() {
  # shellcheck disable=SC1090
  set +u
  source "${ROS_SETUP}"
  if [[ -f "${WORKSPACE_ROOT}/install/setup.bash" ]]; then
    # shellcheck disable=SC1090
    source "${WORKSPACE_ROOT}/install/setup.bash"
  fi

  # Keep the middleware pinned to the one we actually install in the image.
  export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"
  set -u
}

build_workspace() {
  cd "${WORKSPACE_ROOT}"
  # The workspace is mounted from the host and can retain stale CMake caches or
  # overlay exports from earlier failed builds. Clean the generated trees before
  # rebuilding so the startup path is deterministic.
  rm -rf build install log
  colcon build --symlink-install --cmake-args "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
}

maybe_build_workspace() {
  local missing_plugins=0

  if [[ ! -f "${WORKSPACE_ROOT}/install/pb_nav2_plugins/share/colcon-core/packages/pb_nav2_plugins" ]]; then
    missing_plugins=1
  fi

  if [[ ! -f "${WORKSPACE_ROOT}/install/pb_omni_pid_pursuit_controller/share/colcon-core/packages/pb_omni_pid_pursuit_controller" ]]; then
    missing_plugins=1
  fi

  if [[ "${AUTO_BUILD:-0}" == "1" || ! -f "${WORKSPACE_ROOT}/install/setup.bash" || "${missing_plugins}" == "1" ]]; then
    echo "[docker] building workspace (${BUILD_TYPE})"
    build_workspace
  fi
}

start_cmd() {
  local name="$1"
  shift
  local cmd="$*"

  (
    set -euo pipefail
    source_ros
    cd "${WORKSPACE_ROOT}"
    eval "${cmd}"
  ) > >(sed -u "s/^/[${name}] /") 2> >(sed -u "s/^/[${name}] /" >&2) &

  PIDS+=("$!")
}

wait_for_children() {
  if [[ "${#PIDS[@]}" -eq 0 ]]; then
    echo "[docker] no child processes were started"
    return 1
  fi

  local exit_code=0
  for pid in "${PIDS[@]}"; do
    if ! wait "${pid}"; then
      exit_code=1
    fi
  done
  return "${exit_code}"
}
