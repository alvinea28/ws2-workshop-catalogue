# WS2 · Eight independent laboratories

Learn one network scenario with **Terraform Azure Verified Modules (AVM)**,
GitHub, Copilot, tests, security, delivery and feedback. Start with **01** if new;
each lab supplies its own setup, baseline, lessons and attributed reference images.
The catalogue is a directory, **not a ninth Exercise**. **No Bicep or Sentinel.**

[All 33 lessons and historical results](full-ws-content/README.md) · [DevSecOps flow and prerequisites](docs/devsecops-flow.md)

## Prepare your machine before the workshop

**Windows x64: [run the one-command setup](docs/windows-setup.md#2-paste-this-one-command)
before cloning anything.** It installs Git, desktop VS Code, Node **24.16.0**,
Terraform **1.16.1**, terraform-docs **0.24.0**, actionlint **1.7.12**, GitHub CLI,
Azure CLI and **six VS Code extensions**, including Copilot Chat and Terraform.
Run once for all eight labs; compatible installed tools are reused. Preview and
check-only modes are included. Restart VS Code after **READY**.

No Git/Node/VS Code installation is needed to run the setup itself; it uses
Windows PowerShell and WinGet. Your GitHub/Copilot sign-in, MFA/seat and permissions
remain personal steps. Other platforms keep the manual **Setup** guides below.
No cloud resources, identities, subscriptions, state or learner progress are changed.

## Start in your own private copy

1. Open a source README below. Use **COPY EXERCISE** or **Use this template →
  Create a new repository**; choose your permitted owner and **Private**, retaining
  the laboratory-number suffix. Already copied? Reuse that copy.
2. Already ran the Windows setup? Skip manual installs. Otherwise use **Setup**
  below to install the tools. In **your copy**,
  copy **Code → HTTPS**; use **Ctrl+Shift+P → Git: Clone** (macOS: **Cmd**), paste
  **your own URL**, choose a folder, then **Open** only that clone—not its parent.
3. Follow **Setup** for accounts, local authorship, Copilot seat and tool verification.
  Run its explained **read-only doctor** at the clone root; stop on errors and
  use that lab's linked recovery instructions. A doctor cannot certify a seat/login.
4. Open **your copy's Exercise** and follow its current task. Save, inspect, commit
  and push as instructed; AgentAlvine checks real activity and updates that same
  issue body. Use Actions for diagnostics, not manual checkboxes or evidence PRs.

## Choose a laboratory

Numbers recommend an order, not dependencies. **Preview** is read-only, not your progress.

| Lab / source README | Focus | Setup | Source Preview |
| --- | --- | --- | --- |
| [01](https://github.com/alvinea28/ws2-github-copilot-laboratory-01/blob/dev/README.md) | GitHub, VS Code, Copilot and educational PR | [Setup](https://github.com/alvinea28/ws2-github-copilot-laboratory-01/blob/dev/docs/start-here.md) | [Preview](https://github.com/alvinea28/ws2-github-copilot-laboratory-01/issues/1) |
| [02](https://github.com/alvinea28/ws2-network-module-laboratory-02/blob/dev/README.md) | Network contract; AVM VNet/subnets/NSG | [Setup](https://github.com/alvinea28/ws2-network-module-laboratory-02/blob/dev/docs/start-here.md) | [Preview](https://github.com/alvinea28/ws2-network-module-laboratory-02/issues/1) |
| [03](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/blob/dev/README.md) | NSG rules/associations; policy governance | [Setup](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/blob/dev/docs/start-here.md) | [Preview](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/issues/1) |
| [04](https://github.com/alvinea28/ws2-terraform-tests-docs-laboratory-04/blob/dev/README.md) | Tests, generated docs and repository security | [Setup](https://github.com/alvinea28/ws2-terraform-tests-docs-laboratory-04/blob/dev/docs/start-here.md) | [Preview](https://github.com/alvinea28/ws2-terraform-tests-docs-laboratory-04/issues/1) |
| [05](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/blob/dev/README.md) | Release/exact consumer pin; stack lifecycle | [Setup](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/blob/dev/docs/start-here.md) | [Preview](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/issues/1) |
| [06](https://github.com/alvinea28/ws2-github-actions-ci-laboratory-06/blob/dev/README.md) | Red/green Actions CI; Defender DevOps | [Setup](https://github.com/alvinea28/ws2-github-actions-ci-laboratory-06/blob/dev/docs/start-here.md) | [Preview](https://github.com/alvinea28/ws2-github-actions-ci-laboratory-06/issues/1) |
| [07](https://github.com/alvinea28/ws2-azure-delivery-laboratory-07/blob/dev/README.md) | Identity/state, protected delivery and posture | [Setup](https://github.com/alvinea28/ws2-azure-delivery-laboratory-07/blob/dev/docs/start-here.md) | [Preview](https://github.com/alvinea28/ws2-azure-delivery-laboratory-07/issues/1) |
| [08](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/blob/dev/README.md) | Recovery, compatible upgrade and Monitor feedback | [Setup](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/blob/dev/docs/start-here.md) | [Preview](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/issues/1) |

## Fill your own Azure values and sign in

Azure setup is separate from offline entry. Each guide explains your assigned
tenant, subscription and **existing RG**, CLI installation, conditional login/MFA
and a read-only RG check. Never commit these values or copy the author's account.

| Lab | Architecture / hands-on instructions | Your Azure values and sign-in |
| --- | --- | --- |
| 01 | [Inspect and merge an educational PR](https://github.com/alvinea28/ws2-github-copilot-laboratory-01/blob/dev/.github/steps/04.md) | [Azure setup](https://github.com/alvinea28/ws2-github-copilot-laboratory-01/blob/dev/docs/azure-setup.md) |
| 02 | [Pinned Terraform AVM network](https://github.com/alvinea28/ws2-network-module-laboratory-02/blob/dev/avm/README.md) | [Azure setup](https://github.com/alvinea28/ws2-network-module-laboratory-02/blob/dev/docs/azure-setup.md) |
| 03 | [Policy: observe, fix and clean up](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/blob/dev/docs/policy-hands-on.md) | [Azure setup](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/blob/dev/docs/azure-setup.md) |
| 04 | [Advanced Security: find, fix, rescan](https://github.com/alvinea28/ws2-terraform-tests-docs-laboratory-04/blob/dev/docs/security-hands-on.md) | [Azure setup](https://github.com/alvinea28/ws2-terraform-tests-docs-laboratory-04/blob/dev/docs/azure-setup.md) |
| 05 | [Separate Terraform/AzAPI stack bridge](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/blob/dev/stack/README.md) | [Azure setup](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/blob/dev/docs/azure-setup.md) |
| 06 | [Defender DevOps scan and ingestion](https://github.com/alvinea28/ws2-github-actions-ci-laboratory-06/blob/dev/docs/defender-devops-hands-on.md) | [Azure setup](https://github.com/alvinea28/ws2-github-actions-ci-laboratory-06/blob/dev/docs/azure-setup.md) |
| 07 | [Defender runtime posture and remediation](https://github.com/alvinea28/ws2-azure-delivery-laboratory-07/blob/dev/docs/defender-posture-hands-on.md) | [Azure setup](https://github.com/alvinea28/ws2-azure-delivery-laboratory-07/blob/dev/docs/azure-setup.md) |
| 08 | [Monitor → Logic Apps → GitHub feedback](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/blob/dev/docs/monitor-feedback-hands-on.md) | [Azure setup](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/blob/dev/docs/azure-setup.md) |

**Tools:** Node.js **24.16.0**; Terraform **1.16.1** for 02–08; terraform-docs
**0.24.0** for 04. The custom learner baseline uses AzureRM **5.4.0**, not AVM.
Isolated profiles select AzureRM **4.81.0** / AzAPI **2.12.0** where used, with
their own locks/state; the baseline is not downgraded or adopted by a stack.

## Educational PRs are not live approval

In **01/05**, inspect your own diff and current checks, then **merge your own
educational PR where repository rules permit**. GitHub cannot approve your own
PR. Required nonauthor reviews still apply; never disable checks or use a bypass.

**Live 07 is not solo:** protected main, independent approvals and exact-plan
review remain mandatory. Its baseline workflow does **not** deploy the four new
profiles automatically. Public templates/PR CI have no Azure/OIDC/state access.
Lab 08 can finish offline without 07; approved live follow-up uses one designated writer.

**Prior authoring checks:** all four profiles initialized/validated; **9 mocked
contracts passed (3 + 2 + 2 + 2)** with Windows/Linux lock hashes. Not rerun for
this docs edit; not Exercise completion, cloud deployment, OAuth, finding ingestion,
monitoring-issue creation or deletion proof. Owner access/licensing/preflight remain real gates.

Every authorized live exercise ends with **full reviewed cleanup through each
original root/state** and verified inventory. Retain the existing RG, backend,
identities, runner and shared settings. Issue progress never authorizes Azure.

Maintenance is **dev only**; **main publication is prohibited** by authoring policy.
The optional workstation installer changes local software, never cloud permissions
or repositories. [MIT license](LICENSE).
