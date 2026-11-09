#!/usr/bin/env bash
# One-time OpenBao bootstrap for the lab, run by a person on ocp-svc. Written 2026-11-09. Idempotent.
#
#   1. init (first run only): prints 3 unseal key shares + the root token ONCE, to this terminal only.
#      Save them in your password manager, off the cluster. Nothing is written to disk.
#   2. unseal: asks for 2 of the 3 shares (hidden input).
#   3. configure: KV v2 at secret/, audit log, Kubernetes auth, policy obs-agent-read, role eso-obs-agent
#      (ESO's service account may read secret/data/obs-agent/* and nothing else), and a userpass login
#      "dare" with policy obs-agent-writer for later rotations, so the root token is not needed again.
#   4. load: copies obs-agent's current secrets from the root-only files on ocp-svc into OpenBao.
#      Values go through stdin, never argv, never printed. Missing files are skipped.
#   5. revokes the root token.
#
# After a restart (power cut), OpenBao starts sealed: re-run this script; it only asks for 2 shares.
set -euo pipefail
export KUBECONFIG=${KUBECONFIG:-/root/ocp-install/auth/kubeconfig}
NS=lab-secrets; POD=openbao-0
bao()   { oc -n "$NS" exec -i "$POD" -- bao "$@"; }
# Runs a bao command with the token read from stdin (first line), so it never appears in a process list.
as_root() { local cmd=$1; shift; { printf '%s\n' "$ROOT"; cat; } | oc -n "$NS" exec -i "$POD" -- sh -c "read -r BAO_TOKEN; export BAO_TOKEN; $cmd"; }

oc -n "$NS" wait --for=jsonpath='{.status.phase}'=Running pod/"$POD" --timeout=300s >/dev/null
st=$(bao status -format=json 2>/dev/null || true)

if [ "$(echo "$st" | jq -r .initialized)" != "true" ]; then
  echo "== Initialising OpenBao. The output below is shown ONCE. Save it now, off the cluster."
  bao operator init -key-shares=3 -key-threshold=2
  echo "== Saved the 3 unseal keys and the root token? Press Enter to continue."; read -r _
  st=$(bao status -format=json 2>/dev/null || true)
fi

if [ "$(echo "$st" | jq -r .sealed)" = "true" ]; then
  for n in 1 2; do
    read -rs -p "Unseal key share $n: " K; echo
    printf '%s\n' "$K" | oc -n "$NS" exec -i "$POD" -- bao operator unseal - >/dev/null; unset K
  done
  [ "$(bao status -format=json | jq -r .sealed)" = "false" ] && echo "== Unsealed." || { echo "Still sealed."; exit 1; }
fi

read -rs -p "Root token (Enter to skip configuration and loading, e.g. after a restart): " ROOT; echo
[ -n "$ROOT" ] || { echo "== Unsealed only. Done."; exit 0; }

echo "== Configuring"
as_root 'bao secrets list -format=json | grep -q "\"secret/\"" || bao secrets enable -path=secret kv-v2' </dev/null
as_root 'bao audit list 2>/dev/null | grep -q "^file/" || bao audit enable file file_path=/openbao/audit/audit.log' </dev/null
as_root 'bao auth list -format=json | grep -q "\"kubernetes/\"" || bao auth enable kubernetes' </dev/null
as_root 'bao write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc >/dev/null' </dev/null
printf '%s\n' 'path "secret/data/obs-agent/*" { capabilities = ["read"] }' 'path "secret/metadata/obs-agent/*" { capabilities = ["read", "list"] }' \
  | as_root 'bao policy write obs-agent-read - >/dev/null'
printf '%s\n' 'path "secret/data/obs-agent/*" { capabilities = ["create", "update", "read"] }' 'path "secret/metadata/obs-agent/*" { capabilities = ["read", "list"] }' \
  | as_root 'bao policy write obs-agent-writer - >/dev/null'
as_root 'bao write auth/kubernetes/role/eso-obs-agent bound_service_account_names=external-secrets bound_service_account_namespaces=external-secrets policies=obs-agent-read ttl=1h >/dev/null' </dev/null
as_root 'bao auth list -format=json | grep -q "\"userpass/\"" || bao auth enable userpass' </dev/null
read -rs -p "Password for OpenBao user 'dare' (for later rotations; Enter keeps the current one): " P; echo
if [ -n "$P" ]; then printf '%s\n' "$P" | as_root 'read -r PW; bao write auth/userpass/users/dare password="$PW" policies=obs-agent-writer >/dev/null'; fi; unset P

echo "== Loading obs-agent secrets from files on this host (values are not shown)"
put() {  # put <path> <property>=<file>|env:<VAR> ...   (JSON built locally, sent on stdin)
  local path=$1; shift
  local json; json=$(python3 - "$@" <<'PY'
import json, os, sys
out = {}
for arg in sys.argv[1:]:
    k, f = arg.split("=", 1)
    if f.startswith("env:"):            # value from an environment variable (never argv)
        v = os.environ.get(f[4:], "")
        if v: out[k] = v
    elif os.path.isfile(f) and os.path.getsize(f) > 0:
        out[k] = open(f).readline().strip()
print(json.dumps(out) if out else "")
PY
)
  [ -n "$json" ] || { echo "   $path: no source files, skipped"; return; }
  printf '%s\n' "$json" | as_root "bao kv patch -mount=secret $path - >/dev/null 2>&1 || bao kv put -mount=secret $path - >/dev/null"
  echo "   $path: $(echo "$json" | jq -r 'keys | join(", ")')"
}
SESSION_KEY=$(oc -n obs-agent get secret obs-agent-console -o jsonpath='{.data.session-key}' 2>/dev/null | base64 -d || true)
[ -n "$SESSION_KEY" ] || SESSION_KEY=$(openssl rand -hex 32)
put obs-agent/llm     anthropic-api-key=/root/.anthropic-api-key
put obs-agent/notify  webhook-url=/root/.obs-notify-webhook
export SESSION_KEY; put obs-agent/console token-dare=/root/.obs-console-token-dare session-key=env:SESSION_KEY
put obs-agent/git     pr-token=/root/.obs-prwriter-token feedback-token=/root/.obs-feedback-token
unset SESSION_KEY

as_root 'bao token revoke -self >/dev/null' </dev/null; unset ROOT
echo "== Done. Root token revoked. Later changes: log in as 'dare' (UI https://openbao.apps.lab.ocp.lan, or bao login -method=userpass)."
