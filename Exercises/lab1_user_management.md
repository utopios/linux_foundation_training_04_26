# TP 1: User Management Mini-Project

| | |
|---|---|
| **Estimated Duration** | 45min |
| **Objectives** | Configure a multi-team server with users, groups, shared directories, and permissions |
| **Prerequisites** | See below |
| **Difficulty** | Intermediate |

### Prerequisites

Choose ONE of the following environments:

**Option A -- Virtual Machine (recommended for full system access)**
- A Linux VM (Ubuntu 22.04+ or Debian 12 recommended)
- Install via VirtualBox, UTM (macOS), VMware, or Hyper-V
- Minimum: 2 GB RAM, 20 GB disk
- Snapshot your VM before each lab
- Note: A VM provides a more realistic multi-user experience; Docker containers run as root by default, which can mask real-world permission and authentication behaviors

**Option B -- Docker Container**
- Docker Desktop installed and running
- Pull required images: `docker pull ubuntu:22.04`
- Note: Containers run as root by default. User/group management and permissions work, but some behaviors (e.g., login shells, PAM authentication, `su` sessions) may differ from a real system

> **Note:** Commands shown use Docker. If you are using a VM, skip the `docker run` and `docker exec` commands and run the Linux commands directly in your VM terminal.

---

## Scenario

You are a system administrator in a company. You must configure a Linux server to host three teams:

- **Dev Team** (developers): Alice, Bob, Charlie
- **Ops Team** (operations): David, Eve
- **Management Team**: Frank

Each team must have:
- A shared directory accessible only by its members
- A common `/shared` directory readable by everyone, writable by Dev and Ops
- Files created in a shared directory must automatically belong to the team's group (SGID)

Frank (Management) must be able to read all team directories but can only write in the management directory.

---

## Environment Setup

Launch the server container:

```bash
docker run -it --rm --hostname server-tp1 --name tp1 ubuntu:22.04 bash
```

Install the required tools:

```bash
apt update && apt install -y sudo vim tree acl
```

> **Tip**: Open a second terminal to test access with different users.
>
> ```bash
> docker exec -it tp1 bash
> ```

---

## Step 1: Create the Groups (10 min)

Create three groups corresponding to the teams:

- `dev` (GID 2001)
- `ops` (GID 2002)
- `management` (GID 2003)

Also create a `shared` group (GID 2010) for the common directory.

**What to use:** the `groupadd` command with the `-g` flag to specify a GID.

After creating the groups, verify them by checking `/etc/group`.

---

## Step 2: Create the Users (15 min)

Create the following users with their groups:

| User | Primary Group | Secondary Groups | Password |
|---|---|---|---|
| alice | dev | shared | `alice123` |
| bob | dev | shared | `bob123` |
| charlie | dev | shared | `charlie123` |
| david | ops | shared | `david123` |
| eve | ops | shared | `eve123` |
| frank | management | (read-only via ACL) | `frank123` |

Each user must have:
- A home directory at `/home/USER`
- The `/bin/bash` shell
- A comment describing their role

**What to use:** the `useradd` command with flags for home directory (`-m`), shell (`-s`), primary group (`-g`), secondary groups (`-G`), and comment (`-c`). Use `chpasswd` to set passwords.

After creating the users, verify them using the `id` command.

---

## Step 3: Create the Shared Directories (10 min)

Create the following structure:

```
/teams/
├── dev/          (accessible only by the dev group)
├── ops/          (accessible only by the ops group)
├── management/   (accessible only by the management group)
└── shared/       (readable by all, writable by dev and ops)
```

**What to do:**
1. Create all four directories under `/teams/`
2. Set the correct owner and group on each directory using `chown`
3. Set permissions using `chmod` -- think about what mode gives group read/write/execute while blocking others
4. Enable SGID on each team directory so that new files inherit the directory's group

**Key concept:** SGID on a directory is set with the `2` prefix in octal permissions (e.g., `2770`).

After creating the directories, verify the structure with `ls -la /teams/`.

---

## Step 4: Verify SGID Behavior (10 min)

The SGID (Set Group ID) bit on a directory causes new files to inherit the directory's group (instead of the user's primary group).

Test that SGID works correctly:

