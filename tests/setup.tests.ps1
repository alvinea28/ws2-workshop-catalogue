#requires -Version 5.1
# Deliberately no Pester/module download and no real installer/extension execution.
param([Parameter(Mandatory = $true)] [string] $NodeExecutable)
$ErrorActionPreference = 'Stop'
$installer = Join-Path $PSScriptRoot '..\setup.ps1'
$tokens = $null
$parseErrors = $null
$null = [Management.Automation.Language.Parser]::ParseFile($installer, [ref] $tokens, [ref] $parseErrors)
if (@($parseErrors).Count) { throw ($parseErrors | Out-String) }
. $installer
$nativeImplementation = ${function:Invoke-WS2Native}
$pathImplementation = ${function:Get-WS2PersistentPath}
$bundledImplementation = ${function:Get-WS2BundledExtensions}
$guide = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\docs\windows-setup.md'))
$bootstrap = [regex]::Match($guide, '(?s)```powershell\r?\n(.*?)\r?\n```').Groups[1].Value
if (-not $bootstrap -or $bootstrap -notmatch "-ne '([a-f0-9]{64})'") { throw 'Missing published bootstrap/hash' }
$bootstrapHash = $Matches[1]
$script:tools = @(Get-WS2Tools)
$script:extensions = @(Get-WS2Extensions)
$script:calls = New-Object 'System.Collections.Generic.List[object]'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}
function Assert-Stops {
    param([scriptblock] $Action, [string] $Message)
    $caught = $null
    try { $null = & $Action } catch { $caught = $_.Exception.Message }
    Assert-True ($null -ne $caught -and $caught -match $Message) "Expected stop matching '$Message'; actual '$caught'"
}
function Reset-Mocks {
    $script:calls.Clear()
    $script:installed = @{}
    foreach ($tool in $script:tools) {
        $version = if ($tool.Version) { $tool.Version } else { '2.99.0' }
        if ($tool.Id -eq 'Microsoft.VisualStudioCode') { $version = '1.138.0' }
        $script:installed[$tool.Id] = $version
    }
    $script:installedExtensions = @($script:extensions)
    $script:bundledExtensions = @()
    $script:bundleAfterCodeInstall = $false
    $script:hostInfo = @{ Windows = $true; Build = 26100; Architecture = 'AMD64'; NativeArchitecture = ''; Is64Bit = $true; Elevated = $false }
    $script:wingetExists = $true
    $script:wingetVersion = 'v1.29.290'
    $script:npmExists = $true
    $script:gcmExists = $true
    $script:badVersionOutput = ''
    $script:unavailable = ''
    $script:failedPackage = ''
    $script:packageExit = 1603
    $script:invisibleAfterInstall = ''
    $script:wrongAfterInstall = ''
    $script:failedExtension = ''
    $script:ghostExtension = ''
    $script:listFailure = $false
    $script:downloaded = $false
    $script:downloadFailure = ''
    $script:hashMismatch = $false
    $script:childExit = 0
    $script:bootstrapEvents = @()
    $script:childOptions = @{}
}
function Get-WS2Host { $script:hostInfo }
function Get-WS2PersistentPath { 'C:\Existing Machine Tools;C:\Existing User Tools' }
function Get-WS2BundledExtensions { param([string] $Code); $script:bundledExtensions }
function Find-WS2Executable {
    param([string] $Name)
    if ($Name -eq 'winget.exe') { if ($script:wingetExists) { $Name }; return }
    if ($Name -eq 'npm.cmd') { if ($script:npmExists -and $script:installed.ContainsKey('OpenJS.NodeJS.LTS')) { $Name }; return }
    $tool = @($script:tools | Where-Object { $_.Command -eq $Name })
    if ($tool.Count -ne 1) { throw "Unexpected executable lookup: $Name" }
    if ($script:installed.ContainsKey($tool[0].Id) -and $script:invisibleAfterInstall -ne $tool[0].Id) { $Name }
}
function Invoke-WS2Native {
    param([string] $File, [string[]] $Arguments)
    $script:calls.Add([pscustomobject] @{ File = $File; Arguments = @($Arguments) })
    $exitCode = 0
    $output = ''
    if ($File -eq 'winget.exe') {
        if ($Arguments[0] -eq '--version') { $output = $script:wingetVersion }
        elseif ($Arguments[0] -in @('show', 'install')) {
            $id = $Arguments[[Array]::IndexOf($Arguments, '--id') + 1]
            $tool = @($script:tools | Where-Object { $_.Id -eq $id })
            Assert-True ($tool.Count -eq 1) 'Unknown package must not execute'
            if ($Arguments[0] -eq 'show') {
                if ($id -eq $script:unavailable) { $exitCode = -1978335212 } else { $output = "Found $id" }
            } elseif ($id -eq $script:failedPackage) { $exitCode = $script:packageExit }
            else {
                $version = if ($tool[0].Version) { $tool[0].Version } else { '2.99.0' }
                if ($id -eq 'Microsoft.VisualStudioCode') { $version = '1.138.0' }
                if ($id -eq $script:wrongAfterInstall) { $version = '0.0.1' }
                $script:installed[$id] = $version
                if ($id -eq 'OpenJS.NodeJS.LTS') { $script:npmExists = $true }
                if ($id -eq 'Microsoft.VisualStudioCode' -and $script:bundleAfterCodeInstall) { $script:bundledExtensions = @('github.copilot-chat') }
            }
        } else { throw "Unexpected WinGet command: $Arguments" }
    } elseif ($File -eq 'code.cmd' -and $Arguments[0] -eq '--list-extensions') {
        if ($script:listFailure) { $exitCode = 1 }
        else { $output = ($script:installedExtensions | ForEach-Object { "$_@1.2.3" }) -join "`n" }
    } elseif ($File -eq 'code.cmd' -and $Arguments[0] -eq '--install-extension') {
        $id = $Arguments[1]
        Assert-True ($script:extensions -contains $id) 'Unknown extension must not execute'
        if ($id -eq $script:failedExtension) { $exitCode = 9 }
        elseif ($id -ne $script:ghostExtension) { $script:installedExtensions += $id }
    } elseif ($File -eq 'npm.cmd') { $output = '11.9.0' }
    elseif ($File -eq 'git.exe' -and $Arguments[0] -eq 'credential-manager') {
        if ($script:gcmExists) { $output = '2.9.0' } else { $exitCode = 1 }
    } else {
        $tool = @($script:tools | Where-Object { $_.Command -eq $File })
        Assert-True ($tool.Count -eq 1) "Unmocked command blocked: $File"
        $version = $script:installed[$tool[0].Id]
        switch ($File) {
            'git.exe' { $output = "git version $version.windows.1" }
            'code.cmd' { $output = "$version`n0123456789abcdef`nx64" }
            'node.exe' { $output = "v$version" }
            'terraform.exe' { $output = '{"terraform_version":"' + $version + '","platform":"windows_amd64"}' }
            'terraform-docs.exe' { $output = "terraform-docs version v$version windows/amd64" }
            'actionlint.exe' { $output = "$version`nInstalled by test stub" }
            'gh.exe' { $output = "gh version $version (2026-09-18)" }
            'az.cmd' { $output = '{"azure-cli":"' + $version + '"}' }
            default { throw "Unmocked native operation blocked: $File $Arguments" }
        }
        if ($script:badVersionOutput -eq $tool[0].Id) { $output = 'unparseable'; $exitCode = 4 }
    }
    [pscustomobject] @{ ExitCode = $exitCode; Output = $output }
}
function Get-InstallCalls {
    @($script:calls | Where-Object { $_.Arguments[0] -in @('install', '--install-extension') })
}
function Assert-NoInstalls {
    Assert-True (@(Get-InstallCalls).Count -eq 0) 'Read-only/preflight failure executed a mutation'
}

