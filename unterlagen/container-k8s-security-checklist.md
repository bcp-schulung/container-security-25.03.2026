# Container + Kubernetes Security Checklist (50 Points)

Use this as an audit sheet. Mark each item as done when implemented.

## 1) Governance and Baseline

1. [ ] Define security standards for containers and Kubernetes (CIS/NIST/internal baseline).
   - Example: Create a baseline document and map controls to CIS Kubernetes Benchmark sections 1–5.

2. [ ] Keep a full inventory of clusters, nodes, namespaces, registries, and critical workloads.
   - Example: `kubectl get ns && kubectl get nodes -o wide && kubectl get deploy -A`.

3. [ ] Classify workloads by sensitivity and apply minimum controls per tier.
   - Example: Label namespaces with `security-tier=restricted|internal|public` and enforce policy by label.

4. [ ] Assign clear security ownership (platform/app/SOC) and escalation paths.
   - Example: Define owners for `patching`, `incident response`, `exception approvals` in a RACI table.

5. [ ] Enforce policy-as-code checks before deployment.
   - Example: Block manifests missing `runAsNonRoot` via Kyverno/Gatekeeper admission policy.

## 2) Image Build Security

6. [ ] Use minimal trusted base images.
   - Example: `FROM gcr.io/distroless/static-debian12` instead of full distro images when possible.

7. [ ] Pin image references by digest, not mutable tags.
   - Example: `image: nginx@sha256:<digest>` instead of `nginx:latest`.

8. [ ] Scan images for CVEs in CI and fail on high/critical.
   - Example: `trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:build`.

9. [ ] Generate an SBOM for every build.
   - Example: `syft myapp:build -o spdx-json > sbom.spdx.json`.

10. [ ] Sign images and verify signatures at admission.
    - Example: `cosign sign --key cosign.key registry.local/myapp:1.0.0` + verify policy in cluster.

## 3) CI/CD and Supply Chain

11. [ ] Protect branches and require reviews for infra/security changes.
    - Example: Require 2 approvals for changes under `k8s/` and `Dockerfile` paths.

12. [ ] Isolate CI runners and limit secret access for untrusted builds.
    - Example: Pull request workflows run without production credentials.

13. [ ] Record build provenance/attestation.
    - Example: Attach SLSA-style provenance linking image digest to commit SHA.

14. [ ] Scan Kubernetes manifests/IaC in CI.
    - Example: `trivy config .` or `checkov -d .` before merge.

15. [ ] Detect hardcoded secrets in code and history.
    - Example: `gitleaks detect --source .` in pipeline.

## 4) Registry and Artifact Management

16. [ ] Restrict registry push/pull with strong auth.
    - Example: Separate `push` role for CI and `pull` role for runtime nodes only.

17. [ ] Enforce immutable tags.
    - Example: Registry policy blocks overwriting `v1.2.3` after first push.

18. [ ] Quarantine vulnerable images.
    - Example: Auto-mark image as non-deployable when critical CVEs found.

19. [ ] Replicate registry data and test restore procedures.
    - Example: Weekly restore test from backup to standby registry.

20. [ ] Monitor registry access anomalies.
    - Example: Alert on sudden bulk pulls from unusual IP ranges.

## 5) Node and Host Hardening

21. [ ] Patch node OS, kubelet, and runtime on a defined SLA.
    - Example: Critical updates applied within 7 days.

22. [ ] Harden node OS and disable unused services.
    - Example: Disable password SSH login and remove unused daemons.

23. [ ] Encrypt node disks and use secure boot where supported.
    - Example: Enable cloud-provider disk encryption with customer-managed keys.

24. [ ] Restrict node access and log all admin sessions.
    - Example: Access only via bastion + MFA + session recording.

25. [ ] Detect node configuration drift.
    - Example: Daily baseline comparison of kubelet flags and kernel parameters.

## 6) Pod and Runtime Security

