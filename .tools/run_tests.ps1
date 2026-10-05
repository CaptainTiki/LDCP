# Runs every GUT test under .tests/ headless and exits with GUT's exit code.
# Usage:  .\.tools\run_tests.ps1 [-Godot <path to godot exe>]
# Without -Godot it uses the GODOT environment variable, then this desktop's
# Steam install.
param(
	[string]$Godot = $(if ($env:GODOT) { $env:GODOT } else { "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" })
)

$project = Split-Path -Parent $PSScriptRoot
& $Godot --headless --path $project -s addons/gut/gut_cmdln.gd `
	"-gdir=res://.tests/unit,res://.tests/integration" -gexit
exit $LASTEXITCODE
