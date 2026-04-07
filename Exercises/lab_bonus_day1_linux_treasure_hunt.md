# **🎁 Bonus Lab — Day 1**: Linux Treasure Hunt

| | |
|---|---|
| **Duration** | 45 min |
| **Objectives** | Explore the Linux system in depth through fun, progressive challenges using only Day 1 concepts |
| **Prerequisites** | See below |
| **Difficulty** | Beginner to Intermediate |

### Prerequisites

Choose ONE of the following environments:

**Option A -- Virtual Machine (recommended for full system access)**
- A Linux VM (Ubuntu 22.04+ or Debian 12 recommended)
- Installation via VirtualBox, UTM (macOS), VMware or Hyper-V
- Minimum: 2 GB RAM, 20 GB disk
- Take a snapshot of your VM before starting

**Option B -- Docker Container**
- Docker Desktop installed and running
- Required image: `docker pull ubuntu:22.04`
- Some system information (CPU, uptime, systemd) may differ or be unavailable in a container

> **Note:** The commands shown use Docker. If you are using a VM, ignore the `docker run` and `docker exec` commands and run the Linux commands directly in your terminal.

---

## Concept

You are a Linux explorer. Your mission: uncover hidden information within the system. Each challenge earns points. The scoring is indicated for each question.

Launch your environment:

```bash
docker run -it --rm --hostname treasure-hunt --name bonus1 ubuntu:22.04 bash
```

Install useful tools:

```bash
apt update && apt install -y procps coreutils kmod systemd
```

---

## Challenge 1: Kernel Compilation Date (1 point)

Find the exact compilation date of the currently running Linux kernel.

**Hint**: the file `/proc/version` contains this information.

---

## Challenge 2: How Many Kernel Modules Are Loaded? (2 points)

Count the total number of kernel modules currently loaded in memory.

**Hint**: `lsmod` lists all loaded modules. You need to count the lines (minus the header).

---

## Challenge 3: Default Systemd Target (2 points)

Find out what the default systemd target is on this system.

**Hint**: `systemctl` can tell you the default target.

---

## Challenge 4: Slowest Service at Boot (2 points)

Find which service took the longest to start during the last boot.

**Hint**: `systemd-analyze` provides boot timing information.

---

## Challenge 5: CPU Model (1 point)

Find the exact CPU model name this machine is running.

**Hint**: look inside `/proc/cpuinfo`.

---

## Challenge 6: Total System RAM (1 point)

Find out how much total RAM this system has.

**Hint**: look inside `/proc/meminfo`.

---

## Challenge 7: Available Shells (2 points)

List all the shells available on this system.

**Hint**: there is a specific file that lists all valid login shells.

---

## Challenge 8: Bootloader Configuration (2 points)

Identify what bootloader is installed and find its configuration file.

**Hint**: the most common Linux bootloader is GRUB. Its configuration lives in `/etc/default/` and `/boot/`.

---

## Challenge 9: System Uptime (1 point)

Find the current system uptime (how long the machine has been running).

---

## Challenge 10 — BONUS: Kernel Module Investigation (3 points)

Find the names of 3 currently loaded kernel modules and describe what each one does.

**Hint**: use `lsmod` to list modules and `modinfo <module_name>` to get details.

---

## Scoring Summary

| Challenge | Description | Points |
|---|---|---|
| 1 | Kernel compilation date | 1 |
| 2 | Number of loaded kernel modules | 2 |
| 3 | Default systemd target | 2 |
| 4 | Slowest service at boot | 2 |
| 5 | CPU model name | 1 |
| 6 | Total system RAM | 1 |
| 7 | Available shells | 2 |
| 8 | Bootloader configuration | 2 |
| 9 | System uptime | 1 |
| 10 | Kernel module investigation (BONUS) | 3 |
| | **Total** | **17** |

---

## Verification

Final checklist:

- [ ] Challenge 1: Kernel compilation date found
- [ ] Challenge 2: Number of loaded modules counted
- [ ] Challenge 3: Default systemd target identified
- [ ] Challenge 4: Slowest boot service identified
- [ ] Challenge 5: CPU model name found
- [ ] Challenge 6: Total RAM amount found
- [ ] Challenge 7: All available shells listed
- [ ] Challenge 8: Bootloader and its configuration located
- [ ] Challenge 9: Current uptime displayed
- [ ] Challenge 10: 3 kernel modules described with modinfo

---

## Common Pitfalls

| Pitfall | Explanation |
|---|---|
| `lsmod` empty in Docker | In minimal containers, very few modules may be listed; the host kernel modules are still visible |
| `systemctl` not available in Docker | systemd is not the init system in containers; use a VM for challenges 3 and 4 |
| `systemd-analyze` fails in Docker | Requires a full systemd boot; skip this challenge in container environments |
| `/boot/` empty in Docker | The boot partition is not mounted in containers; use a VM for challenge 8 |
| `uptime -p` not available | On older systems, use `uptime` without the `-p` flag |
| Confusing `/proc/cpuinfo` threads vs cores | Each `processor` entry may be a thread (hyperthreading), not a physical core |

> 💡 Solutions are available from your trainer.
