#!/usr/bin/env bash
# Run terraform with the ESXi password loaded from a file on the runner.
# The provider reads env `esxi_password`; it is never a TF variable, so never in a plan file.
set -euo pipefail
: "${ESXI_PASSWORD_FILE:?set in the runner .env}"
esxi_password="$(<"$ESXI_PASSWORD_FILE")"
export esxi_password
exec terraform "$@"
