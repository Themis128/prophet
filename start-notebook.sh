#!/bin/bash
set -e

# Ensure the script handles termination signals gracefully
trap "echo 'Stopping JupyterLab...'; exit" SIGTERM SIGINT

# Start JupyterLab
exec jupyter lab --no-browser --ip=0.0.0.0 --port=8888 --allow-root "$@"

