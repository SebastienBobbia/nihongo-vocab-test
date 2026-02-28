#!/bin/bash
# ============================================================================
# Script de configuration SSH automatisée pour UGREEN NAS
# ============================================================================
# Usage: bash setup-ssh.sh <user> <nas-ip> <nas-domain>
# Exemple: bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net
# ============================================================================

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# ============================================================================
# Validation des arguments
# ============================================================================

if [ $# -lt 2 ]; then
    echo -e "${YELLOW}Usage: bash setup-ssh.sh <user> <nas-ip> [nas-domain]${NC}"
    echo -e "${YELLOW}Exemple: bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net${NC}"
    exit 1
fi

NAS_USER="$1"
NAS_IP="$2"
NAS_DOMAIN="${3:-}"

print_header "Configuration SSH pour UGREEN NAS"

echo "Configuration détectée :"
echo "  • User: $NAS_USER"
echo "  • IP: $NAS_IP"
if [ -n "$NAS_DOMAIN" ]; then
    echo "  • Domaine Tailscale: $NAS_DOMAIN"
fi

# ============================================================================
# Étape 1 : Générer une clé SSH si elle n'existe pas
# ============================================================================

print_header "Étape 1 : Vérifier/Générer clé SSH"

SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_PUB="$SSH_KEY.pub"

if [ -f "$SSH_KEY" ]; then
    print_success "Clé SSH trouvée: $SSH_KEY"
else
    print_warning "Clé SSH non trouvée. Génération..."
    mkdir -p ~/.ssh
    ssh-keygen -t ed25519 -C "$NAS_USER@nas" -f "$SSH_KEY" -N ""
    print_success "Clé SSH créée"
fi

# ============================================================================
# Étape 2 : Copier la clé sur le NAS
# ============================================================================

print_header "Étape 2 : Copier la clé sur le NAS"

echo "Tentative de copie de la clé SSH sur le NAS..."
echo "(Vous devrez entrer le mot de passe du NAS UNE FOIS)"

if ssh-copy-id -i "$SSH_PUB" "$NAS_USER@$NAS_IP" 2>/dev/null; then
    print_success "Clé SSH copiée sur le NAS"
else
    print_error "Impossible de copier la clé automatiquement"
    echo ""
    echo "Pour copier manuellement :"
    echo "1. Sur votre ordinateur, afficher la clé :"
    echo "   cat $SSH_PUB"
    echo ""
    echo "2. Se connecter au NAS :"
    echo "   ssh $NAS_USER@$NAS_IP"
    echo ""
    echo "3. Sur le NAS, ajouter la clé :"
    echo "   mkdir -p ~/.ssh"
    echo "   nano ~/.ssh/authorized_keys"
    echo "   # Coller la clé, Ctrl+X, Y, Entrée"
    echo ""
    echo "4. Fixer les permissions :"
    echo "   chmod 600 ~/.ssh/authorized_keys"
    echo "   chmod 700 ~/.ssh"
    exit 1
fi

# ============================================================================
# Étape 3 : Tester la connexion
# ============================================================================

print_header "Étape 3 : Tester la connexion SSH"

echo "Test de connexion sans mot de passe..."

if ssh -o StrictHostKeyChecking=no "$NAS_USER@$NAS_IP" "echo 'SSH OK'" > /dev/null 2>&1; then
    print_success "Connexion SSH fonctionnelle sans mot de passe"
else
    print_error "Impossible de se connecter sans mot de passe"
    echo "Vérifier:"
    echo "  ssh $NAS_USER@$NAS_IP 'ls -la ~/.ssh/'"
    exit 1
fi

# ============================================================================
# Étape 4 : Créer l'alias SSH dans ~/.ssh/config
# ============================================================================

print_header "Étape 4 : Créer alias SSH"

SSH_CONFIG="$HOME/.ssh/config"

# Créer le fichier s'il n'existe pas
if [ ! -f "$SSH_CONFIG" ]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

# Vérifier si les alias existent déjà
if grep -q "Host nas$" "$SSH_CONFIG"; then
    print_warning "Alias 'nas' existe déjà dans ~/.ssh/config"
else
    cat >> "$SSH_CONFIG" << EOF

# UGREEN NAS (ajouté par setup-ssh.sh)
Host nas
    HostName $NAS_IP
    User $NAS_USER
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

EOF
    print_success "Alias 'nas' créé dans ~/.ssh/config"
fi

# Ajouter l'alias Tailscale si domaine fourni
if [ -n "$NAS_DOMAIN" ]; then
    if grep -q "Host nas-tailscale$" "$SSH_CONFIG"; then
        print_warning "Alias 'nas-tailscale' existe déjà dans ~/.ssh/config"
    else
        cat >> "$SSH_CONFIG" << EOF
Host nas-tailscale
    HostName $NAS_DOMAIN
    User $NAS_USER
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

EOF
        print_success "Alias 'nas-tailscale' créé dans ~/.ssh/config"
    fi
fi

# ============================================================================
# Étape 5 : Tester les alias
# ============================================================================

print_header "Étape 5 : Tester les alias SSH"

if ssh -q nas "echo OK" > /dev/null 2>&1; then
    print_success "Alias 'nas' fonctionne"
else
    print_error "Alias 'nas' ne fonctionne pas"
fi

if [ -n "$NAS_DOMAIN" ]; then
    if ssh -q nas-tailscale "echo OK" > /dev/null 2>&1; then
        print_success "Alias 'nas-tailscale' fonctionne"
    else
        print_warning "Alias 'nas-tailscale' ne fonctionne pas (Tailscale peut ne pas être connecté)"
    fi
fi

# ============================================================================
# Étape 6 : Créer le script de commandes utiles
# ============================================================================

print_header "Étape 6 : Créer les scripts helper"

HELPER_SCRIPT="$(pwd)/nas-commands.sh"

cat > "$HELPER_SCRIPT" << 'SCRIPT_EOF'
#!/bin/bash
# Commandes helper pour interagir avec le NAS

case "$1" in
  ip)
    echo "IP Tailscale du NAS :"
    ssh nas "tailscale ip -4" ;;
  logs)
    ssh nas "cd /volume1/docker/nihongo-vocab-test && docker-compose logs -f" ;;
  restart)
    ssh nas "cd /volume1/docker/nihongo-vocab-test && docker-compose restart"
    echo "✓ Application redémarrée" ;;
  stop)
    ssh nas "cd /volume1/docker/nihongo-vocab-test && docker-compose down"
    echo "✓ Application arrêtée" ;;
  start)
    ssh nas "cd /volume1/docker/nihongo-vocab-test && docker-compose up -d"
    echo "✓ Application démarrée" ;;
  shell)
    ssh nas ;;
  deploy)
    ssh nas << 'DEPLOY_EOF'
