# Lab inference: local LLM on the Tesla P40

Written 2026-11-08 (OCP 4.19.11 home lab). obs-agent's **secondary model**: when the Anthropic API fails
(credit, auth, rate limit, outage), L2 re-runs the incident on this model, marks the answer degraded,
opens no PR and never escalates from it. Off by default in obs-agent; enabled on the lab only.

| Part | What |
|---|---|
| Image | `images/llama-cpp-p40`: llama.cpp b7472, CUDA 12.2 (driver 535), sm_61, CPU code limited to SSE4.2/AVX (the node's Xeon E5-2670 has no AVX2/FMA/F16C/BMI2: anything more dies with SIGILL, exit 132) |
| Model | Qwen2.5-7B-Instruct Q4_K_M (Apache-2.0), HF revision bb5d59e, SHA-256 checked by the init container |
| API | OpenAI-compatible, tool calling (`--jinja`), `http://llm-local.lab-inference.svc:8080/v1`, model `qwen2.5-7b-instruct`, no key |
| Access | NetworkPolicy: only obs-agent L2/L3 pods; egress DNS + 443 (model download) |

Measured 2026-11-08 on the P40 (one request at a time, 32k context): tool call chosen and arguments correct on
a two-turn SCC case; 32 tok/s generation on a short prompt, 18 tok/s at 27k context; prefill ~470 tok/s at
27k (61 s for a full 27k prompt). Quality is well below Claude: on that case it named the cause but proposed
a weaker fix.

## Bootstrap (once, after merge)

```sh
oc create ns lab-inference
oc -n obs-agent get secret harbor-pull -o json | jq '{apiVersion,kind,type,data,metadata:{name:.metadata.name,namespace:"lab-inference"}}' | oc apply -f -
oc apply -f argocd/inference/bootstrap/application.yaml
```

## Not covered

- nvcr.io is unreachable from ocp-svc, so the CUDA base images come from Docker Hub.
- The GPU is shared with anything else that requests it; this Deployment holds it permanently.
- No eval of the model on real incidents yet.
