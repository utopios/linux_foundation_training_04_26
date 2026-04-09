# Exercise 4: Network Diagnostics

| | |
|---|---|
| **Estimated Duration** | 30-45 minutes |
| **Objectives** | Troubleshoot network issues, check connectivity/DNS/ports, apply basic iptables rules |
| **Prerequisites** | See below |
| **Difficulty** | Intermediate to Advanced |

### Prerequisites

Choose ONE of the following environments:

**Option A -- Virtual Machine (recommended for full system access)**
- A Linux VM (Ubuntu 22.04+ or Debian 12 recommended), or multiple VMs for a multi-server setup
- Install via VirtualBox, UTM (macOS), VMware, or Hyper-V
- Minimum: 2 GB RAM, 20 GB disk per VM
- Snapshot your VM before each lab
- Note: A VM gives a much more realistic networking experience (real interfaces, real routing, real iptables). Docker networking uses virtual bridges and NAT, which differ significantly from physical or VM-level networking

**Option B -- Docker Container**
- Docker Desktop installed and running
- Pull required images: `docker pull ubuntu:22.04`
- Note: Docker networking (bridge networks, embedded DNS) differs from real networking. iptables rules inside containers may not behave as expected on all platforms. Concepts like routing, ARP, and firewalling are more realistic on a VM

> **Note:** Commands shown use Docker. If you are using a VM, skip the `docker run`, `docker network`, and `docker exec` commands. Instead, install the networking tools directly on your VM(s) and run the Linux commands in your VM terminal. For multi-server scenarios, use multiple VMs or multiple terminal sessions.

---

## Setup

Create the lab network with containers:

```bash
# Create the network
docker network create --subnet=172.25.0.0/24 diag-network

# Server A - "Web server"
docker run -d --rm --name web-server --hostname web-server \
  --network diag-network --ip 172.25.0.10 \
  ubuntu:22.04 sleep infinity

# Server B - "Database server"
docker run -d --rm --name db-server --hostname db-server \
  --network diag-network --ip 172.25.0.20 \
  ubuntu:22.04 sleep infinity

# Server C - "Client workstation"
docker run -d --rm --name client --hostname client \
  --network diag-network --ip 172.25.0.100 \
  ubuntu:22.04 sleep infinity

# Install tools on all servers
for server in web-server db-server client; do
  docker exec $server bash -c 'apt update && apt install -y iproute2 iputils-ping dnsutils net-tools curl netcat-openbsd python3 iptables' &
done
wait
echo "Setup complete"
```

Start some services:

```bash
# Start a web server on web-server (port 80)
docker exec web-server bash -c '
mkdir -p /var/www
echo "<h1>Web Server OK</h1>" > /var/www/index.html
cd /var/www && python3 -m http.server 80 &
'

# Start a "database" listener on db-server (port 3306)
docker exec db-server bash -c '
while true; do echo "MySQL ready" | nc -l -p 3306 -q 0; done &
'
```

---

## Part 1: Connectivity Diagnostics (10 min)

### Scenario

You are logged into the client workstation. Users report they cannot access the web server.

```bash
docker exec -it client bash
```

### Task 1.1: Basic Connectivity

Check if the client can reach the web server. Use the following diagnostic steps **in order**:

1. Check your own IP configuration
2. Ping the web server
3. Ping the database server
4. Check the routing table

Write down the commands you used and the results you observed.

### Task 1.2: Service Connectivity

Now check if the services are actually running:

1. Test if port 80 is open on the web server
2. Test if port 3306 is open on the database server
3. Test a port that should NOT be open (e.g., 8080)
4. Retrieve the web page content

> **Hint**: Use `nc -zv` to test ports and `curl` to retrieve HTTP content.

---

## Part 2: DNS Diagnostics (10 min)

### Task 2.1: Name Resolution

Check if DNS resolution works:

```bash
# Docker's built-in DNS
dig web-server
dig db-server

# Short form
dig +short web-server

# Check resolver configuration
cat /etc/resolv.conf
```

### Task 2.2: External DNS (if container has internet)

```bash
# Resolve an external domain
dig google.com +short

# Query a specific DNS server
dig @8.8.8.8 google.com +short

# Full trace
dig +trace google.com 2>/dev/null | tail -10
```

### Task 2.3: Troubleshooting DNS

Answer these questions:

1. What DNS server is your container configured to use?
2. What happens if you try to resolve a non-existent name?
3. What is the difference between `dig`, `nslookup`, and `host`?

---

## Part 3: Port and Service Diagnostics (10 min)

### Task 3.1: From the Server Side

Log into the web server and check what's listening:

