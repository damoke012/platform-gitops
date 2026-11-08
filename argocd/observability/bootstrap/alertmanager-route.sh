#!/usr/bin/env bash
# Severity routing for lab alerts in the platform Alertmanager (openshift-monitoring/alertmanager-main).
# Run once by an admin on ocp-svc. Not in Argo CD: the config holds the webhook URL, a credential,
# and there is no secret manager on this cluster.
# Supersedes AiChohort integration/obs-agent/scripts/40-alertmanager-teams.sh (its obs-agent route is
# included here).
#
#   argocd/observability/bootstrap/alertmanager-route.sh --webhook-file /root/.teams-webhook           # dry run, prints the diff
#   argocd/observability/bootstrap/alertmanager-route.sh --webhook-file /root/.teams-webhook --apply
#
# Receiver chosen by URL host: hooks.slack.com -> slack_configs; anything else -> msteamsv2 (Teams
# Workflows; personal teams.live.com accounts cannot create these).
#   critical  every namespace                        wait 30s, repeat 1h
#   warning   every namespace                        wait 2m,  repeat 4h
#   info      lab tiers and obs-agent only           grouped 1h, repeat 24h (a digest, not a page)
#   Watchdog, InfoInhibitor and severity=none        never sent
set -euo pipefail
HOOK=""; APPLY=0
while [ $# -gt 0 ]; do case "$1" in
  --webhook-file) HOOK="$2"; shift 2;; --apply) APPLY=1; shift;;
  *) echo "unknown argument: $1" >&2; exit 2;; esac; done
[ -s "$HOOK" ] || { echo "--webhook-file must point to a non-empty file holding the webhook URL" >&2; exit 2; }
umask 077; WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
oc -n openshift-monitoring get secret alertmanager-main -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d > "$WORK/current.yaml"
python3 - "$WORK/current.yaml" "$HOOK" "$WORK/new.yaml" <<'P'
import sys, yaml
from urllib.parse import urlparse
cur, hook, out = sys.argv[1:]
cfg = yaml.safe_load(open(cur)) or {}
url = open(hook).read().strip()
slack = urlparse(url).hostname == "hooks.slack.com"
title = '{{ if eq .Status "firing" }}{{ if eq .CommonLabels.severity "critical" }}🔴{{ else if eq .CommonLabels.severity "warning" }}🟠{{ else }}🔵{{ end }}{{ else }}✅{{ end }} [{{ .CommonLabels.severity | toUpper }}] {{ .CommonLabels.alertname }}'
text_md = '{{ range .Alerts }}**{{ .Annotations.summary }}**\n\n{{ .Annotations.description }}\n\n{{ end }}'
text_sl = '{{ range .Alerts }}*{{ .Annotations.summary }}*\n{{ .Annotations.description }}\n{{ end }}'
def recv(name):
    if slack:
        return {"name": name, "slack_configs": [{"api_url": url, "send_resolved": True, "title": title, "text": text_sl}]}
    return {"name": name, "msteamsv2_configs": [{"webhook_url": url, "send_resolved": True, "title": title, "text": text_md}]}
# Receivers this script owns; re-running replaces them, nothing else is touched.
ours = {"lab-critical", "lab-warning", "lab-info", "lab-null", "obs-agent-teams"}
cfg["receivers"] = [r for r in cfg.get("receivers", []) if r.get("name") not in ours] + [
    recv("lab-critical"), recv("lab-warning"), recv("lab-info"), {"name": "lab-null"}]
route = cfg.setdefault("route", {"receiver": "lab-null"})
lab = [
    {"receiver": "lab-null", "matchers": ['alertname=~"Watchdog|InfoInhibitor"']},
    {"receiver": "lab-null", "matchers": ['severity="none"']},
    {"receiver": "lab-critical", "matchers": ['severity="critical"'], "group_by": ["alertname", "namespace"],
     "group_wait": "30s", "group_interval": "5m", "repeat_interval": "1h"},
    {"receiver": "lab-warning", "matchers": ['severity="warning"'], "group_by": ["alertname", "namespace"],
     "group_wait": "2m", "group_interval": "10m", "repeat_interval": "4h"},
    {"receiver": "lab-info", "matchers": ['severity="info"', 'tier=~".+"'], "group_by": ["tier"],
     "group_wait": "10m", "group_interval": "1h", "repeat_interval": "24h"},
    {"receiver": "lab-info", "matchers": ['severity="info"', 'namespace="obs-agent"'], "group_by": ["alertname"],
     "group_wait": "10m", "group_interval": "1h", "repeat_interval": "24h"},
]
keep = [r for r in route.get("routes", []) if r.get("receiver") not in ours]
route["routes"] = lab + keep
yaml.safe_dump(cfg, open(out, "w"), sort_keys=False)
print(f"receiver type: {'slack' if slack else 'msteamsv2'}")
P
MASK='s#((webhook_url|api_url|slack_api_url): ).*#\1<masked>#'
diff <(sed -E "$MASK" "$WORK/current.yaml") <(sed -E "$MASK" "$WORK/new.yaml") || true
if [ "$APPLY" = 1 ]; then
  cp "$WORK/current.yaml" "$(dirname "$HOOK")/alertmanager-main.pre-lab.$(date +%Y%m%d%H%M%S).yaml"
  printf '{"data":{"alertmanager.yaml":"%s"}}' "$(base64 -w0 "$WORK/new.yaml")" > "$WORK/patch.json"
  oc -n openshift-monitoring patch secret alertmanager-main --type merge --patch-file "$WORK/patch.json" >/dev/null
  echo "applied; Alertmanager reloads within about a minute."
else
  echo "dry run. Nothing changed. Re-run with --apply."
fi