# All bootstrap boundary operations are stubs. No downloaded script is executed.
function Invoke-WebRequest {
    param([switch] $UseBasicParsing, [int] $TimeoutSec, [string] $Uri, [string] $OutFile)
    Assert-True ($Uri -ceq 'https://raw.githubusercontent.com/alvinea28/ws2-workshop-catalogue/dev/setup.ps1') 'Unexpected download source'
    Assert-True ($UseBasicParsing -and $TimeoutSec -eq 120) 'Missing compatible bounded web request'
    Assert-True ($OutFile -match 'ws2-setup-[a-f0-9-]+\.ps1$') 'Temporary filename is not unique'
    $script:bootstrapEvents += 'download'
    if ($script:downloadFailure -eq 'before-file') { throw 'Simulated download failure' }
    $script:downloaded = $true
    if ($script:downloadFailure -eq 'partial-file') { throw 'Simulated partial download failure' }
}
function Get-FileHash {
    param([string] $LiteralPath, [string] $Algorithm)
    Assert-True ($Algorithm -eq 'SHA256' -and $LiteralPath -match 'ws2-setup-') 'Wrong hash verification'
    $script:bootstrapEvents += 'hash'
    $hash = if ($script:hashMismatch) { '0' * 64 } else { $bootstrapHash }
    [pscustomobject] @{ Hash = $hash }
}
function powershell.exe {
    param([switch] $NoProfile, [string] $ExecutionPolicy, [string] $File, [switch] $Plan, [switch] $Check)
    Assert-True ($NoProfile -and $ExecutionPolicy -eq 'Bypass') 'Wrong child-shell options'
    Assert-True ($File -match 'ws2-setup-' -and $script:bootstrapEvents[-1] -eq 'hash') 'Child launched before hash verification'
    $script:bootstrapEvents += 'child'
    # Array-splatted native tokens are positional $args to a FUNCTION stub;
    # the real powershell.exe -File parser binds them as named script switches.
    Assert-True (@($args | Where-Object { $_ -notin @('-Plan', '-Check') }).Count -eq 0) 'Unexpected child token'
    $script:childOptions = @{ Plan = ([bool] $Plan -or $args -contains '-Plan'); Check = ([bool] $Check -or $args -contains '-Check') }
    $global:LASTEXITCODE = $script:childExit
}
function Test-Path {
    param([string] $LiteralPath)
    Assert-True ($LiteralPath -match 'ws2-setup-') 'Unexpected bootstrap file probe'
    $script:downloaded
}
function Remove-Item {
    param([string] $LiteralPath)
    Assert-True ($LiteralPath -match 'ws2-setup-') 'Cleanup targets an unrelated path'
    $script:bootstrapEvents += 'cleanup'
    $script:downloaded = $false
}
function Invoke-TestBootstrap {
    param([ValidateSet('Install', 'Plan', 'Check')] [string] $Mode)
    $code = $bootstrap -replace '\} Install\s*$', ('} ' + $Mode)
    & ([scriptblock]::Create($code))
}

