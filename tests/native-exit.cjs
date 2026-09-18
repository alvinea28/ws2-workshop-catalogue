// Harmless real child process: tests native stderr/exit handling without shell quoting.
process.stderr.write('expected test stderr\n');
process.exitCode = process.argv.includes('--success') ? 0 : 9;
