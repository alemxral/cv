#!/bin/bash
# setup-monitoring-service.sh
# Run this script with sudo

SCRIPT_PATH="/usr/local/bin/monitoring.sh"
SERVICE_PATH="/etc/systemd/system/monitoring-banner.service"

echo "=== Setting up monitoring-banner service ==="

# Check if monitoring.sh exists in the current directory
if [ ! -f "./monitoring.sh" ]; then
  echo "Error: monitoring.sh not found in the current directory."
  exit 1
fi

# Move script to /usr/local/bin and make it executable
echo "Copying monitoring.sh to $SCRIPT_PATH..."
cp ./monitoring.sh "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Create the systemd service file
echo "Creating systemd service file at $SERVICE_PATH..."
cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Monitoring Banner Script
After=network.target

[Service]
Type=simple
ExecStart=$SCRIPT_PATH
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start the service
echo "Reloading systemd..."
systemctl daemon-reload
echo "Enabling monitoring-banner.service..."
systemctl enable monitoring-banner.service
echo "Starting monitoring-banner.service..."
systemctl start monitoring-banner.service

echo "=== Done! ==="
systemctl status monitoring-banner.service --no-pager
