# Uninstall this program.
$path = [System.Environment]::GetEnvironmentVariable(
    'PATH',
    'Machine'
)
$path = ($path.Split(';') | Where-Object { $_ -ne 'C:\Dev\partycopy' }) -join ';'
[System.Environment]::SetEnvironmentVariable(
    'PATH',
    $path,
    'Machine'
)
