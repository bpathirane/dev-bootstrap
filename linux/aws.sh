#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists aws; then
  echo "AWS CLI $(aws --version) already installed"
  exit 0
fi

curl "https://awscli.amazonaws.com/awscli-exe-linux-$(get_arch).zip" -o "/tmp/awscliv2.zip"
cd /tmp && unzip -q awscliv2.zip && sudo ./aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "AWS CLI installed"
