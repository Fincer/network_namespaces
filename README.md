# Set network namespaces automatically

This repository is intended to ease use of isolated network namespaces with Linux desktop applications. The repository offers several scripts and files which

- automate network namespace creation for you
  - iptables-based firewall rules are automatically configured for network namespaces
  - you can re-apply network namespace configuration, too

- provide launch script `netns_exec` which enforces application to run in selected network namespace

- `ps` and `kill`  command wrappers (`psns` and `killns`, respectively) for checking and killing applications running in a specific network namespace

For automation and auto-deployment of desired network namespaces during system boot, I prefer [rc-local systemd wrapper](https://aur.archlinux.org/packages/rc-local).

# Deployment

- Deploy repository snippet files using the directory hierarchy shown here

- The functionality depends on `iptables`, `sudo`. `rc.local` is preferred, too

- Set executable bit for files in `usr/local/bin/` and `etc/network-namespaces.d/netns_init.sh`

# Examples

## Predefined network namespaces

```
nonet = No network access
netwan = WAN access. No LAN access
failsafe = Similar to netwan but with different DNS set
netlocal = Host-only network access without DNS (change configuration as desired)

```

You should configure pre-defined network namespaces as you wish (file `etc/network-namespaces.d/netns_init.sh`). You should add or remove network namespaces and customize the setup for your needs.

## Running application in specific network namespace, examples

### Generic application, run in "nonet" namespace (no network access):

```
netns_exec nonet vlc
```

### Flatpak application, run in "nonet" namespace (no network access):

(NOTE: This can be also be achieved via Flatpak network access control)

```
netns_exec nonet netwan /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/steam --file-forwarding com.valvesoftware.Steam
```

### Flatpak application, run in "netwan" namespace

```
netns_exec netwan /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=com.discordapp.Discord com.discordapp.Discord
```

### Flatpak application, run in "failsafe" namespace

```
netns_exec failsafe /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=firefox --file-forwarding org.mozilla.firefox
```
