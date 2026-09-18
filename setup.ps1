#requires -Version 5.1
<#
.SYNOPSIS
Prepare the local Windows x64 tools for all eight AgentAlvine WS2 labs.
.DESCRIPTION
Uses the official WinGet source and VS Code Marketplace. Existing compatible
tools are reused, never silently upgraded/downgraded. No login, Git configuration,
repository clone, Terraform initialization, Azure API or persistent policy edit.
.PARAMETER Check
Check installed tools and extensions only. Exit 1 if anything is missing/wrong.
.PARAMETER Plan
Preview missing packages/extensions only; no installs or network lookups.
.PARAMETER VSCodeProfile
An EXISTING named VS Code profile to prepare; omit for the Default profile.
#>
[CmdletBinding(DefaultParameterSetName = 'Install')]
param(
    [Parameter(ParameterSetName = 'Check', Mandatory = $true)]
    [switch] $Check,
    [Parameter(ParameterSetName = 'Plan', Mandatory = $true)]
    [Alias('WhatIf')]
    [switch] $Plan,
    [ValidatePattern('^(?:[a-zA-Z0-9_][a-zA-Z0-9_. -]{0,99})?$')]
    [string] $VSCodeProfile
)

function Get-WS2Tools {
    # PackageVersion is WinGet's EXACT spelling, not necessarily the CLI version.
    @(
        @{ Name = 'Git'; Id = 'Git.Git'; Command = 'git.exe'; Args = @('--version'); Pattern = 'git version (2\.\d+\.\d+)'; Version = ''; PackageVersion = ''; Scope = ''; Extra = @('credential-manager', '--version') }
        @{ Name = 'VS Code'; Id = 'Microsoft.VisualStudioCode'; Command = 'code.cmd'; Args = @('--version'); Pattern = '(?m)^(\d+\.\d+\.\d+)\s*$'; Version = ''; PackageVersion = ''; Scope = 'user' }
        @{ Name = 'Node.js'; Id = 'OpenJS.NodeJS.LTS'; Command = 'node.exe'; Args = @('--version'); Pattern = '^v(\d+\.\d+\.\d+)\s*$'; Version = '24.16.0'; PackageVersion = '24.16.0'; Scope = '' }
        @{ Name = 'Terraform'; Id = 'Hashicorp.Terraform'; Command = 'terraform.exe'; Args = @('version', '-json'); Pattern = '"terraform_version"\s*:\s*"([^"]+)"'; Version = '1.16.1'; PackageVersion = '1.16.1'; Scope = 'user' }
        @{ Name = 'terraform-docs'; Id = 'Terraform-docs.Terraform-docs'; Command = 'terraform-docs.exe'; Args = @('version'); Pattern = 'terraform-docs version v(\d+\.\d+\.\d+)(?:\s|$)'; Version = '0.24.0'; PackageVersion = 'v0.24.0'; Scope = 'user' }
        @{ Name = 'actionlint'; Id = 'rhysd.actionlint'; Command = 'actionlint.exe'; Args = @('-version'); Pattern = '(?m)^v?(\d+\.\d+\.\d+)\s*$'; Version = '1.7.12'; PackageVersion = '1.7.12'; Scope = 'user' }
        @{ Name = 'GitHub CLI'; Id = 'GitHub.cli'; Command = 'gh.exe'; Args = @('--version'); Pattern = 'gh version (\d+\.\d+\.\d+)'; Version = ''; PackageVersion = ''; Scope = '' }
        @{ Name = 'Azure CLI'; Id = 'Microsoft.AzureCLI'; Command = 'az.cmd'; Args = @('version', '--output', 'json'); Pattern = '"azure-cli"\s*:\s*"([^"]+)"'; Version = ''; PackageVersion = ''; Scope = '' }
    )
}

function Get-WS2Extensions {
    @('GitHub.copilot-chat', 'GitHub.vscode-pull-request-github',
      'HashiCorp.terraform', 'GitHub.vscode-github-actions',
      'ms-vscode.PowerShell', 'redhat.vscode-yaml')
}

