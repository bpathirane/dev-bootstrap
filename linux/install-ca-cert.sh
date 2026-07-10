#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-cert.crt>" >&2
  exit 2
fi
SRC="$1"
if [ ! -f "$SRC" ]; then
  echo "Cert file not found: $SRC" >&2
  exit 2
fi
sudo mkdir -p /usr/local/share/ca-certificates
FNAME=$(basename "$SRC")
TMP="$PWD/$FNAME"
cp "$SRC" "$TMP"
# If DER format, convert to PEM
if file "$TMP" | grep -qi DER; then
  openssl x509 -inform der -in "$TMP" -out "$TMP.pem"
  sudo cp "$TMP.pem" "/usr/local/share/ca-certificates/${FNAME%.crt}.crt"
else
  sudo cp "$TMP" "/usr/local/share/ca-certificates/$FNAME"
fi
sudo update-ca-certificates
echo "Installed certificate to /usr/local/share/ca-certificates/. Run 'curl -v' to validate." 