```bash
# As alice, create a file in /teams/dev
su - alice -c 'touch /teams/dev/code_alice.py'

# Verify the file belongs to the dev group
ls -la /teams/dev/
```

Expected output:

```
-rw-r--r-- 1 alice dev 0 ... code_alice.py
```

> The file belongs to the `dev` group (not alice's default group) thanks to SGID.

Perform the same verification with other users in their respective directories.

---

## Step 5: Test Access Restrictions (15 min)

Verify that the restrictions work. For each test, note whether access is granted or denied:

### Tests to Perform

| Test | Command | Expected Result |
|---|---|---|
| Alice reads /teams/dev | `su - alice -c 'ls /teams/dev'` | Allowed |
| Alice writes in /teams/dev | `su - alice -c 'touch /teams/dev/test'` | Allowed |
| Alice reads /teams/ops | `su - alice -c 'ls /teams/ops'` | Denied |
| David reads /teams/dev | `su - david -c 'ls /teams/dev'` | Denied |
| David writes in /teams/ops | `su - david -c 'touch /teams/ops/test'` | Allowed |
| Alice writes in /teams/shared | `su - alice -c 'touch /teams/shared/test_a'` | Allowed |
| Frank reads /teams/shared | `su - frank -c 'ls /teams/shared'` | Allowed |
| Frank writes in /teams/shared | `su - frank -c 'touch /teams/shared/test_f'` | Denied |
| Frank reads /teams/dev | `su - frank -c 'ls /teams/dev'` | Denied |

Run each command and verify the results.

> **Question**: Why can't Frank write in `/teams/shared`? How could we give him read access to the team directories?

---

## Step 6: ACLs for Frank (15 min)

Frank must be able to **read** all team directories. Standard permissions are not sufficient for this -- you need ACLs (Access Control Lists).

**What to do:**
1. Use `setfacl` to grant Frank read and execute access (`rx`) on `/teams/dev` and `/teams/ops`
2. Verify the ACLs using `getfacl`
3. Test that Frank can now list files in `/teams/dev` but still cannot write
4. Set **default ACLs** so that future files created in those directories are also readable by Frank
5. Add Frank to the `shared` group so he can write in `/teams/shared`

**Key commands to research:** `setfacl -m`, `setfacl -dm`, `getfacl`, `usermod -aG`

> Remember: A user must log out and log back in for group changes to take effect.

---

## Step 7: Sticky Bit on /teams/shared (10 min)

**Problem**: In a shared directory, a user can delete other users' files if they have write permission on the directory.

**Your task:**
1. Create a file as David in `/teams/shared/`
2. Try to delete it as Alice -- it should succeed (this is the problem)
3. Enable the sticky bit on `/teams/shared` using `chmod +t`
4. Verify the sticky bit appears in the permissions (look for `t` in the output)
5. Try again to delete David's file as Alice -- it should now be denied

**Key concept:** The sticky bit restricts file deletion in a directory to the file's owner, the directory's owner, or root.

---

## Final Structure Summary

```bash
tree -pugla /teams/
```

Run this command to visualize the structure with permissions, owners, and groups.

---

## Verification

Final checklist:

- [ ] 3 groups created (dev, ops, management) + 1 shared group
- [ ] 6 users created with the correct primary and secondary groups
- [ ] 4 shared directories with the correct permissions
- [ ] SGID enabled on all team directories
- [ ] Created files inherit the correct group
- [ ] Isolation between teams (dev cannot read ops and vice versa)
- [ ] Frank can read dev and ops via ACL
- [ ] Sticky bit on /teams/shared
- [ ] Nobody can delete other users' files in /shared


---

## Bonus: Automation Script

If you finish early, write a bash script that automates all of the above configuration. The script must:

1. Create the groups
2. Create the users
3. Create the directories
4. Configure permissions, SGID, ACLs, and sticky bit
5. Display a final summary

---

## Common Pitfalls

| Pitfall | Explanation |
|---|---|
| Forgetting `-a` in `usermod -aG` | Without `-a`, secondary groups are replaced instead of appended |
| SGID not enabled | Files do not inherit the directory's group |
| Permissions too open | `chmod 777` is almost always a mistake |
| Groups not taken into account | A user must log out/log in for group changes to take effect |
| ACLs ignored | Verify that the filesystem supports ACLs (`acl` mount option) |


