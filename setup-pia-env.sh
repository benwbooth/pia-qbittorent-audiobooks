#!/bin/sh
# Prompt for PIA credentials and write them into pia.env for Gluetun.

set -eu

ENV_FILE="pia.env"

sanitize_input() {
  # Strip control characters (including stray ESC) while leaving printable bytes intact.
  # shellcheck disable=SC2019,SC2018
  printf '%s' "$1" | LC_ALL=C tr -d '\000-\010\013\014\016-\037\177'
}

printf "Enter PIA username (e.g. p1234567): "
IFS= read -r OPENVPN_USER
OPENVPN_USER=$(sanitize_input "${OPENVPN_USER:-}")

if [ -z "$OPENVPN_USER" ]; then
  echo "PIA username is required." >&2
  exit 1
fi

printf "Enter PIA password: "
if [ -t 0 ]; then
  # Disable echo for password entry when running in a TTY.
  trap 'stty echo' INT TERM EXIT
  stty -echo
fi
IFS= read -r OPENVPN_PASSWORD
OPENVPN_PASSWORD=$(sanitize_input "${OPENVPN_PASSWORD:-}")
if [ -t 0 ]; then
  stty echo
  trap - INT TERM EXIT
  printf "\n"
else
  printf "\n"
fi

if [ -z "$OPENVPN_PASSWORD" ]; then
  echo "PIA password is required." >&2
  exit 1
fi

cat >"$ENV_FILE" <<EOF
OPENVPN_USER=$OPENVPN_USER
OPENVPN_PASSWORD=$OPENVPN_PASSWORD
EOF

chmod 600 "$ENV_FILE"
echo "Credentials written to $ENV_FILE"
