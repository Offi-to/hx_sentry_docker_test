#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

declare -a PIDS=()

maybe_build_workspace

start_cmd "livox" "ros2 launch livox_ros_driver2 msg_MID360_launch.py"
start_cmd "real_sim" "ros2 launch pb_rm_simulation rm_real.launch.py use_sim_time:=false"
start_cmd "imu_filter" "ros2 launch imu_complementary_filter complementary_filter.launch.py use_sim_time:=false"
start_cmd "point_lio" "ros2 launch point_lio point_lio.launch.py use_sim_time:=false"
start_cmd "icp" "ros2 launch icp_registration icp.launch.py use_sim_time:=false"
start_cmd "cloud_process" "ros2 launch cloud_process cloud_process.launch.py use_sim_time:=false"
start_cmd "terrain_analysis" "ros2 launch terrain_analysis terrain_analysis.launch use_sim_time:=false"
start_cmd "merge_cloud" "ros2 launch merge_cloud merge_cloud_code.launch.py use_sim_time:=false"
start_cmd "pcl2scan" "ros2 launch pointcloud_to_laserscan pointcloud_to_laserscan_launch.py use_sim_time:=false"
start_cmd "bringup" "ros2 launch rm_nav_bringup bringup_launch.py use_sim_time:=false"
start_cmd "serial" "ros2 launch rm_serial_driver serial_driver.launch.py use_sim_time:=false"
start_cmd "decision" "ros2 run hx_decsion hx_decsion"

trap 'kill "${PIDS[@]}" 2>/dev/null || true' EXIT INT TERM
wait_for_children
