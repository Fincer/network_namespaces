# Network namespaces for Linux desktop & shell applications

Ease use of isolated network namespaces with Linux desktop and shell applications. This repository offers several scripts and files which

- automate network namespace creation for you

  - iptables-based firewall rules are automatically configured for your network namespaces

    - restarting `iptables` Systemd service unit should preserve your network namespace rules when provided unit [override.conf file](etc/systemd/system/iptables.service.d/override.conf) is applied

      - NOTE: you should configure contents [usr/local/bin/iptables-netns](usr/local/bin/iptables-netns) to match configuration of your [/etc/network-namespaces.d/netns_init.sh](etc/network-namespaces.d/netns_init.sh) file

  - you can re-apply network namespace configuration by re-executing `/etc/network-namespaces.d/netns_init.sh`

- provide launch script [netns_exec](usr/local/bin/netns_exec) which enforces an application to run in the selected network namespace

- `ps` and `kill` command wrappers ([psns](usr/local/bin/psns) and [killns](usr/local/bin/killns), respectively) for checking and sending signals (`man 7 signal`) to applications running in a specific network namespace

For automation and auto-deployment of network namespaces during system boot, I prefer [rc-local Systemd wrapper](https://aur.archlinux.org/packages/rc-local).

# Deployment

- You should deploy repository snippet files using the directory hierarchy shown here

- `bash`, `iptables` and `sudo` are required

  - `rc.local` is optional but preferred for full automation

- You should set executable bit (`chmod +x`) for files in [usr/local/bin/](usr/local/bin/) and for `etc/network-namespaces.d/netns_init.sh`

# Examples

## Predefined network namespaces

| Network namespace | Description                                                            |
|-------------------|------------------------------------------------------------------------|
| nonet             | No network access                                                      |
| netwan            | WAN access. No LAN access                                              |
| failsafe          | Similar to netwan but with different DNS set                           |
| netlocal          | Host-only network access without DNS (change configuration as desired) |

You should re-configure pre-defined network namespaces as you wish (contents of files [etc/network-namespaces.d/netns_init.sh](etc/network-namespaces.d/netns_init.sh) and [usr/local/bin/iptables-netns](usr/local/bin/iptables-netns)).

You should add or remove network namespaces and customize the setup for your needs.

## Desktop applications, usage examples

- Generic application (VLC), run in `nonet` namespace (no network access):

```
netns_exec nonet vlc
```

- Flatpak application (Valve Steam), run in `nonet` namespace (no network access):

(NOTE: This can be also be achieved via native Flatpak network access/permission control)

```
netns_exec nonet /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/steam --file-forwarding com.valvesoftware.Steam
```

- Flatpak application (Discord), run in `netwan` namespace:

```
netns_exec netwan /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=com.discordapp.Discord com.discordapp.Discord
```

- Flatpak application (Firefox), run in `failsafe` namespace:

```
netns_exec failsafe /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=firefox --file-forwarding org.mozilla.firefox
```
