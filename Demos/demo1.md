## First command

```bash
cat /etc/os-release
```

## Package Managers

- Debian Family: APT
- FEDORA AND REHL: DNF remplacement of yum
- ALPINE: apk (ALPINE PACKAGE KEEPER)
- Arch Linux: Pacman

### Package manager Cheat sheet

| Action | APT (Ubuntu/Debian) | DNF (Fedora) | APK (Alpine) | Pacman (Arch) |
|---|---|---|---|---|
| Update repos | `apt update` | `dnf check-update` | `apk update` | `pacman -Sy` |
| Install a package | `apt install -y PKG` | `dnf install -y PKG` | `apk add PKG` | `pacman -S --noconfirm PKG` |
| Remove a package | `apt remove PKG` | `dnf remove PKG` | `apk del PKG` | `pacman -R PKG` |
| Search a package | `apt search PKG` | `dnf search PKG` | `apk search PKG` | `pacman -Ss PKG` |
| List installed | `dpkg -l` | `rpm -qa` | `apk info` | `pacman -Q` |
| Upgrade system | `apt upgrade -y` | `dnf upgrade -y` | `apk upgrade` | `pacman -Syu` |

## User management


| Command | Description |
|---|---|
| `useradd -m -s /bin/bash USER` | Create a user with home and shell |
| `userdel -r USER` | Delete a user and their home |
| `usermod -aG GROUP USER` | Add a user to a group |
| `usermod -L USER` | Lock an account |
| `usermod -U USER` | Unlock an account |
| `groupadd GROUP` | Create a group |
| `groupdel GROUP` | Delete a group |
| `groupmod -n NEWNAME GROUP` | Rename a group |
| `passwd USER` | Change password |
| `chpasswd` | Change passwords in batch |
| `id USER` | Display UID, GID, and groups |
| `su - USER` | Login as USER |
| `sudo COMMAND` | Run as root |