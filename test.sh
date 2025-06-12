#!/bin/bash

# Variables
PLAYBOOK_FILE="update_os_passwords.yml"  # The playbook you want to test
INVENTORY_FILE="inventory.ini"
OUTPUT_FILE="ansible_result.json"
API_ENDPOINT="https://example.com/api/ansible-report"  # Replace with your actual endpoint

# Run Ansible playbook and capture output in JSON
ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE" -e "new_password=Test1234!" \
  --tree ./ansible_output/ > "$OUTPUT_FILE"

# Check if the playbook ran successfully
if [ $? -eq 0 ]; then
  echo "Playbook executed successfully. Posting result to API..."
else
  echo "Playbook failed. Posting result to API..."
fi

# Post result to API
if [ -f "$OUTPUT_FILE" ]; then
  curl -X POST "$API_ENDPOINT" \
    -H "Content-Type: application/json" \
    --data-binary "@${OUTPUT_FILE}"
else
  echo "Output file not found. Cannot post result."
  exit 1
fi
