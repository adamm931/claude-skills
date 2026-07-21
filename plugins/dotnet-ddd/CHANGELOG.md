# Changelog

## 1.1.0
- Add `dotnet-setup` skill: checks for the .NET SDK and installs it (`scripts/install-dotnet-sdk.sh`)
  if missing, mirroring the mandatory-first-step pattern in `postgres-ops`/`kafka-ops`. `init-ddd`
  now points to it as step 1.

## 1.0.0
- Initial release: architecture-rules constitution; init-ddd, new-module, vertical-slice,
  integration-event, and aggregate-design skills; ddd-reviewer agent; PostToolUse verify hook.
