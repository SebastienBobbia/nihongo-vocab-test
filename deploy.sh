#!/bin/bash
# ============================================================================
# Script de déploiement automatisé pour UGREEN DXP2800
# ============================================================================
# Usage: bash deploy.sh
# ============================================================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_PATH="/volume1/docker"
PROJECT_NAME="nihongo-vocab-test"
REPO_URL="https://github.com/SebastienBobbia/nihongo-vocab-test.git"
PORT="8500"

# ============================================================================
# Fonctions utilitaires
# ============================================================================

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Vérifications préalables
# ============================================================================

print_header "Vérification des prérequis"

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker n'est pas installé"
    exit 1
fi
print_success "Docker trouvé: $(docker --version)"

# Vérifier docker-compose
if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose n'est pas installé"
    exit 1
fi
print_success "docker-compose trouvé: $(docker-compose --version)"

# Vérifier git
if ! command -v git &> /dev/null; then
    print_error "Git n'est pas installé"
    exit 1
fi
print_success "Git trouvé"

# Vérifier l'espace disque
AVAILABLE_SPACE=$(df /volume1 | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt 2097152 ]; then  # 2GB en KB
    print_warning "Moins de 2GB disponibles sur /volume1"
else
    print_success "Espace disque suffisant: $(numfmt --to=iec $((AVAILABLE_SPACE * 1024)) 2>/dev/null || echo '${AVAILABLE_SPACE}KB')"
fi

# ============================================================================
# Création et navigation vers le dossier de déploiement
# ============================================================================

print_header "Préparation du répertoire de déploiement"

if [ ! -d "$DEPLOY_PATH" ]; then
    print_info "Création du répertoire $DEPLOY_PATH"
    mkdir -p "$DEPLOY_PATH"
    print_success "Répertoire créé"
else
    print_success "Répertoire $DEPLOY_PATH existe déjà"
fi

cd "$DEPLOY_PATH"
print_success "Navigué vers $DEPLOY_PATH"

# ============================================================================
# Clonage du repository
# ============================================================================

print_header "Clonage du repository"

if [ -d "$PROJECT_NAME" ]; then
    print_info "Le projet existe déjà. Mise à jour..."
    cd "$PROJECT_NAME"
    git pull origin main
    print_success "Repository mis à jour"
else
    print_info "Clonage du repository..."
    git clone "$REPO_URL" "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    print_success "Repository cloné"
fi

# ============================================================================
# Vérification de la structure
# ============================================================================

print_header "Vérification de la structure du projet"

REQUIRED_FILES=("docker-compose.yml" "Dockerfile" "requirements.txt" "config.py" "generate_test.py" "correct_test.py")

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file trouvé"
    else
        print_error "$file manquant"
        exit 1
    fi
done

# Vérifier les fichiers de ressources
if [ -d "resources" ] && [ -f "resources/vocabulary_N4.xlsx" ] && [ -f "resources/vocabulary_N5.xlsx" ]; then
    print_success "Fichiers de vocabulaire trouvés"
else
    print_error "Fichiers de vocabulaire manquants"
    exit 1
fi

# ============================================================================
# Création des répertoires de sortie
# ============================================================================

print_header "Création des répertoires de sortie"

mkdir -p output/N4 output/N5
print_success "Répertoires output créés"

# ============================================================================
# Construction de l'image Docker
# ============================================================================

print_header "Construction de l'image Docker"

print_info "Ceci peut prendre 2-5 minutes..."
docker-compose build

if [ $? -eq 0 ]; then
    print_success "Image construite avec succès"
else
    print_error "Échec de la construction de l'image"
    exit 1
fi

# ============================================================================
# Lancement du container
# ============================================================================

print_header "Lancement du container"

docker-compose down 2>/dev/null || true
print_info "Ancien container arrêté"

docker-compose up -d

if [ $? -eq 0 ]; then
    print_success "Container lancé"
else
    print_error "Échec du lancement du container"
    exit 1
fi

# ============================================================================
# Attendre que le service démarre
# ============================================================================

print_header "Attente du démarrage du service"

RETRIES=0
MAX_RETRIES=30

while [ $RETRIES -lt $MAX_RETRIES ]; do
    print_info "Tentative $((RETRIES + 1))/$MAX_RETRIES..."
    
    if docker-compose exec nihongo-vocab-app curl -s http://localhost:8000/health > /dev/null 2>&1; then
        print_success "Service démarré et réactif"
        break
    fi
    
    RETRIES=$((RETRIES + 1))
    sleep 1
done

if [ $RETRIES -eq $MAX_RETRIES ]; then
    print_warning "Le service met du temps à démarrer. Vérification des logs..."
    docker-compose logs
fi

# ============================================================================
# Vérifications post-déploiement
# ============================================================================

print_header "Vérifications post-déploiement"

# Vérifier l'état du container
CONTAINER_STATUS=$(docker-compose ps | grep nihongo-vocab-test)
if echo "$CONTAINER_STATUS" | grep -q "Up"; then
    print_success "Container en cours d'exécution"
else
    print_error "Container n'est pas en cours d'exécution"
    docker-compose logs
    exit 1
fi

# Tester l'API
print_info "Test de l'API..."
API_RESPONSE=$(curl -s http://localhost:8000/health)
if echo "$API_RESPONSE" | grep -q "ok"; then
    print_success "API réactive"
else
    print_error "API ne répond pas correctement"
fi

# ============================================================================
# Information de connexion
# ============================================================================

print_header "Déploiement terminé avec succès!"

# Essayer de trouver les IPs
TAILSCALE_IP=$(ip addr show tailscale0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "IP Tailscale non trouvée")
NAS_IP=$(hostname -I | awk '{print $1}' || echo "IP NAS non trouvée")

echo -e "${GREEN}🎉 L'application est maintenant déployée!${NC}\n"

echo -e "${YELLOW}Configuration:${NC}"
echo "  • Chemin: $DEPLOY_PATH/$PROJECT_NAME"
echo "  • Port: $PORT"
echo "  • Container: nihongo-vocab-test"

echo -e "\n${YELLOW}Accès depuis iPhone via Tailscale:${NC}"
echo "  • Domaine: http://<votre-domaine-tailscale>:$PORT"
echo "  • IP Tailscale: http://$TAILSCALE_IP:$PORT"

echo -e "\n${YELLOW}Accès local sur le NAS:${NC}"
echo "  • http://localhost:$PORT"
echo "  • http://$NAS_IP:$PORT"

echo -e "\n${YELLOW}Commandes utiles:${NC}"
echo "  • Voir les logs: docker-compose -f $DEPLOY_PATH/$PROJECT_NAME/docker-compose.yml logs -f"
echo "  • Arrêter: docker-compose -f $DEPLOY_PATH/$PROJECT_NAME/docker-compose.yml down"
echo "  • Redémarrer: docker-compose -f $DEPLOY_PATH/$PROJECT_NAME/docker-compose.yml restart"

echo -e "\n${BLUE}💡 Conseil: Ajoutez l'URL à l'écran d'accueil de votre iPhone!${NC}\n"
