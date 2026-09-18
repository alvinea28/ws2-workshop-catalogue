import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const script = readFileSync(resolve(root, 'setup.ps1'), 'utf8');
assert.equal(process.platform, 'win32', 'Run these installer tests on Windows (native PowerShell 5.1); do not substitute skipped tests.');
const environment = { ...process.env };
for (const key of Object.keys(environment)) {
  if (/^(ARM_|AZURE_|ACTIONS_ID_TOKEN_|TF_VAR_|TF_CLI_ARGS|TF_LOG|GH_TOKEN$|GITHUB_TOKEN$)/i.test(key)) delete environment[key];
}
const powershell = resolve(process.env.SystemRoot, 'System32/WindowsPowerShell/v1.0/powershell.exe');
const run = spawnSync(powershell, ['-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
  '-File', resolve(root, 'tests/setup.tests.ps1'), '-NodeExecutable', process.execPath], {
  cwd: root, env: environment, encoding: 'utf8', shell: false, timeout: 120_000, maxBuffer: 4 * 1024 * 1024,
});
const line = run.stdout?.split(/\r?\n/).find(value => value.startsWith('WS2_TEST_RESULT='));
assert.ok(line, `PowerShell test harness produced no results: ${run.error || run.stderr}\n${run.stdout}`);
const result = JSON.parse(line.slice('WS2_TEST_RESULT='.length));

test('native Windows PowerShell parses the complete installer', () => assert.equal(result.syntaxErrors, 0));
for (const scenario of result.cases) test(scenario.name, () => assert.equal(scenario.passed, true, scenario.error));
test('all expected scenarios execute without any real installations or Azure access', () => {
  assert.equal(result.cases.length, 53);
  assert.equal(run.status, 0);
  for (const key of ['realPackageInstalls', 'realExtensionInstalls', 'azureCalls']) assert.equal(result[key], 0);
});
test('installer has no cloud, identity, persistent policy or insecure installer commands', () => {
  assert.doesNotMatch(script, /\b(?:Invoke-Expression|Set-ExecutionPolicy|SetEnvironmentVariable|Start-Sleep|Restart-Computer)\b/);
  assert.doesNotMatch(script, /--(?:ignore-security-hash|ignore-local-archive-malware-scan|allow-reboot|uninstall-previous)\b/);
  assert.doesNotMatch(script, /(?:az|gh)\s+(?:login|account|auth)|terraform\s+(?:init|plan|apply|destroy)\s+-/i);
  assert.doesNotMatch(script, /(?:git\s+(?:clone|config)\b|--disable-workspace-trust|--disable-certificate)/i);
});
test('pins and curated Marketplace IDs match the independently checked toolchain', () => {
  for (const pin of ["PackageVersion = '24.16.0'", "PackageVersion = '1.16.1'", "PackageVersion = 'v0.24.0'", "PackageVersion = '1.7.12'"]) assert.ok(script.includes(pin), pin);
  for (const id of ['GitHub.copilot-chat', 'GitHub.vscode-pull-request-github', 'HashiCorp.terraform',
    'GitHub.vscode-github-actions', 'ms-vscode.PowerShell', 'redhat.vscode-yaml']) assert.ok(script.includes(id), id);
  assert.ok(script.includes("Id = 'Terraform-docs.Terraform-docs'"));
});

test('published bootstrap SHA-256 matches the exact LF-normalized Git script', () => {
  const guide = readFileSync(resolve(root, 'docs/windows-setup.md'), 'utf8');
  const hashes = [...guide.matchAll(/-ne '([a-f0-9]{64})'/g)].map(match => match[1]);
  assert.deepEqual(hashes, [createHash('sha256').update(script.replace(/\r\n/g, '\n')).digest('hex')]);
  assert.match(readFileSync(resolve(root, '.gitattributes'), 'utf8'), /^\*\.ps1 text eol=lf$/m);
  assert.ok(guide.includes('https://raw.githubusercontent.com/alvinea28/ws2-workshop-catalogue/dev/setup.ps1'));
});