26. [ ] Run containers as non-root.
    - Example:
      ```yaml
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
      ```

27. [ ] Use read-only root filesystems unless writes are required.
    - Example:
      ```yaml
      securityContext:
        readOnlyRootFilesystem: true
      ```

28. [ ] Drop Linux capabilities by default.
    - Example:
      ```yaml
      securityContext:
        capabilities:
          drop: ["ALL"]
      ```

29. [ ] Prevent privilege escalation and privileged mode.
    - Example:
      ```yaml
      securityContext:
        allowPrivilegeEscalation: false
        privileged: false
      ```

30. [ ] Enforce seccomp/AppArmor/SELinux profiles.
    - Example:
      ```yaml
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      ```

## 7) Kubernetes API and Control Plane

31. [ ] Disable anonymous API access and enforce authentication.
    - Example: API server started with `--anonymous-auth=false`.

32. [ ] Enable control-plane and API audit logging.
    - Example: Configure API server `--audit-policy-file` and ship logs centrally.

33. [ ] Encrypt etcd data at rest.
    - Example: Use `EncryptionConfiguration` for secrets in the API server.

34. [ ] Restrict control-plane network exposure.
    - Example: Private API endpoint + allowlist only admin CIDRs.

35. [ ] Rotate certificates and signing keys regularly.
    - Example: Quarterly cert rotation runbook tested in staging.

## 8) Identity, RBAC, and Multi-Tenancy

36. [ ] Apply least-privilege RBAC.
    - Example: Replace broad `cluster-admin` bindings with namespace-scoped Roles.

37. [ ] Review and remove stale role bindings.
    - Example: Monthly report of inactive users/service accounts with elevated privileges.

38. [ ] Disable auto-mounting service account tokens when not needed.
    - Example:
      ```yaml
      automountServiceAccountToken: false
      ```

39. [ ] Use workload identity instead of static cloud keys.
    - Example: Bind Kubernetes SA to cloud IAM role (IRSA/Workload Identity).

40. [ ] Isolate tenants properly.
    - Example: Separate namespaces + NetworkPolicies + distinct quotas and RBAC per tenant.

## 9) Network and Traffic Security

41. [ ] Apply default-deny ingress and egress policies.
    - Example:
      ```yaml
      apiVersion: networking.k8s.io/v1
      kind: NetworkPolicy
      metadata:
        name: default-deny
      spec:
        podSelector: {}
        policyTypes: ["Ingress", "Egress"]
      ```

42. [ ] Explicitly allow only required east-west traffic.
    - Example: Allow `frontend -> api:8443`, deny all other namespace-to-namespace traffic.

43. [ ] Enforce TLS/mTLS for service communication.
    - Example: Service mesh policy requiring mTLS in `strict` mode.

44. [ ] Protect ingress with WAF/rate limits and strict routing.
    - Example: Ingress annotations for rate limit and host-based routing only.

45. [ ] Control outbound traffic and DNS usage.
    - Example: Egress policy allows only approved external endpoints and DNS resolver.

## 10) Secrets, Monitoring, and Incident Response

46. [ ] Use a dedicated secrets manager.
    - Example: External Secrets Operator syncs from Vault/AWS Secrets Manager.

47. [ ] Encrypt Kubernetes Secrets and restrict access.
    - Example: API server secret encryption + RBAC allowing read only for required SAs.

48. [ ] Enable runtime threat detection.
    - Example: Falco alerts on suspicious `setns`, shell spawn, or crypto-mining behavior.

49. [ ] Centralize logs/metrics/traces and alert on security events.
    - Example: Alert when a Pod enters `privileged` mode or policy violations spike.

50. [ ] Test incident response playbooks.
    - Example: Run quarterly tabletop + technical drill for container breakout scenario.

---

## Quick Audit Fields (optional)

For each item, add:
- Owner:
- Status: Pass / Partial / Fail
- Evidence link:
- Target date:
- Notes:
