# Troubleshooting Guide

This guide covers common issues and solutions for deploying and running the Nihongo Vocab Test application on UGREEN DXP2800.

## Table of Contents

1. [SSH Connection Issues](#ssh-connection-issues)
2. [Docker Issues](#docker-issues)
3. [Application Issues](#application-issues)
4. [Network & Tailscale Issues](#network--tailscale-issues)
5. [Vocabulary Data Issues](#vocabulary-data-issues)
6. [Performance Issues](#performance-issues)

---

## SSH Connection Issues

### Problem: "Permission denied (publickey)" when connecting to NAS

**Symptoms:**
```
Permission denied (publickey).
```

**Solutions:**

1. **Verify SSH key exists locally:**
   ```bash
   ls -la ~/.ssh/id_ed25519
   ```
   If not found, generate it:
   ```bash
   ./setup-ssh.sh
   ```

2. **Verify public key is on NAS:**
   ```bash
   ssh nas "cat ~/.ssh/authorized_keys | grep $(cat ~/.ssh/id_ed25519.pub)"
   ```
   Should return your public key. If empty, run:
   ```bash
   ./setup-ssh.sh
   ```

3. **Check SSH config is correct:**
   ```bash
   cat ~/.ssh/config | grep -A 5 "Host nas"
   ```
   Should show:
   ```
   Host nas
       HostName 192.168.1.100
       User loklas
       IdentityFile ~/.ssh/id_ed25519
       StrictHostKeyChecking no
   ```

4. **Verify NAS is accessible:**
   ```bash
   ping 192.168.1.100
   ```
   If no response, check network connectivity and NAS IP address.

---

### Problem: "Could not open a connection to your authentication agent" 

**Symptoms:**
```
Could not open a connection to your authentication agent
```

**Solution:**
SSH agent is not running. Start it:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

---

### Problem: SSH timeout after long inactivity

**Symptoms:**
```
ssh_exchange_identification: Connection closed by remote host
```

**Solution:**
Add keep-alive settings to `~/.ssh/config`:
```
Host nas
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

---

## Docker Issues

### Problem: "docker: command not found" 

**Symptoms:**
```
docker: command not found
```

**Solution:**

1. **Verify Docker is installed on NAS:**
   ```bash
   ssh nas "docker --version"
   ```

2. **If not installed, connect to NAS and install:**
   ```bash
   ssh nas
   # Then on NAS:
   curl -sSL https://get.docker.com | sh
   sudo usermod -aG docker loklas
   exit
   # Reconnect
   ssh nas "docker --version"
   ```

---

### Problem: "Cannot connect to Docker daemon"

**Symptoms:**
```
Cannot connect to Docker daemon at unix:///var/run/docker.sock
```

**Solution:**

1. **Check if Docker daemon is running on NAS:**
   ```bash
   ssh nas "sudo systemctl status docker"
   ```

2. **Start Docker if stopped:**
   ```bash
   ssh nas "sudo systemctl start docker"
   ```

3. **Enable auto-start:**
   ```bash
   ssh nas "sudo systemctl enable docker"
   ```

---

### Problem: "Permission denied" when building/running containers

**Symptoms:**
```
permission denied while trying to connect to Docker daemon
```

**Solution:**

1. **Add user to docker group on NAS:**
   ```bash
   ssh nas "sudo usermod -aG docker loklas"
   ```

2. **Log out and back in for changes to take effect:**
   ```bash
   ssh nas "exit"
   # Wait 10 seconds
   ssh nas "id"
   ```
   You should see `docker` in the groups list.

---

### Problem: Port 8500 already in use

**Symptoms:**
```
Error response from daemon: driver failed programming external connectivity
port 8500 is in use
```

**Solution:**

1. **Check what's using port 8500:**
   ```bash
   ssh nas "lsof -i :8500" 
   ```

2. **Stop the existing service or choose another port:**
   - Option A: Stop existing service
     ```bash
     ssh nas "docker stop <container_id>"
     ```
   - Option B: Use different port in `docker-compose.yml`:
     ```yaml
     ports:
       - "8501:8000"  # Changed from 8500
     ```

---

### Problem: "low memory, swap disabled"

**Symptoms:**
```
WARNING: No swap limit support
```

**Solution:**
This is a warning, not an error. Your NAS doesn't support memory limits, which is fine for single-container deployments. The app will still work.

---

## Application Issues

### Problem: "ModuleNotFoundError: No module named 'generate_test'"

**Symptoms:**
```
ModuleNotFoundError: No module named 'generate_test'
```

**Solution:**

1. **Verify files are in Docker image:**
   ```bash
   ssh nas "docker exec nihongo-vocab-test ls -la /app/*.py"
   ```

2. **Check Docker build included all files:**
   ```bash
   cat Dockerfile | grep COPY
   ```
   Should show:
   ```
   COPY generate_test.py .
   COPY correct_test.py .
   ```

3. **Rebuild and redeploy:**
   ```bash
   ./deploy.sh
   ```

---

### Problem: Tests not generating - getting 500 error

**Symptoms:**
- API returns HTTP 500 error
- Browser shows error when requesting test

**Solutions:**

1. **Check application logs:**
   ```bash
   ./nas-commands.sh logs
   ```

2. **Verify vocabulary files exist:**
   ```bash
   ssh nas "ls -la /volume1/docker/nihongo-vocab-test/resources/"
   ```
   Should show `vocabulary_N4.xlsx` and `vocabulary_N5.xlsx`

3. **Check file permissions:**
   ```bash
   ssh nas "ls -la /volume1/docker/nihongo-vocab-test/resources/*.xlsx"
   ```

4. **Verify Python dependencies installed:**
   ```bash
   ./nas-commands.sh shell "pip list | grep -E 'openpyxl|pandas|fastapi'"
   ```

---

### Problem: "Connection refused" when accessing app

**Symptoms:**
- Browser shows "Connection refused" or "Can't reach server"

**Solutions:**

1. **Verify container is running:**
   ```bash
   ./nas-commands.sh ps
   ```
   Should show `nihongo-vocab-test` as running.

2. **Check if port is open:**
   ```bash
   ssh nas "netstat -tlnp | grep 8500"
   ```

3. **View recent container logs:**
   ```bash
   ./nas-commands.sh logs
   ```

4. **Restart container:**
   ```bash
   ./nas-commands.sh restart
   ```

---

### Problem: Application crashes after deployment

**Symptoms:**
- Container exits immediately
- `./nas-commands.sh ps` shows container not running

**Solutions:**

1. **Check error logs:**
   ```bash
   ./nas-commands.sh logs --tail=50
   ```

2. **Common causes and fixes:**

   **Missing dependencies:**
   ```bash
   # Rebuild with updated requirements
   ./deploy.sh
   ```

   **Permission issue with output directory:**
   ```bash
   ssh nas "chmod 777 /volume1/docker/nihongo-vocab-test/output"
   ```

   **Corrupt vocabulary files:**
   ```bash
   # Redownload or check file integrity
   ssh nas "file /volume1/docker/nihongo-vocab-test/resources/*.xlsx"
   ```

---

## Network & Tailscale Issues

### Problem: Can't access app via Tailscale

**Symptoms:**
- Can reach `https://nihongo.your-domain.ts.net` in browser but page won't load
- Timeout or connection refused

**Solutions:**

1. **Verify Tailscale is running on NAS:**
   ```bash
   ssh nas "sudo systemctl status tailscaled"
   ```

2. **Start Tailscale if stopped:**
   ```bash
   ssh nas "sudo systemctl start tailscaled"
   ```

3. **Check Tailscale connection status:**
   ```bash
   ssh nas "tailscale status"
   ```

4. **Verify DNS resolution:**
   ```bash
   nslookup nihongo.your-domain.ts.net
   ```

5. **Test connectivity to NAS via Tailscale IP:**
   ```bash
   ping $(ssh nas "tailscale ip -4")
   ```

---

### Problem: Tailscale custom domain not working

**Symptoms:**
- Custom domain not resolving
- DNS lookup fails for `nihongo.your-domain.ts.net`

**Solutions:**

1. **Check Tailscale machine name:**
   ```bash
   ssh nas "tailscale status | grep 'local='
   ```

2. **Verify Funnel is enabled (if using Funnel for public access):**
   ```bash
   ssh nas "tailscale funnel status"
   ```

3. **Reconfigure custom domain in Tailscale admin panel:**
   - Go to https://login.tailscale.com/admin/dns
   - Verify machine name matches
   - Try disabling and re-enabling custom domain

---

### Problem: "Forbidden" error when accessing via Tailscale

**Symptoms:**
```
403 Forbidden
You don't have permission to access this resource
```

**Solution:**
This is likely an ACL (Access Control List) issue. Check your Tailscale ACL policy:
- Go to https://login.tailscale.com/admin/acls
- Verify your device has permission to access the NAS

---

## Vocabulary Data Issues

### Problem: Excel files not found or can't be read

**Symptoms:**
- 500 error when requesting test
- "No such file" in logs
- Vocabulary N4/N5 not appearing

**Solutions:**

1. **Verify files exist with correct names:**
   ```bash
   ssh nas "ls -la /volume1/docker/nihongo-vocab-test/resources/"
   ```
   Files must be named exactly:
   - `vocabulary_N4.xlsx`
   - `vocabulary_N5.xlsx`

2. **Check file format is actually Excel:**
   ```bash
   ssh nas "file /volume1/docker/nihongo-vocab-test/resources/*.xlsx"
   ```
   Should return: `Microsoft Excel 2007+`

3. **Verify file is not corrupted:**
   ```bash
   ssh nas "unzip -t /volume1/docker/nihongo-vocab-test/resources/vocabulary_N4.xlsx"
   ```
   Should not show errors.

4. **Check file permissions:**
   ```bash
   ssh nas "chmod 644 /volume1/docker/nihongo-vocab-test/resources/*.xlsx"
   ```

---

### Problem: Excel parsing error - "Can't find worksheet"

**Symptoms:**
```
Error reading Excel file: Sheet 'vocabulary' not found
```

**Solution:**

1. **Check sheet names in Excel file:**
   ```bash
   ssh nas "python3 -c \"import openpyxl; wb = openpyxl.load_workbook('/volume1/docker/nihongo-vocab-test/resources/vocabulary_N4.xlsx'); print(wb.sheetnames)\""
   ```

2. **Update sheet name in `generate_test.py`:**
   Edit line with `sheet_name=` parameter to match actual sheet name.

---

## Performance Issues

### Problem: App is slow or times out generating tests

**Symptoms:**
- Takes 10+ seconds to generate a test
- Browser shows "Loading..." for long time
- Timeout errors

**Solutions:**

1. **Check NAS CPU usage:**
   ```bash
   ssh nas "top -bn1 | head -10"
   ```

2. **Check available memory:**
   ```bash
   ssh nas "free -h"
   ```

3. **Reduce vocabulary set size:**
   - If using full N4 list (1200+ words), consider creating smaller subsets
   - Modify `generate_test.py` to limit to recent entries

4. **Check disk I/O:**
   ```bash
   ssh nas "iostat -x 1 3"
   ```

5. **Optimize Excel reading:**
   - Ensure Excel files are not huge (should be <5MB)
   - Consider using CSV format if performance is critical

---

### Problem: Memory usage keeps growing

**Symptoms:**
- Memory usage increases after each test
- Eventually runs out of memory

**Solution:**

1. **Restart container to free memory:**
   ```bash
   ./nas-commands.sh restart
   ```

2. **Check for memory leaks in logs:**
   ```bash
   ./nas-commands.sh logs --tail=100 | grep -i memory
   ```

3. **Consider setting container memory limit in `docker-compose.yml`:**
   ```yaml
   services:
     nihongo-vocab-app:
       mem_limit: 512m
   ```

---

## Emergency Recovery

### Problem: Everything is broken, need to restart from scratch

**Solution:**

1. **Remove old container and volumes:**
   ```bash
   ssh nas "docker stop nihongo-vocab-test || true"
   ssh nas "docker rm nihongo-vocab-test || true"
   ```

2. **Remove old image:**
   ```bash
   ssh nas "docker rmi nihongo-vocab-test:latest || true"
   ```

3. **Redeploy from scratch:**
   ```bash
   ./deploy.sh
   ```

---

## Getting Help

If you encounter an issue not covered here:

1. **Collect diagnostic information:**
   ```bash
   ./nas-commands.sh logs --tail=50 > logs.txt
   ssh nas "docker system df" > docker-df.txt
   ssh nas "free -h" > memory.txt
   ```

2. **Check GitHub issues:**
   https://github.com/SebastienBobbia/nihongo-vocab-test/issues

3. **Report the issue with:**
   - Error message and logs
   - Steps to reproduce
   - Output from diagnostic commands above
   - NAS model and OS version

