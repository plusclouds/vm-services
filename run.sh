#!/bin/bash

# Variables
INVENTORY_FILE="inventory.ini"
PLAYBOOK_FILE="run.yml"
OUTPUT_FILE="ansible_output.json"
API_ENDPOINT="https://example.com/api/report"  # Replace with your actual endpoint

# Run the Ansible playbook and capture output in JSON format
ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE" -e reboot_after_update=true \
  --tree ansible_output > "$OUTPUT_FILE"

# Post the output to the API
if [ -f "$OUTPUT_FILE" ]; then
  curl -X POST "$API_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "@${OUTPUT_FILE}"
else
  echo "Ansible output file not found."
  exit 1
fi
