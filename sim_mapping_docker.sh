#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

declare -a PIDS=()

maybe_build_workspace

start_cmd "sim_world" "ros2 launch pb_rm_simulation rm_simulation.launch.py world:=RMUC use_sim_time:=true"
start_cmd "imu_filter" "ros2 launch imu_complementary_filter complementary_filter.launch.py use_sim_time:=true"
start_cmd "fast_lio" "ros2 launch fast_lio mapping_mid360.launch.py use_sim_time:=true"
start_cmd "ground_seg" "ros2 launch linefit_ground_segmentation_ros segmentation.launch.py use_sim_time:=true"
start_cmd "pcl2scan" "ros2 launch pointcloud_to_laserscan pointcloud_to_laserscan_launch.py use_sim_time:=true"
start_cmd "online_async" "ros2 launch rm_nav_bringup online_async_launch.py use_sim_time:=true"
start_cmd "bringup_no_amcl" "ros2 launch rm_nav_bringup bringup_no_amcl_launch.py use_sim_time:=true use_rviz:=false"
start_cmd "rviz" "ros2 launch rm_nav_bringup rviz_launch.py"

trap 'kill "${PIDS[@]}" 2>/dev/null || true' EXIT INT TERM
wait_for_children