cd /tmp
curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/deploy.sh
chmod +x deploy.sh
bash deploy.sh
DEPLOY_EOF
    ;;
  *)
    echo "Commandes disponibles :"
    echo "  nas-commands.sh ip       - Voir l'IP Tailscale"
    echo "  nas-commands.sh logs     - Voir les logs en temps réel"
    echo "  nas-commands.sh restart  - Redémarrer l'application"
    echo "  nas-commands.sh stop     - Arrêter l'application"
    echo "  nas-commands.sh start    - Démarrer l'application"
    echo "  nas-commands.sh shell    - Connexion SSH shell"
    echo "  nas-commands.sh deploy   - Déployer l'application"
    ;;
esac
SCRIPT_EOF

chmod +x "$HELPER_SCRIPT"
print_success "Script helper créé: $HELPER_SCRIPT"

# ============================================================================
# Résumé final
# ============================================================================

print_header "Configuration terminée avec succès!"

echo -e "${GREEN}🎉 SSH est maintenant configuré!${NC}\n"

echo "Vous pouvez maintenant utiliser :"
echo ""
echo "  ${BLUE}Connexion SSH simple${NC}"
echo "    ssh nas                    # Connexion locale"
if [ -n "$NAS_DOMAIN" ]; then
    echo "    ssh nas-tailscale          # Connexion via Tailscale"
fi
echo ""
echo "  ${BLUE}Commandes rapides${NC}"
echo "    ./nas-commands.sh ip       # IP Tailscale"
echo "    ./nas-commands.sh logs     # Voir les logs"
echo "    ./nas-commands.sh deploy   # Déployer l'app"
echo "    ./nas-commands.sh restart  # Redémarrer l'app"
echo ""
echo "  ${BLUE}Déploiement direct${NC}"
echo "    ssh nas 'cd /tmp && curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/deploy.sh && bash deploy.sh'"
echo ""
echo -e "${YELLOW}ℹ Aucun mot de passe requis - tout fonctionne avec les clés SSH!${NC}\n"