function Get-WS2Host {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    try {
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        @{
            Windows = ($env:OS -eq 'Windows_NT')
            Build = [Environment]::OSVersion.Version.Build
            Architecture = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE')
            NativeArchitecture = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITEW6432')
            Is64Bit = [Environment]::Is64BitProcess
            Elevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
    } finally { $identity.Dispose() }
}

function Assert-WS2Host {
    param([switch] $Installing)
    if ($env:OS -ne 'Windows_NT') { throw 'Use the manual toolchain guide on macOS/Linux; this installer is Windows only.' }
    $hostInfo = Get-WS2Host
    if (-not $hostInfo.Windows -or $hostInfo.Build -lt 19045) {
        throw 'Use supported Windows 11, or IT-supported Windows 10 22H2 (ESU). Older Windows is not supported.'
    }
    if (-not $hostInfo.Is64Bit -or $hostInfo.Architecture -ne 'AMD64' -or
        ($hostInfo.NativeArchitecture -and $hostInfo.NativeArchitecture -ne 'AMD64')) {
        throw 'This bundle requires native Windows x64 and 64-bit PowerShell. ARM64/32-bit: use the manual architecture-specific guide; do not substitute pinned versions.'
    }
    if ($Installing -and $hostInfo.Elevated) {
        throw 'Start a NORMAL, non-administrator PowerShell as the participant. Individual installers may request UAC; VS Code extensions must belong to your own user.'
    }
}

function Get-WS2PersistentPath {
    # Validate what a NEW terminal will receive, not a temporary authoring PATH.
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    [Environment]::ExpandEnvironmentVariables(($machine, $user -join ';'))
}

function Find-WS2Executable {
    param([string] $Name)
    $found = Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($found) { $found.Source }
}

function Invoke-WS2Native {
    param([string] $File, [string[]] $Arguments)
    # Windows PowerShell treats native stderr as ErrorRecords. Capture it without
    # mistaking a warning for a failed process, then inspect the real exit code.
    $ErrorActionPreference = 'Continue'
    # Native execution updates the GLOBAL automatic variable in Windows PS 5.1;
    # a local variable of the same name would shadow the real result.
    $previousExit = $global:LASTEXITCODE
    try {
        $global:LASTEXITCODE = -1
        $output = @(& $File @Arguments 2>&1)
        $result = $global:LASTEXITCODE
    } catch {
        return [pscustomobject] @{ ExitCode = -1; Output = $_.Exception.Message }
    } finally { $global:LASTEXITCODE = $previousExit }
    [pscustomobject] @{ ExitCode = $result; Output = ($output | Out-String).Trim() }
}

function Get-WS2ToolState {
    param([hashtable] $Tool)
    $file = Find-WS2Executable $Tool.Command
    if (-not $file) { return [pscustomobject] @{ Status = 'MISSING'; Detail = 'Not on the persistent Windows PATH'; Tool = $Tool } }
    $result = Invoke-WS2Native $file $Tool.Args
    $version = $null
    if ($result.ExitCode -eq 0 -and $result.Output -match $Tool.Pattern) { $version = $Matches[1] }
    if (-not $version -or ($Tool.Version -and $version -ne $Tool.Version)) {
        $expected = if ($Tool.Version) { $Tool.Version } else { 'a working supported release' }
        return [pscustomobject] @{ Status = 'CONFLICT'; Detail = "Need $expected; found '$version' at $file (exit $($result.ExitCode)). Resolve with IT; no automatic replacement."; Tool = $Tool }
    }
    if ($Tool.Extra) {
        $extra = Invoke-WS2Native $file $Tool.Extra
        if ($extra.ExitCode -ne 0 -or $extra.Output -notmatch '\d+\.\d+') {
            return [pscustomobject] @{ Status = 'CONFLICT'; Detail = 'Git Credential Manager is missing/broken. Repair Git with its official installer; no credential settings were changed.'; Tool = $Tool }
        }
    }
    if ($Tool.Id -eq 'OpenJS.NodeJS.LTS') {
        $npm = Find-WS2Executable 'npm.cmd'
        if (-not $npm) { return [pscustomobject] @{ Status = 'CONFLICT'; Detail = 'Node is present but bundled npm.cmd is missing; repair the official Node installation.'; Tool = $Tool } }
        $npmVersion = Invoke-WS2Native $npm @('--version')
        if ($npmVersion.ExitCode -ne 0 -or $npmVersion.Output -notmatch '^\d+\.\d+\.\d+\s*$') {
            return [pscustomobject] @{ Status = 'CONFLICT'; Detail = 'Bundled npm.cmd failed its version check; repair Node before continuing.'; Tool = $Tool }
        }
    }
    [pscustomobject] @{ Status = 'OK'; Detail = $version; Tool = $Tool }
}

function Get-WS2ExtensionArguments {
    param([string[]] $Arguments, [string] $Profile)
    if ($Profile) { @($Arguments) + @('--profile', $Profile) } else { @($Arguments) }
}

function Get-WS2BundledExtensions {
    param([string] $Code)
    # --list-extensions and --locate-extension omit system-bundled Copilot.
    # Read ONLY the app selected by this official Windows launcher, never an old
    # sibling build, another Code installation or a user-supplied extension folder.
    if (-not [IO.File]::Exists($Code)) { return @() }
    $launcher = [IO.File]::ReadAllText($Code)
    $match = [regex]::Match($launcher, '"%~dp0(?<relative>\.\.\\(?:[a-f0-9]{8,40}\\)?resources\\app)\\out\\cli\.js"', 'IgnoreCase')
    if (-not $match.Success) { return @() }
    $app = [IO.Path]::GetFullPath([IO.Path]::Combine([IO.Path]::GetDirectoryName($Code), $match.Groups['relative'].Value))
    foreach ($folder in @('copilot', 'github.copilot-chat')) {
        $directory = Join-Path $app ('extensions\' + $folder)
        $manifest = Join-Path $directory 'package.json'
        if (-not [IO.File]::Exists($manifest)) { continue }
        try { $package = [IO.File]::ReadAllText($manifest) | ConvertFrom-Json }
        catch { throw 'The active VS Code bundled Copilot manifest is unreadable. Repair/update VS Code through the approved channel.' }
        if ($package.publisher -ne 'GitHub' -or $package.name -ne 'copilot-chat' -or
            $package.version -notmatch '^\d+\.\d+\.\d+(?:[-+].+)?$' -or
            -not ($package.main -is [string]) -or $package.main -notmatch '^(?:\./)?[a-zA-Z0-9_/-]+(?:\.js)?$' -or
            $package.main.StartsWith('/')) {
            throw 'Unexpected bundled Copilot identity/entry point. Repair/update VS Code; do not count an unknown extension as ready.'
        }
        $entry = Join-Path $directory $package.main
        if (-not [IO.File]::Exists($entry) -and -not [IO.File]::Exists($entry + '.js')) {
            throw 'The active VS Code bundled Copilot entry point is missing. Repair/update VS Code before continuing.'
        }
        return @('github.copilot-chat')
    }
    @()
}

function Get-WS2InstalledExtensions {
    param([string] $Code, [string] $Profile)
    $arguments = Get-WS2ExtensionArguments @('--list-extensions', '--show-versions') $Profile
    $result = Invoke-WS2Native $Code $arguments
    if ($result.ExitCode -ne 0) { throw "VS Code could not list extensions (exit $($result.ExitCode)). Check the existing profile, policy and editor installation." }
    $userExtensions = @($result.Output -split '\r?\n' | ForEach-Object {
        if ($_ -match '^([a-z0-9][a-z0-9.-]+\.[a-z0-9][a-z0-9.-]+)@\S+$') { $Matches[1].ToLowerInvariant() }
    })
    @($userExtensions + @(Get-WS2BundledExtensions $Code) | Select-Object -Unique)
}

function Get-WS2WingetArguments {
    param([hashtable] $Tool, [ValidateSet('show', 'install')] [string] $Operation)
    $arguments = @($Operation, '--id', $Tool.Id, '--exact', '--source', 'winget',
        '--accept-source-agreements', '--disable-interactivity')
    if ($Tool.PackageVersion) { $arguments += @('--version', $Tool.PackageVersion) }
    if ($Operation -eq 'install') {
        $arguments += @('--architecture', 'x64', '--silent', '--accept-package-agreements', '--no-upgrade')
        if ($Tool.Scope) { $arguments += @('--scope', $Tool.Scope) }
    }
    $arguments
}

function Assert-WS2Winget {
    $winget = Find-WS2Executable 'winget.exe'
    if (-not $winget) { throw 'WinGet is missing. Install/update Microsoft App Installer from https://apps.microsoft.com/detail/9NBLGGH4NNS1 (or ask IT), reopen PowerShell and rerun. Nothing was installed.' }
    $result = Invoke-WS2Native $winget @('--version')
    if ($result.ExitCode -ne 0 -or $result.Output -notmatch '^v?(\d+\.\d+\.\d+)(?:\s|$)' -or
        [version] $Matches[1] -lt [version] '1.9.0') {
        throw 'WinGet 1.9+ is required. Update Microsoft App Installer through the approved process; no alternate package manager or policy bypass is used.'
    }
    $winget
}

function Install-WS2Package {
    param([hashtable] $Tool, [string] $Winget)
    Write-Host "INSTALL $($Tool.Name) ($($Tool.Id) $($Tool.PackageVersion))"
    $arguments = Get-WS2WingetArguments $Tool 'install'
    $result = Invoke-WS2Native $Winget $arguments
    # WinGet/vendor installers own their normal PATH updates; never overwrite it.
    $env:Path = Get-WS2PersistentPath
    if ($result.ExitCode -ne 0) {
        Write-Host $result.Output
        throw "$($Tool.Name) installation stopped (exit $($result.ExitCode)). Complete any requested IT/UAC/reboot action, then rerun. Completed tools are retained; no automatic restart, downgrade or rollback."
    }
    $state = Get-WS2ToolState $Tool
    if ($state.Status -ne 'OK') { throw "$($Tool.Name) did not pass its post-install check: $($state.Detail). Close all terminals/VS Code, reopen and rerun; do not ignore PATH/version conflicts." }
    Write-Host "PASS $($Tool.Name) $($state.Detail)"
}

function Invoke-WS2Setup {
    param(
        [switch] $CheckOnly,
        [switch] $Preview,
        # code.cmd has a cmd.exe boundary; reject shell metacharacters, not just
        # control characters, rather than rely on function-stub argument quoting.
        [ValidatePattern('^(?:[a-zA-Z0-9_][a-zA-Z0-9_. -]{0,99})?$')]
        [string] $Profile
    )
    $ErrorActionPreference = 'Stop'
    Assert-WS2Host -Installing:(-not $CheckOnly -and -not $Preview)
    $originalPath = $env:Path
    try {
        $env:Path = Get-WS2PersistentPath
        Write-Host 'AgentAlvine WS2 | all eight labs | Windows x64'
        Write-Host 'Checks use the persistent Windows PATH. No login, clone, Git identity or Azure access.'
        $tools = @(Get-WS2Tools)
        $states = @($tools | ForEach-Object { Get-WS2ToolState $_ })
        foreach ($state in $states) { Write-Host "$($state.Status) $($state.Tool.Name): $($state.Detail)" }
        $conflicts = @($states | Where-Object { $_.Status -eq 'CONFLICT' })
        $missing = @($states | Where-Object { $_.Status -eq 'MISSING' })
        $code = Find-WS2Executable 'code.cmd'
        $installed = @()
        if ($code) { $installed = @(Get-WS2InstalledExtensions $code $Profile) }
        $extensions = @(Get-WS2Extensions)
        $needed = @($extensions | Where-Object { $installed -notcontains $_.ToLowerInvariant() })
        foreach ($extension in $extensions) {
            $status = if ($needed -contains $extension) { 'MISSING' } else { 'OK' }
            Write-Host "$status extension: $extension"
        }
        if ($Preview) {
            Write-Host "PLAN ONLY: $($missing.Count) missing tools, $($needed.Count) missing extensions, $($conflicts.Count) blocking conflicts. No installs, downloads or persistent configuration changes."
            return 0
        }
        if ($CheckOnly) {
            if ($missing.Count -or $conflicts.Count -or $needed.Count) { Write-Host 'NOT READY: fix the listed items, then rerun setup or -Check.'; return 1 }
        } else {
            if ($conflicts.Count) { throw 'Resolve the listed version/broken-install conflicts first. No packages or extensions were installed; existing tools were not replaced.' }
            if ($missing.Count) {
                $winget = Assert-WS2Winget
                # Verify every requested package/version exists before the first install.
                foreach ($state in $missing) {
                    $arguments = Get-WS2WingetArguments $state.Tool 'show'
                    $availability = Invoke-WS2Native $winget $arguments
                    if ($availability.ExitCode -ne 0) { throw "WinGet cannot resolve $($state.Tool.Id) $($state.Tool.PackageVersion) (exit $($availability.ExitCode)). Check connectivity/source/IT policy. Nothing installed; no latest-version fallback." }
                }
                foreach ($state in $missing) { Install-WS2Package $state.Tool $winget }
            }
            $code = Find-WS2Executable 'code.cmd'
            if (-not $code) { throw 'VS Code is not available on the persistent PATH. Reopen PowerShell after installation; do not continue with missing extensions.' }
            # A just-installed VS Code may already supply bundled Copilot.
            $installed = @(Get-WS2InstalledExtensions $code $Profile)
            $needed = @($extensions | Where-Object { $installed -notcontains $_.ToLowerInvariant() })
            foreach ($extension in $needed) {
                Write-Host "INSTALL extension: $extension"
                $arguments = Get-WS2ExtensionArguments @('--install-extension', $extension, '--force') $Profile
                $result = Invoke-WS2Native $code $arguments
                if ($result.ExitCode -ne 0) { Write-Host $result.Output; throw "Extension $extension failed (exit $($result.ExitCode)). Check Marketplace access, approved VS Code version and extension policy; rerun without disabling controls." }
            }
        }
        # Never interpret WinGet/code exit 0 alone as proof of installation.
        foreach ($tool in $tools) {
            $state = Get-WS2ToolState $tool
            if ($state.Status -ne 'OK') { throw "Final check failed for $($tool.Name): $($state.Detail)" }
        }
        $installed = @(Get-WS2InstalledExtensions $code $Profile)
        foreach ($extension in $extensions) {
            if ($installed -notcontains $extension.ToLowerInvariant()) { throw "Final check: extension $extension is still missing from the chosen profile. Setup is NOT ready." }
        }
        Write-Host "READY: $($tools.Count) local tools (including npm/Git Credential Manager checks) and $($extensions.Count) extensions verified."
        Write-Host 'Save and close ALL VS Code windows and terminals, then reopen VS Code (Default profile unless another was selected).'
        Write-Host 'Next: sign in with your own GitHub/Copilot account, create/reuse your private lab copy, clone it, set local Git authorship and follow its Exercise/doctor.'
        Write-Host 'A listed extension may still be disabled. Check it in VS Code; entitlement/MFA/push rights and instructor Azure approval are NOT certified by this check.'
        return 0
    } finally {
        # Do not mutate the caller's session PATH, registry, shell profile or policy.
        $env:Path = $originalPath
    }
}

# Dot-sourcing defines functions for isolated tests/review, with no installation.
if ($MyInvocation.InvocationName -ne '.') {
    try { exit (Invoke-WS2Setup -CheckOnly:$Check -Preview:$Plan -Profile $VSCodeProfile) }
    catch { [Console]::Error.WriteLine("SETUP STOPPED: $($_.Exception.Message)"); exit 1 }
}
