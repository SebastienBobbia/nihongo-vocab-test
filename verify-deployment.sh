#!/bin/bash

# verify-deployment.sh - Pre-deployment verification script

CHECKS_PASSED=0
CHECKS_FAILED=0

print_header() {
    echo ""
    echo "=== $1 ==="
    echo ""
}

check_pass() {
    echo "[PASS] $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo "[FAIL] $1"
    ((CHECKS_FAILED++))
}

check_warn() {
    echo "[WARN] $1"
}

# Main verification
print_header "Local Environment Checks"

# Check git
if git rev-parse --git-dir > /dev/null 2>&1; then
    check_pass "Git repository initialized"
else
    check_fail "Not a git repository"
fi

# Check required files
print_header "Required Files Check"

required_files=(
    "Dockerfile"
    "docker-compose.yml"
    "requirements.txt"
    "web/app.py"
    "generate_test.py"
    "correct_test.py"
    "resources/vocabulary_N4.xlsx"
    "resources/vocabulary_N5.xlsx"
    "setup-ssh.sh"
    "deploy.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        check_pass "Found: $file"
    else
        check_fail "Missing: $file"
    fi
done

# Check SSH setup
print_header "SSH Configuration Check"

if [ -f ~/.ssh/id_ed25519 ]; then
    check_pass "SSH private key exists (~/.ssh/id_ed25519)"
else
    check_warn "SSH private key not found - run: ./setup-ssh.sh"
fi

if [ -f ~/.ssh/config ]; then
    if grep -q "Host nas" ~/.ssh/config; then
        check_pass "SSH config has 'nas' host entry"
    else
        check_warn "SSH config missing 'nas' host entry"
    fi
else
    check_warn "SSH config not found (~/.ssh/config)"
fi

# Check network connectivity
print_header "Network Connectivity Check"

if command -v ping &> /dev/null; then
    if timeout 5 ping -c 1 192.168.1.100 &> /dev/null; then
        check_pass "NAS is reachable (192.168.1.100)"
    else
        check_warn "NAS not reachable at 192.168.1.100 (may be offline or wrong IP)"
    fi
else
    check_warn "ping command not available - skipping connectivity test"
fi

# Test SSH connection
if timeout 10 ssh -o ConnectTimeout=5 nas "echo OK" &> /dev/null 2>&1; then
    check_pass "SSH connection to NAS works"
    
    # Check Docker on NAS
    if timeout 10 ssh nas "docker --version" &> /dev/null 2>&1; then
        check_pass "Docker is installed on NAS"
    else
        check_warn "Docker not found on NAS - install with: ssh nas 'curl -sSL https://get.docker.com | sh'"
    fi
    
    # Check deployment directory
    if timeout 10 ssh nas "test -d /volume1/docker" &> /dev/null 2>&1; then
        check_pass "Deployment directory exists (/volume1/docker)"
    else
        check_fail "Deployment directory not found (/volume1/docker)"
    fi
else
    check_warn "Cannot SSH to NAS - ensure setup-ssh.sh has been run"
fi

# Check Python locally
print_header "Python Check"

if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1 | awk '{print $2}')
    check_pass "Python 3 installed (v${python_version})"
else
    check_warn "Python 3 not installed locally"
fi

# Check Docker configuration
print_header "Docker Configuration Check"

if grep -q "8500:8000" docker-compose.yml; then
    check_pass "Port mapping configured: 8500:8000"
else
    check_fail "Port mapping not configured correctly"
fi

if grep -q "volumes:" docker-compose.yml; then
    check_pass "Volume mounts configured"
else
    check_fail "Volume mounts not configured"
fi

# Check web app
print_header "Web Application Check"

if [ -f web/app.py ]; then
    if python3 -m py_compile web/app.py 2>/dev/null; then
        check_pass "web/app.py syntax is valid"
    else
        check_fail "web/app.py has syntax errors"
    fi
fi

if [ -f web/static/index.html ]; then
    check_pass "Frontend file found: web/static/index.html"
fi

if [ -f web/static/app.js ]; then
    check_pass "Frontend script found: web/static/app.js"
fi

# Check vocabulary data
print_header "Vocabulary Data Check"

if [ -f resources/vocabulary_N4.xlsx ]; then
    size=$(du -h resources/vocabulary_N4.xlsx | awk '{print $1}')
    check_pass "Vocabulary file exists: vocabulary_N4.xlsx (${size})"
else
    check_fail "Vocabulary file missing: vocabulary_N4.xlsx"
fi

if [ -f resources/vocabulary_N5.xlsx ]; then
    size=$(du -h resources/vocabulary_N5.xlsx | awk '{print $1}')
    check_pass "Vocabulary file exists: vocabulary_N5.xlsx (${size})"
else
    check_fail "Vocabulary file missing: vocabulary_N5.xlsx"
fi

# Summary
print_header "Summary"

total=$((CHECKS_PASSED + CHECKS_FAILED))
echo "Passed: $CHECKS_PASSED"
echo "Failed: $CHECKS_FAILED"
echo "Total:  $total"

if [ $CHECKS_FAILED -eq 0 ]; then
    echo ""
    echo "SUCCESS - All checks passed! Ready to deploy."
    echo ""
    echo "Next steps:"
    echo "  1. Review deployment: cat deploy.sh"
    echo "  2. Start deployment: ./deploy.sh"
    echo "  3. Monitor logs: ./nas-commands.sh logs"
    exit 0
else
    echo ""
    echo "FAILURE - Some checks failed. Please review and fix issues."
    echo ""
    echo "Common fixes:"
    echo "  • Run SSH setup: ./setup-ssh.sh"
    echo "  • Install Docker on NAS: ssh nas 'curl -sSL https://get.docker.com | sh'"
    echo "  • Check network: ping 192.168.1.100"
    exit 1
fi
