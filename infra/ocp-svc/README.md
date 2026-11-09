# ocp-svc host configuration

ocp-svc (192.168.22.1; Tailscale node `localhost-0`, 100.104.146.8) runs the lab's DNS (`named`), the
HAProxy in front of the API (:6443), ingress (:80/:443) and machine-config (:22623), and the Tailscale subnet
router. Nothing here is managed by Argo CD. Written 2026-11-09.

## Tailnet access to the lab (changed 2026-11-09, with Dare's approval)

| Change | Where | How it is recorded |
|---|---|---|
| `named` answers `100.64.0.0/10` (allow-query) | /etc/named.conf on ocp-svc | `named-tailnet.yml` (idempotent; matches the manual change) |
| Subnet route `192.168.22.0/24` advertised by `localhost-0` (plus the existing `192.168.1.144/32`, the ESXi host) | Tailscale node + admin console approval | here only: `tailscale set --advertise-routes=192.168.1.144/32,192.168.22.0/24`, approve in the admin console |
| Split DNS `lab.ocp.lan` -> `192.168.22.1` | Tailscale admin console (DNS) | here only |

Why: phones (Dare, Kenna, Olu) open Slack links to https://obs-agent.apps.lab.ocp.lan, Grafana and Argo CD
off the home Wi-Fi.

## What this exposes, and the ACL it needs

Advertising 192.168.22.0/24 makes every lab node and port reachable from any tailnet device the ACL allows,
including the OpenShift API (:6443 on ocp-svc and the control planes), machine-config (:22623), SSH to the
nodes, and etcd peers. The Tailscale ACL should allow the phones only DNS and HTTPS:

```jsonc
// Tailscale ACL (admin console). Group names are examples.
"groups": {"group:lab-viewers": ["dare@...", "kenna@...", "olu@..."]},
"acls": [
  {"action": "accept", "src": ["group:lab-viewers"],
   "dst": ["192.168.22.1:53", "192.168.22.211:443", "192.168.22.212:443", "192.168.22.213:443", "192.168.22.1:443"]}
]
```

Not yet managed as code: the Tailscale ACL, DNS and route approvals live in the admin console. The
Tailscale Terraform provider (`tailscale/tailscale`) can own them later.
