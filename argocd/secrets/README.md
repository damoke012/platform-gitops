# Lab secret management: OpenBao + External Secrets Operator

**UNVALIDATED until first sync** (written 2026-11-09). Charts rendered and images passed Harbor's policy;
not yet applied. This README is updated with the result.

Why: every obs-agent secret comes from a secret manager through External Secrets Operator (ESO), never
from a file or a hand-made Secret (Dare, 2026-11-08; obs-agent `docs/SECRETS.md`). USX uses AWS Secrets
Manager; the lab runs OpenBao on-prem, the same contract.

| Part | What |
|---|---|
| `lab-eso` | ESO 2.14.0 (chart pinned), image mirrored to Harbor by digest, UID assigned by restricted-v2 |
| `lab-openbao` | OpenBao 2.7.2 (chart 0.30.5), standalone, file storage + audit log on PVCs, TLS from the OpenShift service CA, UI at https://openbao.apps.lab.ocp.lan (reencrypt Route) |
| `lab-secrets-config` | ClusterSecretStore `obs-agent-secrets` (vault provider, Kubernetes auth, usable only from namespace obs-agent) and OpenBao's NetworkPolicy (ESO + router only) |
| `bootstrap/openbao-init.sh` | one-time init/unseal/config/load, run by a person |

Seal: **Shamir**, 3 shares, threshold 2, held by Dare off the cluster. After any restart OpenBao is sealed
until someone runs `openbao-init.sh` (it then only asks for 2 shares). While sealed, existing Secrets keep
working; ESO cannot refresh. The static seal (key file) would auto-unseal but puts the key on the cluster:
not used.

Least privilege: ESO's service account may read `secret/data/obs-agent/*` only (policy `obs-agent-read`);
Dare's userpass login `dare` may write that path only (`obs-agent-writer`); the root token is revoked at
the end of bootstrap.

## Bootstrap (once, cluster admin on ocp-svc, after merge)

```sh
export KUBECONFIG=/root/ocp-install/auth/kubeconfig
for ns in external-secrets lab-secrets; do
  oc get ns $ns >/dev/null 2>&1 || oc create ns $ns
  oc label ns $ns argocd.argoproj.io/managed-by=openshift-gitops --overwrite
  oc -n obs-agent get secret harbor-pull -o json | jq --arg ns $ns '{apiVersion,kind,type,data,metadata:{name:.metadata.name,namespace:$ns}}' | oc apply -f -
done
oc apply -f argocd/secrets/bootstrap/applications.yaml
# when openbao-0 is Running:
argocd/secrets/bootstrap/openbao-init.sh
```

## Secret paths (KV v2, mount `secret`)

`obs-agent/llm` anthropic-api-key · `obs-agent/notify` webhook-url · `obs-agent/console` session-key,
token-dare · `obs-agent/git` pr-token, feedback-token. Same names as obs-agent `docs/SECRETS.md`.

## Not covered

- The `harbor-pull` registry secrets in each namespace are still copied by hand; moving them to
  ExternalSecrets (dockerconfigjson template) is the next step.
- No backup of OpenBao's data yet (snapshot agent not deployed).
- Single replica; no HA.