```bash
# Open a new terminal
docker exec -it web-server bash
```

```bash
# List all listening ports
ss -tlnp

# List all connections (including established)
ss -tanp

# Which process is using port 80?
ss -tlnp | grep :80

# Legacy: netstat
netstat -tlnp
```

**Questions**:
- What process is listening on port 80?
- Is it listening on all interfaces (0.0.0.0) or a specific one?

### Task 3.2: Comprehensive Port Scan

From the client, scan common ports on both servers:

```bash
docker exec -it client bash
```

Write a loop that tests ports 22, 80, 443, 3306, 5432, 8080, 8443 on both the web server (172.25.0.10) and the database server (172.25.0.20), and reports which ports are OPEN and which are CLOSED.


```bash
# Scan common ports on the web server
echo "=== Web Server Port Scan ==="
for port in 22 80 443 3306 5432 8080 8443; do
  result=$(nc -zv -w1 172.25.0.10 $port 2>&1)
  if echo "$result" | grep -q "succeeded"; then
    echo "  Port $port: OPEN"
  else
    echo "  Port $port: CLOSED"
  fi
done

echo ""
echo "=== DB Server Port Scan ==="
for port in 22 80 443 3306 5432 8080 8443; do
  result=$(nc -zv -w1 172.25.0.20 $port 2>&1)
  if echo "$result" | grep -q "succeeded"; then
    echo "  Port $port: OPEN"
  else
    echo "  Port $port: CLOSED"
  fi
done
```

> **Hint**: Use `nc -zv -w1` to test each port. Check the exit code or output for "succeeded".

---

## Part 4: Basic iptables Rules (15 min)

### 4.1 Understanding iptables

iptables is the traditional Linux firewall. It works with **chains** of rules:
- **INPUT**: incoming traffic to this machine
- **OUTPUT**: outgoing traffic from this machine
- **FORWARD**: traffic being routed through this machine

### 4.2 View Current Rules

On the web server:

```bash
docker exec -it web-server bash
```

```bash
# View all rules
iptables -L -n -v

# View rules with line numbers
iptables -L -n --line-numbers
```

By default, all policies should be ACCEPT (no firewall rules).

### 4.3 Block Traffic from the Client

Scenario: Block all traffic from the client (172.25.0.100) to the web server.

iptables -A INPUT -s 172.25.0.100 -j DROP

**Task**: Write the iptables command to add an INPUT rule that DROPs all traffic from 172.25.0.100. Then test from the client using `curl` and `ping` to verify it's blocked. Also verify that traffic from db-server (172.25.0.20) still works.

### 4.4 Allow Only HTTP, Block Everything Else

Remove the previous rule and create a proper firewall configuration:

**Task**: Write iptables rules on the web server that:
1. Flush all existing rules
iptables -F
2. Allow established/related connections

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

3. Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
4. Allow HTTP (port 80) from anyone
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
5. Allow ping (ICMP) from anyone
iptables -A INPUT -p icmp -j ACCEPT
6. Drop everything else
iptables -A INPUT -j DROP

Test from the client: HTTP and ping should work, but other ports (e.g., 22) should be blocked.

### 4.5 Reset the Firewall

```bash
docker exec web-server bash -c '
iptables -F
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
echo "Firewall reset to default (allow all)"
'
```

---

## Verification

Check that you can:

- [ ] Use `ip addr`, `ip route` to check network configuration
- [ ] Use `ping` to test connectivity between hosts
- [ ] Use `dig`/`nslookup` to troubleshoot DNS
- [ ] Use `ss`/`netstat` to check listening ports
- [ ] Use `nc` to test if a specific port is open
- [ ] Use `curl` to test HTTP services
- [ ] Write basic iptables rules (allow, deny, by port, by IP)
- [ ] Flush iptables rules and reset to defaults

**Final test**: Without looking at the instructions, write iptables rules on the db-server that:
1. Allow traffic from the web-server (172.25.0.10) on port 3306
2. Allow ping from everyone
3. Block everything else

---

## Cleanup

```bash
docker stop web-server db-server client
docker network rm diag-network
```

---

## Common Pitfalls

| Pitfall | Explanation |
|---|---|
| Forgetting ESTABLISHED,RELATED | Without this rule, responses to outgoing connections are blocked |
| Wrong rule order | iptables processes rules top-to-bottom; the first match wins |
| Locking yourself out | If using iptables on a remote server, always have a backup plan (console access, cron to flush rules) |
| DROP vs REJECT | DROP silently ignores packets (timeout), REJECT sends back an error (connection refused) |
| Not flushing before testing | Old rules may interfere with your new configuration |

> Solutions are available from your trainer.
