#!/usr/bin/env bash
set -euo pipefail

set +u
source /opt/ros/humble/setup.bash
set -u

# Do not source the workspace overlay here. The sim-nav entrypoint rebuilds the
# workspace on startup, and a stale overlay can reintroduce old environment
# values before the rebuild has a chance to run.
export RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_fastrtps_cpp}"

if [[ $# -eq 0 ]]; then
  exec /bin/bash
fi

exec "$@"
