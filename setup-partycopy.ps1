# setup-partycopy.ps1
# Install partycopy on a Windows system
#
# Author: Sam Saint-Pettersen, October 2025.
# https://stpettersen.xyz
#
# Usage: TODO
#

# Define the server root for assets served by this script.
$global:server = "https://sh.homelab.stpettersen.xyz/partycopy"

function Check-Is-Admin {
    [OutputType([bool])]
    param()
    process {
        [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
        return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
    }
}

function SHA256-Cksum {
    param(
        [string]$file
    )
    $cksum_file = (Get-Item $file).BaseName + "_sha256.txt";
    $expected = (Get-Content -Path $cksum_file).SubString(0, 64);
    $cksum = (Get-FileHash -Path $file -Algorithm SHA256).Hash.ToLower();
    if ($cksum -ne $expected) {
        echo "SHA256 checksum failed.";
        echo "Aborting...";
        exit 1;
    }

    echo "SHA256 checksum OK.";
    #rm -fo $cksum_file
}

function ScriptCksum {

}

function Main {
    if(-not (Check-Is-Admin)) {
        echo "This script must be executed as Administrator."
        exit 1;
    }
    SHA256-Cksum partycopy_win64.zip
}

Main
