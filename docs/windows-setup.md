# Prepare your Windows machine once

**Run this before the workshop, before cloning anything.** One pasted PowerShell
command installs the desktop tools and VS Code extensions for **all eight labs**.
You do not need Git, Node.js or VS Code to start. Allow time for downloads and
installer prompts; a restricted company laptop may need IT approval.

## 1. Open ordinary PowerShell

- Use a **supported Windows 11 x64** machine; IT-supported Windows 10 22H2 with
  ESU also passes the platform check. This bundle is not for ARM64, 32-bit Windows,
  WSL, macOS or Linux. Those computers retain the
  [manual architecture-specific route](https://github.com/alvinea28/ws2-github-copilot-laboratory-01/blob/dev/docs/toolchain.md).
- Open **Start → Windows PowerShell**, normally—not **Run as administrator**.
  Use your participant Windows account so extensions go to your own VS Code.
  Individual application installers can still request Windows **UAC** approval.
- **WinGet 1.9+** normally comes with Windows App Installer. If it is absent or
  blocked, update [Microsoft App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1)
  through your approved channel, or ask IT. There is no policy-bypass fallback.
- Review [the installer source](../setup.ps1) and the package/extension list below.
  Running Install accepts the listed WinGet source/package license agreements and
  installs the named Marketplace extensions. Respect your organization's software policy.

## 2. Paste this one command

Copy **the whole block** into PowerShell and press **Enter**. This is one command;
the final word **Install** selects installation. **No repository clone is needed.**

```powershell
& {
    param([ValidateSet('Install', 'Plan', 'Check')] [string] $Mode)
    $ErrorActionPreference = 'Stop'
    $s = Join-Path $env:TEMP ('ws2-setup-' + [guid]::NewGuid() + '.ps1')
    try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 120 -Uri 'https://raw.githubusercontent.com/alvinea28/ws2-workshop-catalogue/dev/setup.ps1' -OutFile $s
        if ((Get-FileHash -LiteralPath $s -Algorithm SHA256).Hash -ne '990b20728e48b06e51092e7a793cb8ba50e8636f0c95c60d847b9567a61a00cd') { throw 'Setup checksum mismatch. Stop and reopen the official setup guide; do not bypass this check.' }
        $options = @()
        if ($Mode -ne 'Install') { $options = @('-' + $Mode) }
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $s @options
        if ($LASTEXITCODE -ne 0) { throw 'WS2 setup did not finish successfully. Read the recovery message above, fix it, then rerun.' }
    } finally {
        if (Test-Path -LiteralPath $s) { Remove-Item -LiteralPath $s }
    }
} Install
```

**What it does:** downloads the public script to a unique temporary file, checks
its exact **SHA-256**, and runs only those verified bytes in a child PowerShell.
The child-only execution setting does **not** change the user/machine execution
policy or override Group Policy. The temporary script is removed afterward.
WinGet retains normal package hash/signature checks; no TLS checks are disabled.

| Mode | How to use the same command | Expected result |
| --- | --- | --- |
| Install | Keep the final word **Install** | Install only missing tools/extensions; verify every result |
| Preview | Replace only the final word with **Plan** | List missing tools and blocking version conflicts; no installs |
| Recheck | Replace only the final word with **Check** | Read-only readiness check; nonzero exit if anything is missing/wrong |

The launcher downloads the script in every mode. The script's own **Plan/Check**
modes do not download/install packages, sign in or call Azure services. If you
already have a reviewed local copy, its CLI switches are **-Plan** (alias
**-WhatIf**) and **-Check**. Do not run Install from an elevated terminal.

## What gets installed

| Tool | Version policy | Purpose |
| --- | --- | --- |
| Git for Windows + Git Credential Manager | Reuse working Git 2.x; current official package if missing | Clone, commit, push and trusted browser authentication |
| Desktop Visual Studio Code | Reuse installed release; current stable if missing | Editor, terminal and extensions |
| Node.js + npm | **24.16.0** | All eight labs' helpers; verifies bundled npm too |
| Terraform CLI | **1.16.1** | Labs 02–08 and isolated Terraform companions |
| terraform-docs | **0.24.0** | Lab 04's exact documentation output |
| actionlint | **1.7.12** | Optional local GitHub Actions workflow linting |
| GitHub CLI | Reuse working release; current if missing | Convenient GitHub operations; browser/Git remain valid alternatives |
| Azure CLI | Reuse working release; current if missing | Later participant account checks and instructor-approved Azure work |

The complete bundle deliberately includes later-lab tools now, even when your
first lab does not need them. GitHub CLI and actionlint are conveniences, not new
grading requirements. PowerShell 5.1 is already part of Windows; no PowerShell 7,
Azure PowerShell, Docker, Python, Bicep, azd or global npm packages are required.

**VS Code extensions, installed in the Default profile:**

| Extension | Verified Marketplace identifier |
| --- | --- |
| GitHub Copilot Chat | `GitHub.copilot-chat` |
| GitHub Pull Requests | `GitHub.vscode-pull-request-github` |
| HashiCorp Terraform | `HashiCorp.terraform` |
| GitHub Actions | `GitHub.vscode-github-actions` |
| PowerShell | `ms-vscode.PowerShell` |
| YAML | `redhat.vscode-yaml` |

Compatible installed extensions are reused, not force-upgraded. Newer VS Code
can **bundle Copilot Chat** without listing it among user-installed extensions.
Setup verifies the active editor's bundled GitHub manifest and entry point and
reuses that copy; a fresh editor is rechecked before installing any duplicate.
The result is six available extensions, sometimes only five additional installs.
**Install** uses
VS Code's normal Marketplace CLI; its **--force** flag suppresses the named
extension installation prompt, not an organization policy or package hash check.
The installer verifies their presence, not whether you have manually disabled them.
Use **Default** when first opening VS Code. Advanced users can supply
**-VSCodeProfile "EXISTING PROFILE NAME"** to the reviewed local installer (or
after **-File $s** inside the launcher) to target an existing named profile.
Profile names here must start with a letter, digit or underscore and contain
only letters, digits, spaces, dots, underscores or hyphens (maximum 100 characters).
Shell metacharacters are rejected; use Default or the editor UI for other names.
This prepares the local desktop editor, not separate WSL/SSH/container hosts.

**Not pre-installed:** AzureRM/AzAPI providers and AVM modules are repository
dependencies, not desktop applications. The existing lab helpers fetch their
locked versions when needed with backend-disabled initialization. That needs
internet access; workstation readiness does not mean fully air-gapped labs.
The baseline remains **AzureRM 5.4.0**; isolated companions keep their own locks.
Setup never initializes any repository, backend or state.

## 3. Expect READY, then reopen VS Code

Success ends with **READY: 8 local tools … and 6 extensions verified** and exit
code **0**. Missing tools, wrong versions, package errors or missing extensions
must not be ignored; a preview is not a successful installation.

1. **Save and close all VS Code windows and PowerShell terminals**, then reopen
   desktop VS Code. Windows applications can retain an old PATH; if it still
   differs after reopening, sign out of Windows and back in when convenient.
2. In VS Code's **Extensions** view, ensure the installed workshop extensions
   are enabled in the **Default** profile. Follow any legitimate editor reload prompt.
3. Complete the remaining personal-account steps **before workshop time**:
   GitHub account/email, required organization invitation/SSO/MFA and the assigned
   Copilot entitlement. Sign in through VS Code **Accounts → GitHub Copilot**.
   Git Credential Manager can require its own trusted browser sign-in when cloning.
4. Open the [laboratory catalogue](../README.md#choose-a-laboratory), create/reuse
   **your own Private copy**, then clone **your copy's** HTTPS URL in VS Code.
   Do not clone the public template/catalogue as your graded learner repository.
5. Follow that copy's short setup for **repository-local commit authorship**,
   its read-only doctor and the automatically maintained **Exercise** issue.
   The software installation sections can now be skipped unless a check fails.

**Installation cannot create accounts, assign a Copilot seat, consent to MFA,
grant repository access or authorize Azure.** The script changes no Git author,
credential cache, default Azure subscription, permissions or cloud resources.
It does not automatically open a browser/editor, clone a repository, start a lab
or mark Exercise progress. Azure sign-in and any live work stay instructor-gated.

## Recovery without starting over

| Problem | Next action |
| --- | --- |
| WinGet missing/too old | Update Microsoft App Installer through your approved channel; reopen PowerShell |
| Existing Node/Terraform/docs/actionlint has another version | Stop for an approved version/PATH correction; the script never silently downgrades/uninstalls it |
| Install reports success but tool is absent/wrong | Reopen terminals; check persistent machine/user PATH precedence with IT, not a temporary PATH workaround |
| UAC denied, IT restriction, download/proxy failure | Fix the stated restriction/connectivity, then rerun the same command; completed tools are reused |
| Reboot-required/nonzero installer code | Finish the approved reboot/recovery, then rerun; no automatic restart or false READY |
| VS Code/extension mismatch | Update VS Code through the approved channel and select the intended profile; do not disable extension policies |
| Node works but PowerShell blocks the npm script shim | Use **npm.cmd** when a lab asks for npm, or run the documented Node helper; do not weaken system policy |
| Hash mismatch or expired copied bootstrap | Reopen this official guide; never delete its hash check or substitute a random mirror |

Only the normal package installers make their required application/PATH changes.
The script reconstructs PATH **in its child process** for checks, preserves the
machine-before-user order and restores the caller's session value. It never
rewrites registry PATH, changes shell profiles or removes an existing installation.

## Verification and official references

Authoring verification exercises actual PowerShell control flow with isolated
WinGet/VS Code stubs, real native exit/stderr fixtures and a real read-only local
preview. It is **not a clean-machine installation rehearsal** and does not prove
that a company's UAC, proxy, Store or extension policies allow installation.
The [Windows test workflow](../.github/workflows/setup-checks.yml) installs no
workshop software, requests no Azure/OIDC/state access and uses no cloud secrets.

[WinGet installation options](https://learn.microsoft.com/windows/package-manager/winget/install) ·
[VS Code extension CLI](https://code.visualstudio.com/docs/configure/command-line#_working-with-extensions) ·
[Azure CLI Windows installation](https://learn.microsoft.com/cli/azure/install-azure-cli-windows) ·
[Node 24.16.0](https://nodejs.org/dist/v24.16.0/) ·
[Terraform 1.16.1](https://releases.hashicorp.com/terraform/1.16.1/) ·
[terraform-docs 0.24.0](https://github.com/terraform-docs/terraform-docs/releases/tag/v0.24.0) ·
[actionlint 1.7.12](https://github.com/rhysd/actionlint/releases/tag/v1.7.12)
