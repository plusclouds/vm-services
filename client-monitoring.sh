#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   zbx-agent-bootstrap.sh --server <ZABBIX_SERVER_IP_or_DNS> [--hostname <NAME>] [--metadata <TAG>]
#
# Notes:
# - Auto-registration uses HostMetadata (default: "autoreg") to match your Action.
# - Hostname defaults to a persistent UUID stored at /etc/zabbix/vm_uuid.
# - No inbound port is needed; this is active mode only.

ZBX_SERVER=""; HOSTNAME_ARG=""; METADATA="autoreg"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server)   ZBX_SERVER="$2"; shift 2;;
    --hostname) HOSTNAME_ARG="$2"; shift 2;;
    --metadata) METADATA="$2";   shift 2;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

[[ -z "$ZBX_SERVER" ]] && { echo "Usage: $0 --server <ZABBIX_SERVER_IP_or_DNS> [--hostname <NAME>] [--metadata <TAG>]"; exit 1; }

ZBX_DIR="/etc/zabbix"
UUID_FILE="$ZBX_DIR/vm_uuid"
LOG_FILE="/var/log/zabbix/zabbix_agentd.log"
PID_DIR="/run/zabbix"; PID_FILE="$PID_DIR/zabbix_agentd.pid"

mkdir -p "$ZBX_DIR" /var/log/zabbix "$PID_DIR"
chown zabbix:zabbix "$PID_DIR" || true

# Stable hostname: provided name or persistent UUID
if [[ -n "${HOSTNAME_ARG}" ]]; then
  HOSTNAME="${HOSTNAME_ARG}"
else
  if [[ ! -f "$UUID_FILE" ]]; then
    uuidgen > "$UUID_FILE"
  fi
  HOSTNAME="$(cat "$UUID_FILE")"
fi

# Install agent for Ubuntu 22.04/24.04
if ! command -v zabbix_agentd >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y --no-install-recommends lsb-release wget ca-certificates
  CODENAME=$(lsb_release -cs)
  case "$CODENAME" in
    noble) REL="zabbix-release_6.4-1+ubuntu24.04_all.deb" ;;
    jammy) REL="zabbix-release_6.4-1+ubuntu22.04_all.deb" ;;
    *) echo "Unsupported Ubuntu codename: $CODENAME"; exit 1 ;;
  esac
  wget -q "https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/${REL}"
  dpkg -i "${REL}"
  apt-get update -y
  apt-get install -y zabbix-agent
fi

# Active agent config (no inbound needed)
cat >"$ZBX_DIR/zabbix_agentd.conf" <<EOF
LogFile=$LOG_FILE
PidFile=$PID_FILE
Server=$ZBX_SERVER
ServerActive=$ZBX_SERVER
Hostname=$HOSTNAME
HostMetadata=$METADATA
Timeout=10
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF

systemctl daemon-reload
systemctl enable --now zabbix-agent
systemctl restart zabbix-agent

echo "[OK] Zabbix agent started"
echo "     Server:     $ZBX_SERVER"
echo "     Hostname:   $HOSTNAME"
echo "     Metadata:   $METADATA"
echo "     Mode:       active (no inbound port required)"