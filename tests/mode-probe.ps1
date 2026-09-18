# A real, harmless child script: validates -File switch binding, never installs.
param([switch] $Plan, [switch] $Check)
@{ Plan = [bool] $Plan; Check = [bool] $Check } | ConvertTo-Json -Compress
exit 0
