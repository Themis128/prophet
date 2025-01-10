#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Step 1: Upgrade Jupyter Notebook and JupyterLab
echo "Upgrading Notebook and JupyterLab to the latest version..."
pip install --upgrade notebook jupyterlab

# Step 2: Verify the installation
echo "Verifying Notebook 7 installation..."
jupyter_version=$(jupyter --version)
echo "Installed Jupyter versions:"
echo "$jupyter_version"

# Step 3: Update Jupyter extensions
echo "Updating Jupyter Lab extensions..."
jupyter labextension update --all || echo "No extensions to update or extensions are incompatible."

# Step 4: Clean up unused or outdated dependencies
echo "Checking and cleaning up unused dependencies..."
pip check || true
pip uninstall -y notebook jupyter_client || true
pip install --upgrade jupyter_client

# Step 5: Generate and modify Jupyter server configuration
echo "Generating Jupyter server configuration if not already present..."
jupyter server --generate-config

echo "Updating Jupyter configuration for Notebook 7..."
CONFIG_PATH=~/.jupyter/jupyter_server_config.py

if [ -f "$CONFIG_PATH" ]; then
    # Add configuration to enable the new layout
    if ! grep -q "c.ServerApp.use_new_layout = True" "$CONFIG_PATH"; then
        echo "c.ServerApp.use_new_layout = True" >> "$CONFIG_PATH"
        echo "Configuration updated to enable Notebook 7 layout."
    else
        echo "Notebook 7 layout is already enabled."
    fi
else
    echo "Configuration file not found. Something went wrong!"
    exit 1
fi

# Step 6: Test Notebook 7
echo "Starting Jupyter Notebook to test Notebook 7..."
jupyter notebook &

# Step 7: Provide access instructions
echo "---------------------------------------------------------"
echo "Notebook 7 migration completed successfully!"
echo "Access Jupyter Notebook at: http://localhost:8888/lab"
echo "---------------------------------------------------------"

