#!/usr/bin/env bash
# setup-partycopy.sh
# Install partycopy on a Linux system
#
# Author: Sam Saint-Pettersen, October 2025.
# https://stpettersen.xyz
#
# Usage: wget -qO - https://sh.homelab.stpettersen.xyz/partycopy/setup-partycopy.sh | sudo bash
#
# OR SAFER WAY, INSPECTING THE SCRIPT CONTENTS BEFORE RUNNING:
# > wget -O setup-slax.sh https://sh.homelab.stpettersen.xyz/slax/setup-partycopy.sh
# > cat setup-partycopy.sh
# > sudo bash setup-partycopy.sh

# Define the server root for assets served by this script.
server="https://sh.homelab.stpettersen.xyz/partycopy"

check_is_root() {
    if (( EUID != 0 )); then
        echo "Please run this as root (sudo/doas)."
        exit 1
    fi
}

sha256cksm() {
    local status
    local cksum_file
    cksum_file=$1
    cksum_file="${cksum_file%.*}_sha256.txt"
    wget -q "${server}/${cksum_file}"
    sha256sum -c "${cksum_file}" > /dev/null 2>&1
    status=$?
    if (( status == 1 )); then
        echo "SHA256 checksum failed for '${1}'."
        echo "Aborting..."
        rm -f "${cksum_file}"
        exit 1
    else
        echo "SHA256 checksum OK for '${1}'."
    fi
    rm -f "${cksum_file}"
}

script_cksm() {
    if [[ ! -f "setup-partycopy.sh" ]]; then
        wget -q "${server}/setup-partycopy.sh"
    fi
    sha256cksm "setup-partycopy.sh"
    if [[ $(basename "$0") != "setup-partycopy.sh" ]]; then
        rm -f setup-partycopy.sh
    fi
}

main() {
    check_is_root
    # Get machine architecture
    local arch
    arch=$(uname -m)
    if [[ $arch == "x86_64" ]]; then
        arch="amd64"
    elif [[ $arch == "aarch64" ]]; then
        arch="aarch64"
    fi
    local archive
    archive="partycopy_linux_${arch}.tar.gz"
    echo "Installing partycopy (Linux ${arch})..."
    script_cksm
    if [[ -f "${archive}" ]]; then
        rm -f "${archive}"
    fi
    wget -q "${server}/${archive}"
    sha256cksm "${archive}"
    tar -xzf "${archive}"
    rm -f "${archive}"
    mkdir -p /etc/partycopy
    mkdir -p /usr/share/partycopy
    mv partycopy /usr/local/bin
    chmod +x /usr/local/bin/partycopy
    mv LICENSE /usr/share/partycopy

    local pcp
    read -r -p "Create symbolic link pcp for partycopy? (Y/n): " pcp < /dev/tty
    if [[ -z $pcp ]] || [[ "${pcp,,}" == "y" ]]; then
        echo "Creating pcp symbolic link for partycopy..."
        ln -sf /usr/local/bin/partycopy /usr/local/bin/pcp
    fi

    local profiles
    read -r -p "Download available profiles for partycopy? (Y/n): " profiles < /dev/tty
    if [[ -z $profiles ]] || [[ "${profiles,,}" == "y" ]]; then
        echo "Downloading and installing profiles..."
        wget -q "${server}/homelab.cfg"
        sha256cksm "homelab.cfg"
        wget -q "${server}/mmedia.cfg"
        sha256cksm "mmedia.cfg"
        mv "homelab.cfg" /etc/partycopy
        mv "mmedia.cfg" /etc/partycopy
    fi
    echo "Done."
    exit 0
}

main
