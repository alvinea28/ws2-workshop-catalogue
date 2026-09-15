# Full workshop content and historical review

Eight independent review packs contain **all 33 full activity lessons**, complete
setup and attributed reference images. They mirror the course; this index is not
a ninth Exercise. Additional service companions are separate from those grades.

## Start in your copy, review here

Follow the [participant entry](../README.md#start-in-your-own-private-copy):
**copy Private → clone your own URL → open/setup/read-only doctor → your Exercise**.
Reuse an existing copy. AgentAlvine checks real activity and updates the same issue
body; Actions is for results/recovery, not manual checkboxes or evidence PRs.
[Eight own-value Azure guides](../README.md#fill-your-own-azure-values-and-sign-in)
cover tenant, subscription, existing RG and sign-in; setup grants no deployment permission.

## Complete lessons and original Cycle A / B outcomes

**Historical: 2026-09-08.** Pending entries below remain pending in those records;
current solo educational PR guidance for 01/05 does not retroactively complete them.

| Lab / lesson count | Full review pack | Source Preview | Original A / B |
| --- | --- | --- | --- |
| 01 · GitHub/Copilot · 4 | [All lessons](https://github.com/alvinea28/ws2-github-copilot-laboratory-01/tree/dev/full-ws-content) | [Preview](https://github.com/alvinea28/ws2-github-copilot-laboratory-01/issues/1) | 3/4 · 3/4; nonauthor review pending |
| 02 · Network module · 4 | [All lessons](https://github.com/alvinea28/ws2-network-module-laboratory-02/tree/dev/full-ws-content) | [Preview](https://github.com/alvinea28/ws2-network-module-laboratory-02/issues/1) | 4/4 · 4/4 offline |
| 03 · Subnet security · 4 | [All lessons](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/tree/dev/full-ws-content) | [Preview](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/issues/1) | 4/4 · 4/4 offline |
| 04 · Tests/docs · 4 | [All lessons](https://github.com/alvinea28/ws2-terraform-tests-docs-laboratory-04/tree/dev/full-ws-content) | [Preview](https://github.com/alvinea28/ws2-terraform-tests-docs-laboratory-04/issues/1) | 4/4 · 4/4 offline |
| 05 · Release/consumer · 4 | [All lessons](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/tree/dev/full-ws-content) | [Preview](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/issues/1) | 1/4 · 1/4; review/release/pin pending |
| 06 · Actions CI · 4 | [All lessons](https://github.com/alvinea28/ws2-github-actions-ci-laboratory-06/tree/dev/full-ws-content) | [Preview](https://github.com/alvinea28/ws2-github-actions-ci-laboratory-06/issues/1) | 4/4 · 4/4 offline; real red/green CI recorded |
| 07 · Guarded delivery · 5 | [All lessons](https://github.com/alvinea28/ws2-azure-delivery-laboratory-07/tree/dev/full-ws-content) | [Preview](https://github.com/alvinea28/ws2-azure-delivery-laboratory-07/issues/1) | 1/5 · 1/5; instructor/cloud gates pending |
| 08 · Operations · 4 | [All lessons](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/tree/dev/full-ws-content) | [Preview](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/issues/1) | 4/4 · 4/4 offline; live follow-up separate |

Source Preview is **read-only and non-grading**, not your copy's Exercise.
The recorded **2026-09-14** previews show **0/4** (07: **0/5**); zero source progress
is expected, not a failed learner run. They are not historical participant issues.

## Separate service companions — authoring checks, not Exercise grades

The [DevSecOps hands-on map](../docs/devsecops-flow.md#hands-on-map) covers AVM,
Policy, Advanced Security, stacks, Defender and Monitor/Logic Apps; **no Sentinel**.
These procedures add no completed activities to the original 33.

| Actual isolated Terraform profile | Required mock cases | Shipped CI definition |
| --- | --- | --- |
| [02 · AVM VNet/NSG](https://github.com/alvinea28/ws2-network-module-laboratory-02/blob/dev/avm/README.md) | 3 | [Companion contract checks](https://github.com/alvinea28/ws2-network-module-laboratory-02/blob/dev/.github/workflows/companion-checks.yml) |
| [03 · RG policy assignment](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/blob/dev/governance/README.md) | 2 | [Companion contract checks](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/blob/dev/.github/workflows/companion-checks.yml) |
| [05 · Separate stack bridge](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/blob/dev/stack/README.md) | 2 | [Companion contract checks](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/blob/dev/.github/workflows/companion-checks.yml) |
| [08 · Monitor/AVM Logic Apps](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/blob/dev/monitoring/README.md) | 2 | [Companion contract checks](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/blob/dev/.github/workflows/companion-checks.yml) |

CI checks the **actual profile**: formatting, backend-disabled read-only initialization,
schema validation and exact mock counts, with no failures/errors/skips accepted.
Prior local initialization/validation passed for **4/4 profiles**, with **9 contracts
(3 + 2 + 2 + 2)** and Windows/Linux lock hashes. No tests or remote CI were rerun here.
This is not Azure deployment, OAuth consent, finding ingestion, alert/issue delivery
or stack/resource deletion proof. Live work still needs owner access/licensing/preflight;
new profiles are not wired into baseline Lab 07 delivery.

## Keep evidence dates and limits

- **2026-09-08:** both original cycles reached **25/33**. A passed **301 Node** tests;
  B passed **325**. Each recorded **229** distinct mocked cases/fixtures, excluding
  repeated phases. Do not add new companion checks to those historical totals.
- **2026-09-14:** public preview captures and separately labelled fresh local-output
  images are review material; publisher reference images retain attribution.
- [Private per-activity proof](https://github.com/alvine-aurelio-org/ws2-public-rebuild-20260908-evidence/tree/dev/full-ws-content)
  retains original revisions/timestamps, issue records and CI links. Authorized access
  is required; raw logs/backups remain private. No new participant cycle is claimed.
- Original-day per-step browser captures did not exist. Later evidence-viewer images
  are not September 8 screens or proof of live Azure health, installation/MFA/seat access.
- Educational self-inspection/merge is allowed only under repository rules; GitHub
  cannot self-approve. **Protected live 07 retains independent approvals and full cleanup.**

Issue progress never authorizes Azure. This documentation changes no permissions;
maintenance remains **dev only**, with no main publication.
[Return to the workshop catalogue](../README.md).