function Test-WithCodeBundle {
    param([string] $Build, [scriptblock] $Action)
    $directory = Join-Path ([IO.Path]::GetTempPath()) ('WS2 bundle fixture ' + [guid]::NewGuid())
    try {
        $bin = Join-Path $directory 'bin'
        $relative = if ($Build) { "..\$Build\resources\app" } else { '..\resources\app' }
        $app = [IO.Path]::GetFullPath([IO.Path]::Combine($bin, $relative))
        $extension = Join-Path $app 'extensions\copilot'
        $null = [IO.Directory]::CreateDirectory($bin)
        $null = [IO.Directory]::CreateDirectory((Join-Path $extension 'dist'))
        $code = Join-Path $bin 'code.cmd'
        [IO.File]::WriteAllText($code, ('@echo off' + "`n" + '"%~dp0..\Code.exe" "%~dp0' + $relative + '\out\cli.js" %*'))
        $manifest = Join-Path $extension 'package.json'
        [IO.File]::WriteAllText($manifest, '{"publisher":"GitHub","name":"copilot-chat","version":"0.51.2","main":"./dist/extension"}')
        $entry = Join-Path $extension 'dist\extension.js'
        [IO.File]::WriteAllText($entry, '// Synthetic fixture: never execute or load as an extension.')
        & $Action $code $manifest $entry
    } finally { if ([IO.Directory]::Exists($directory)) { [IO.Directory]::Delete($directory, $true) } }
}

