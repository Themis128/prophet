#!/bin/bash
set -e

# Start Jupyter Lab
exec jupyter lab --no-browser --ip=0.0.0.0 --port=8888 --allow-root "$@"
