# WS2 · Eight independent, beginner-friendly laboratories

Learn one Azure network scenario through **GitHub, VS Code, Copilot, Terraform,
tests, releases, CI and guarded delivery**. Each public template contains its
own complete setup guide, detailed exercise steps, attributed screenshots,
starting files, references and tests. **No earlier lab repository is required.**

> [!IMPORTANT]
> **First time? Start with Laboratory 01.** The numbers show the recommended
> learning sequence, not mandatory dependencies. You may enter another lab
> directly; its own **Start here** guide repeats all required setup.

## Review all content and the guided Exercise experience

**[Full workshop content, simulation results and screenshots](full-ws-content/README.md)**
links every lab's complete activity Markdown and its read-only public Exercise
preview. Learners still begin in **their private copy's Exercise issue**;
AgentAlvine uses Actions underneath to validate real activity and update that
same issue. The catalogue is a directory, not a ninth course issue.

## Choose a laboratory

| Order | Public source repository | Focus | External prerequisite |
| --- | --- | --- | --- |
| 01 | [ws2-github-copilot-laboratory-01](https://github.com/alvinea28/ws2-github-copilot-laboratory-01) | GitHub account, clone, VS Code, Copilot, issue and PR | Real nonauthor reviewer for the final PR; no Terraform/Azure required |
| 02 | [ws2-network-module-laboratory-02](https://github.com/alvinea28/ws2-network-module-laboratory-02) | Typed network boundary, VNet and stable named subnets | Local pinned tools; no Azure |
| 03 | [ws2-subnet-security-laboratory-03](https://github.com/alvinea28/ws2-subnet-security-laboratory-03) | Standalone NSG/rules/associations with synthetic IDs | Local pinned tools; no network-lab copy |
| 04 | [ws2-terraform-tests-docs-laboratory-04](https://github.com/alvinea28/ws2-terraform-tests-docs-laboratory-04) | Write tests, prove a seeded rejection, generate docs | Complete module supplied; terraform-docs 0.24.0 |
| 05 | [ws2-module-release-consumer-laboratory-05](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05) | Reviewed release and exact own-copy consumer pin | Complete module/consumer supplied; real nonauthor reviewer |
| 06 | [ws2-github-actions-ci-laboratory-06](https://github.com/alvinea28/ws2-github-actions-ci-laboratory-06) | Real failing/passing CI and typed reusable workflow | Complete module supplied; GitHub Actions available |
| 07 | [ws2-azure-delivery-laboratory-07](https://github.com/alvinea28/ws2-azure-delivery-laboratory-07) | Identity/state study and controlled delivery | Offline module/snapshot supplied; live steps require private instructor-approved copy and real sandbox/gates |
| 08 | [ws2-operations-capstone-laboratory-08](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08) | Sanitized diagnosis, safe recovery, compatible app subnet | Complete module supplied; optional later live follow-up is separately approved |

## Fill your own Azure values and sign in

Each lab includes a complete **Azure setup** guide. Use your own tenant ID,
subscription ID and instructor-assigned existing resource group—not the author's
values. The guide covers finding values in the portal, Azure CLI installation,
reusing an existing login, browser/MFA or device-code sign-in when needed, and a
read-only check of the exact selected resource group. Values stay in your terminal
session and are not committed to the repository.

| Lab | Complete attendee Azure instructions |
| --- | --- |
| 01 | [Tenant, subscription, RG and login](https://github.com/alvinea28/ws2-github-copilot-laboratory-01/blob/dev/docs/azure-setup.md) |
| 02 | [Tenant, subscription, RG and login](https://github.com/alvinea28/ws2-network-module-laboratory-02/blob/dev/docs/azure-setup.md) |
| 03 | [Tenant, subscription, RG and login](https://github.com/alvinea28/ws2-subnet-security-laboratory-03/blob/dev/docs/azure-setup.md) |
| 04 | [Tenant, subscription, RG and login](https://github.com/alvinea28/ws2-terraform-tests-docs-laboratory-04/blob/dev/docs/azure-setup.md) |
| 05 | [Tenant, subscription, RG and login](https://github.com/alvinea28/ws2-module-release-consumer-laboratory-05/blob/dev/docs/azure-setup.md) |
| 06 | [Tenant, subscription, RG and login](https://github.com/alvinea28/ws2-github-actions-ci-laboratory-06/blob/dev/docs/azure-setup.md) |
| 07 | [Tenant, subscription, RG and login](https://github.com/alvinea28/ws2-azure-delivery-laboratory-07/blob/dev/docs/azure-setup.md) |
| 08 | [Tenant, subscription, RG and login](https://github.com/alvinea28/ws2-operations-capstone-laboratory-08/blob/dev/docs/azure-setup.md) |

Setup does not provision resources or grant permissions. PR jobs must remain
credential-free. Every approved live exercise must finish with full destruction
of its own managed workload and verified cleanup; preserve existing/shared
resource groups, backends and identities. Do not confuse sign-in, provider-mocked
validation or an Exercise checkbox with a verified Azure deployment.

## Exactly how to begin

1. Open the selected public repository above and read its **Start here** section.
2. Use **COPY EXERCISE** or **Use this template → Create a new repository**.
3. Choose your intended personal/assigned owner and **Private** visibility.
4. Name your copy with the same ending, such as `my-ws2-network-module-laboratory-02`.
5. Wait for AgentAlvine's Exercise issue. **Copying on GitHub is not cloning.**
6. Install Git and desktop VS Code if needed, then use **Ctrl+Shift+P → Git: Clone**
   with **your own copy's URL**, choose a local folder and select **Open**.
7. Verify the GitHub account, local commit authorship and Copilot account/seat
   separately. Follow the included screenshots; never paste a token into chat.
8. Run the local readiness doctor, then follow the current Exercise issue.

If you already created a private copy, skip making another one and continue
with cloning/opening it. Open each clone as its own VS Code folder, not one
large parent directory containing many unrelated repositories.

## What is independent, and what is not simulated

- The labs include all code needed for their own offline exercises. Labs 03–08
  do not require work produced in Labs 01/02; their local baselines are supplied.
- Lab 07 includes its own complete module and verified vendored snapshot. Its
  offline study/tests require no prior network deployment or other lab repository.
- Lab 08 can finish offline without Lab 07. If the instructor later requests
  live follow-up, use **one** chosen private delivery copy and its review gates.
- Peer reviews, Copilot entitlement and real instructor cloud prerequisites are
  genuine requirements, not outcomes a script may invent. Missing prerequisites
  stay visibly pending; do not weaken permissions, locking or approvals.

**Pinned tools:** Node.js 24.16.0; Terraform 1.16.1 and AzureRM 5.4.0 for Labs
02–08; terraform-docs 0.24.0 for Lab 04. Git and VS Code setup is explained in
every lab. All PR/learner CI is credential-free and provider-mocked.

**Public templates never deploy Azure.** No Azure resources, identities,
subscriptions or remote state are changed by copying, setup checks, or offline
workshop tests. Real delivery is instructor-prepared, private and independently
approved. AgentAlvine's educational progress is not deployment authorization.

Reference screenshots are authentic publisher documentation images, attributed
and labelled in each repository; they are not fabricated participant screens.
Original workshop code is MIT-licensed. Source maintenance is on **dev**.