$cases = [ordered] @{
    'fresh machine installs exact eight tools and six extensions' = {
        $script:installed.Clear(); $script:installedExtensions = @(); $script:npmExists = $false
        Assert-True ((Invoke-WS2Setup) -eq 0) 'Fresh install failed'
        Assert-True (@(Get-InstallCalls).Count -eq 14) 'Expected exactly eight packages plus six extensions'
        $shows = @($script:calls | Where-Object { $_.Arguments[0] -eq 'show' })
        Assert-True ($shows.Count -eq 8) 'All packages must be preflighted'
        foreach ($call in @(Get-InstallCalls | Where-Object { $_.File -eq 'winget.exe' })) {
            foreach ($flag in @('--exact', '--source', '--accept-source-agreements', '--accept-package-agreements', '--no-upgrade', '--silent', '--disable-interactivity')) {
                Assert-True ($call.Arguments -contains $flag) "Missing package safety flag $flag"
            }
            Assert-True ($call.Arguments -notcontains '--force') 'Forced package install is prohibited'
            $id = $call.Arguments[[Array]::IndexOf($call.Arguments, '--id') + 1]
            $tool = @($script:tools | Where-Object { $_.Id -eq $id })[0]
            if ($tool.PackageVersion) {
                Assert-True ($call.Arguments[[Array]::IndexOf($call.Arguments, '--version') + 1] -eq $tool.PackageVersion) "Wrong exact pin for $id"
            }
        }
    }
    'rerun reuses all tools and extensions without upgrades' = {
        Assert-True ((Invoke-WS2Setup) -eq 0) 'Rerun failed'
        Assert-NoInstalls
        Assert-True (@($script:calls | Where-Object { $_.File -eq 'winget.exe' }).Count -eq 0) 'No WinGet needed on rerun'
    }
    'check ready works without WinGet' = {
        $script:wingetExists = $false
        Assert-True ((Invoke-WS2Setup -CheckOnly) -eq 0) 'Ready check failed'
        Assert-NoInstalls
    }
    'check missing returns one without install' = {
        $script:installed.Remove('Hashicorp.Terraform')
        Assert-True ((Invoke-WS2Setup -CheckOnly) -eq 1) 'Missing tool falsely ready'
        Assert-NoInstalls
    }
    'check wrong version returns one without replacement' = {
        $script:installed['OpenJS.NodeJS.LTS'] = '24.19.0'
        Assert-True ((Invoke-WS2Setup -CheckOnly) -eq 1) 'Wrong version falsely ready'
        Assert-NoInstalls
    }
    'preview empty machine needs neither network nor WinGet' = {
        $script:installed.Clear(); $script:installedExtensions = @(); $script:wingetExists = $false
        Assert-True ((Invoke-WS2Setup -Preview) -eq 0) 'Preview failed'
        Assert-True ($script:calls.Count -eq 0) 'Empty preview invoked a command'
    }
    'preview reports conflicts without mutation' = {
        $script:installed['OpenJS.NodeJS.LTS'] = '22.0.0'
        Assert-True ((Invoke-WS2Setup -Preview) -eq 0) 'Conflict preview failed'
        Assert-NoInstalls
    }
    'version conflict stops before even a missing tool installs' = {
        $script:installed['OpenJS.NodeJS.LTS'] = '24.19.0'; $script:installed.Remove('Git.Git')
        Assert-Stops { Invoke-WS2Setup } 'conflicts first'
        Assert-NoInstalls
    }
    'broken native version command is not success' = {
        $script:badVersionOutput = 'Hashicorp.Terraform'
        Assert-Stops { Invoke-WS2Setup } 'conflicts first'
        Assert-NoInstalls
    }
    'Node without bundled npm blocks readiness' = {
        $script:npmExists = $false
        Assert-Stops { Invoke-WS2Setup } 'conflicts first'
        Assert-NoInstalls
    }
    'Git without Credential Manager blocks readiness' = {
        $script:gcmExists = $false
        Assert-Stops { Invoke-WS2Setup } 'conflicts first'
        Assert-NoInstalls
    }
    'missing WinGet gives App Installer recovery' = {
        $script:installed.Remove('Hashicorp.Terraform'); $script:wingetExists = $false
        Assert-Stops { Invoke-WS2Setup } 'Microsoft App Installer'
        Assert-NoInstalls
    }
    'old WinGet stops before install' = {
        $script:installed.Remove('Hashicorp.Terraform'); $script:wingetVersion = 'v1.8.0'
        Assert-Stops { Invoke-WS2Setup } 'WinGet 1.9'
        Assert-NoInstalls
    }
    'malformed WinGet version fails closed' = {
        $script:installed.Remove('Hashicorp.Terraform'); $script:wingetVersion = 'unknown'
        Assert-Stops { Invoke-WS2Setup } 'WinGet 1.9'
        Assert-NoInstalls
    }
    'unavailable exact package stops all installs' = {
        $script:installed.Remove('Git.Git'); $script:installed.Remove('Hashicorp.Terraform'); $script:unavailable = 'Hashicorp.Terraform'
        Assert-Stops { Invoke-WS2Setup } 'no latest-version fallback'
        Assert-NoInstalls
    }
    'failed package retains earlier success and resumes safely' = {
        $script:installed.Remove('Git.Git'); $script:installed.Remove('Hashicorp.Terraform'); $script:failedPackage = 'Hashicorp.Terraform'
        Assert-Stops { Invoke-WS2Setup } 'exit 1603'
        Assert-True ($script:installed.ContainsKey('Git.Git')) 'Earlier successful Git install was lost'
        $script:failedPackage = ''; $script:calls.Clear()
        Assert-True ((Invoke-WS2Setup) -eq 0) 'Resume failed'
        Assert-True (@(Get-InstallCalls).Count -eq 1) 'Resume reinstalled an already completed package'
    }
    'reboot-required status is not successful readiness' = {
        $script:installed.Remove('Hashicorp.Terraform'); $script:failedPackage = 'Hashicorp.Terraform'; $script:packageExit = 3010
        Assert-Stops { Invoke-WS2Setup } 'exit 3010'
        Assert-True (@($script:calls | Where-Object { $_.Arguments -contains '--allow-reboot' }).Count -eq 0) 'Automatic reboot requested'
    }
    'success exit with absent persistent PATH is rejected' = {
        $script:installed.Remove('Hashicorp.Terraform'); $script:invisibleAfterInstall = 'Hashicorp.Terraform'
        Assert-Stops { Invoke-WS2Setup } 'post-install check'
    }
    'wrong installed version is rejected even after exit zero' = {
        $script:installed.Remove('Hashicorp.Terraform'); $script:wrongAfterInstall = 'Hashicorp.Terraform'
        Assert-Stops { Invoke-WS2Setup } 'post-install check'
    }
    'extension installer failure is not ignored' = {
        $script:installedExtensions = @(); $script:failedExtension = $script:extensions[0]
        Assert-Stops { Invoke-WS2Setup } 'Extension.*failed'
    }
    'extension exit zero without installation fails readback' = {
        $script:installedExtensions = @(); $script:ghostExtension = $script:extensions[0]
        Assert-Stops { Invoke-WS2Setup } 'still missing'
    }
    'extension IDs are verified case insensitively' = {
        $script:installedExtensions = @($script:extensions | ForEach-Object { $_.ToUpperInvariant() })
        Assert-True ((Invoke-WS2Setup -CheckOnly) -eq 0) 'Extension ID casing broke verification'
        Assert-NoInstalls
    }
    'bundled Copilot satisfies readiness without a user extension' = {
        $script:installedExtensions = @($script:extensions | Where-Object { $_ -ne 'GitHub.copilot-chat' })
        $script:bundledExtensions = @('github.copilot-chat')
        Assert-True ((Invoke-WS2Setup -CheckOnly) -eq 0) 'A bundled Copilot was falsely missing'
        Assert-NoInstalls
    }
    'new VS Code bundle is rechecked before extension installation' = {
        $script:installed.Clear(); $script:installedExtensions = @(); $script:bundleAfterCodeInstall = $true
        Assert-True ((Invoke-WS2Setup) -eq 0) 'Fresh bundled setup failed'
        Assert-True (@(Get-InstallCalls).Count -eq 13) 'Expected eight tools and only five additional extensions'
        Assert-True (@(Get-InstallCalls | Where-Object { $_.Arguments -contains 'GitHub.copilot-chat' }).Count -eq 0) 'Attempted duplicate Copilot installation'
    }
    'versioned Code launcher proves active bundled Copilot identity' = {
        Test-WithCodeBundle 'abcdef1234' {
            param($code, $manifest, $entry)
            $found = @(& $bundledImplementation $code)
            Assert-True ($found.Count -eq 1 -and $found[0] -eq 'github.copilot-chat') 'Versioned bundle was not found'
        }
    }
    'legacy Code launcher proves bundled Copilot identity' = {
        Test-WithCodeBundle '' {
            param($code, $manifest, $entry)
            Assert-True ((@(& $bundledImplementation $code)) -contains 'github.copilot-chat') 'Legacy-layout bundle was not found'
        }
    }
    'stale bundle from another app build cannot satisfy readiness' = {
        Test-WithCodeBundle '' {
            param($code, $manifest, $entry)
            [IO.File]::WriteAllText($code, '"%~dp0..\Code.exe" "%~dp0..\deadbeef1234\resources\app\out\cli.js" %*')
            Assert-True (@(& $bundledImplementation $code).Count -eq 0) 'Unselected old bundle was incorrectly accepted'
        }
    }
    'wrong bundled extension publisher is rejected' = {
        Test-WithCodeBundle '' {
            param($code, $manifest, $entry)
            [IO.File]::WriteAllText($manifest, '{"publisher":"Other","name":"copilot-chat","version":"0.51.2","main":"./dist/extension"}')
            Assert-Stops { & $bundledImplementation $code } 'Unexpected bundled Copilot identity'
        }
    }
    'bundled manifest without executable entry point is rejected' = {
        Test-WithCodeBundle '' {
            param($code, $manifest, $entry)
            [IO.File]::Delete($entry)
            Assert-Stops { & $bundledImplementation $code } 'entry point is missing'
        }
    }
    'malformed bundled manifest is rejected' = {
        Test-WithCodeBundle '' {
            param($code, $manifest, $entry)
            [IO.File]::WriteAllText($manifest, '{invalid-json')
            Assert-Stops { & $bundledImplementation $code } 'manifest is unreadable'
        }
    }
    'existing named profile is passed as one literal argument' = {
        $profile = 'Workshop learning profile'
        Assert-True ((Invoke-WS2Setup -CheckOnly -Profile $profile) -eq 0) 'Named profile check failed'
        foreach ($call in @($script:calls | Where-Object { $_.Arguments[0] -eq '--list-extensions' })) {
            Assert-True ($call.Arguments[[Array]::IndexOf($call.Arguments, '--profile') + 1] -ceq $profile) 'Profile argument was split or evaluated'
        }
        Assert-NoInstalls
    }
    'profile shell metacharacters are rejected before native invocation' = {
        foreach ($profile in @('Workshop&whoami', 'Workshop|whoami', 'Workshop%USERPROFILE%', 'Workshop"quoted', 'abc^def', "bad`nprofile")) {
            Assert-Stops { Invoke-WS2Setup -Profile $profile } 'validate argument'
        }
        Assert-True ($script:calls.Count -eq 0) 'An unsafe profile reached a cmd.exe boundary'
    }
    'extension listing errors stop before installation' = {
        $script:listFailure = $true; $script:installed.Remove('Git.Git')
        Assert-Stops { Invoke-WS2Setup } 'could not list extensions'
        Assert-NoInstalls
    }
    'caller PATH is preserved on failure' = {
        $before = $env:Path; $script:listFailure = $true
        Assert-Stops { Invoke-WS2Setup } 'could not list extensions'
        Assert-True ($env:Path -ceq $before) 'Caller PATH changed on failure'
    }
    'native ARM64 is rejected before any invocation' = {
        $script:hostInfo.Architecture = 'ARM64'
        Assert-Stops { Invoke-WS2Setup } 'native Windows x64'
        Assert-True ($script:calls.Count -eq 0) 'Unsupported architecture executed commands'
    }
    'x64 emulation on ARM64 is rejected' = {
        $script:hostInfo.NativeArchitecture = 'ARM64'
        Assert-Stops { Invoke-WS2Setup } 'native Windows x64'
        Assert-NoInstalls
    }
    '32-bit PowerShell is rejected' = {
        $script:hostInfo.Is64Bit = $false
        Assert-Stops { Invoke-WS2Setup } '64-bit PowerShell'
        Assert-NoInstalls
    }
    'unsupported Windows build is rejected' = {
        $script:hostInfo.Build = 17763
        Assert-Stops { Invoke-WS2Setup } 'Older Windows'
        Assert-NoInstalls
    }
    'elevated install protects participant profile' = {
        $script:hostInfo.Elevated = $true
        Assert-Stops { Invoke-WS2Setup } 'non-administrator'
        Assert-NoInstalls
    }
    'elevated read-only check is permitted' = {
        $script:hostInfo.Elevated = $true
        Assert-True ((Invoke-WS2Setup -CheckOnly) -eq 0) 'Elevated read-only check was blocked'
        Assert-NoInstalls
    }
    'native wrapper preserves real nonzero exit and stderr' = {
        $result = & $nativeImplementation -File $NodeExecutable -Arguments @((Join-Path $PSScriptRoot 'native-exit.cjs'))
        Assert-True ($result.ExitCode -eq 9) 'Real native exit was lost'
        Assert-True ($result.Output -match 'expected test stderr') 'Real stderr was lost'
    }
    'native stderr warning with zero exit remains success' = {
        $result = & $nativeImplementation -File $NodeExecutable -Arguments @((Join-Path $PSScriptRoot 'native-exit.cjs'), '--success')
        Assert-True ($result.ExitCode -eq 0) 'A stderr warning was incorrectly treated as a failed process'
        Assert-True ($result.Output -match 'expected test stderr') 'Warning output was lost'
    }
    'native executable launch failure cannot report zero' = {
        $result = & $nativeImplementation -File (Join-Path $PSScriptRoot 'intentionally-absent.exe') -Arguments @()
        Assert-True ($result.ExitCode -ne 0) 'Missing executable falsely succeeded'
    }
    'persistent PATH reconstruction does not write registry' = {
        $before = [Environment]::GetEnvironmentVariable('Path', 'User')
        $expected = [Environment]::ExpandEnvironmentVariables((([Environment]::GetEnvironmentVariable('Path', 'Machine')), $before -join ';'))
        $actual = & $pathImplementation
        Assert-True ($actual -ceq $expected) 'Persistent PATH precedence differs from Machine then User'
        Assert-True ([Environment]::GetEnvironmentVariable('Path', 'User') -ceq $before) 'User PATH was modified'
    }
    'published bootstrap parses in Windows PowerShell 5.1' = {
        $bootstrapErrors = $null; $bootstrapTokens = $null
        $null = [Management.Automation.Language.Parser]::ParseInput($bootstrap, [ref] $bootstrapTokens, [ref] $bootstrapErrors)
        Assert-True (@($bootstrapErrors).Count -eq 0) 'Published command has a syntax error'
    }
    'bootstrap install verifies checksum before child and cleans up' = {
        Invoke-TestBootstrap 'Install'
        Assert-True (($script:bootstrapEvents -join ',') -eq 'download,hash,child,cleanup') 'Incorrect bootstrap operation order'
        Assert-True (-not $script:childOptions.Plan -and -not $script:childOptions.Check) 'Install mode forwarded the wrong switch'
    }
    'bootstrap preview forwards only Plan' = {
        Invoke-TestBootstrap 'Plan'
        Assert-True ($script:childOptions.Plan -and -not $script:childOptions.Check) 'Plan was not forwarded correctly'
        Assert-True ($script:bootstrapEvents[-1] -eq 'cleanup') 'Plan did not clean its download'
    }
    'bootstrap check forwards only Check' = {
        Invoke-TestBootstrap 'Check'
        Assert-True ($script:childOptions.Check -and -not $script:childOptions.Plan) 'Check was not forwarded correctly'
    }
    'real child PowerShell binds array-splatted mode switches' = {
        $executable = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        foreach ($mode in @('Plan', 'Check')) {
            $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'mode-probe.ps1'), ('-' + $mode))
            $result = & $nativeImplementation -File $executable -Arguments $arguments
            Assert-True ($result.ExitCode -eq 0) 'Real mode probe failed'
            $bound = $result.Output | ConvertFrom-Json
            Assert-True ($bound.$mode -eq $true) "Real child did not bind $mode"
        }
    }
    'bootstrap checksum mismatch never executes downloaded code' = {
        $script:hashMismatch = $true
        Assert-Stops { Invoke-TestBootstrap 'Install' } 'checksum mismatch'
        Assert-True (($script:bootstrapEvents -join ',') -eq 'download,hash,cleanup') 'Mismatch executed code or missed cleanup'
    }
    'bootstrap failed download never hashes or executes' = {
        $script:downloadFailure = 'before-file'
        Assert-Stops { Invoke-TestBootstrap 'Install' } 'download failure'
        Assert-True (($script:bootstrapEvents -join ',') -eq 'download') 'Missing download continued execution'
    }
    'bootstrap partial download is removed without execution' = {
        $script:downloadFailure = 'partial-file'
        Assert-Stops { Invoke-TestBootstrap 'Install' } 'partial download failure'
        Assert-True (($script:bootstrapEvents -join ',') -eq 'download,cleanup') 'Partial download continued execution or was retained'
    }
    'bootstrap propagates failed child status and cleans up' = {
        $script:childExit = 13
        Assert-Stops { Invoke-TestBootstrap 'Install' } 'did not finish successfully'
        Assert-True (($script:bootstrapEvents -join ',') -eq 'download,hash,child,cleanup') 'Failed child missed cleanup'
    }
}

$results = @()
foreach ($entry in $cases.GetEnumerator()) {
    Reset-Mocks
    $before = $env:Path
    try {
        & $entry.Value
        Assert-True ($env:Path -ceq $before) 'Caller PATH was not restored'
        $results += [pscustomobject] @{ name = $entry.Key; passed = $true }
    } catch {
        $results += [pscustomobject] @{ name = $entry.Key; passed = $false; error = $_.Exception.Message }
    } finally { $env:Path = $before }
}
$summary = @{ cases = $results; syntaxErrors = @($parseErrors).Count; realPackageInstalls = 0; realExtensionInstalls = 0; azureCalls = 0 }
Write-Output ('WS2_TEST_RESULT=' + ($summary | ConvertTo-Json -Depth 8 -Compress))
if (@($results | Where-Object { -not $_.passed }).Count) { exit 1 }
exit 0
