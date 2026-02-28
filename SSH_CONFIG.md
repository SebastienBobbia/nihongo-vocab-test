# 🔐 Configuration SSH Sécurisée pour UGREEN NAS

## 🎯 Pourquoi les clés SSH ?

- ✅ **Pas de mot de passe en clair** à mémoriser ou stocker
- ✅ **Pas de credential Git** (donc rien à commiter)
- ✅ **Connexion automatique** - `ssh nas` sans taper quoi que ce soit
- ✅ **Plus sécurisé** que les mots de passe
- ✅ **Standard industrie** (utilisé partout)

---

## **Étape 1 : Générer une clé SSH (sur votre ordinateur)**

### Sur macOS/Linux
```bash
# Générer une clé SSH (garder le chemin par défaut)
ssh-keygen -t ed25519 -C "sebastien@nihongo-test"

# Questions :
# - Enter file: [appuyez sur Entrée - chemin par défaut]
# - Enter passphrase: [entrez une passphrase ou laissez vide]
# - Confirm passphrase: [confirmez]
```

### Sur Windows (PowerShell)
```powershell
# Générer la clé
ssh-keygen -t ed25519 -C "sebastien@nihongo-test"

# Ou installer OpenSSH si pas disponible :
# Settings → System → Optional features → "OpenSSH Client" → Install
```

**Résultat :**
```
Generating public/private ed25519 key pair.
Your public key has been saved in ~/.ssh/id_ed25519.pub
Your private key has been saved in ~/.ssh/id_ed25519
```

---

## **Étape 2 : Copier la clé sur le NAS**

### Option A : Automatiquement (recommandé)

```bash
# Sur votre ordinateur - une commande !
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@<ip-nas>

# Exemple
ssh-copy-id -i ~/.ssh/id_ed25519.pub loklas@192.168.1.100
```

Vous devrez taper le mot de passe UNE FOIS, c'est tout.

### Option B : Manuellement

Si `ssh-copy-id` ne fonctionne pas sur Windows :

```bash
# 1. Afficher votre clé publique
cat ~/.ssh/id_ed25519.pub

# 2. Copier le contenu (ex: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... loklas@nas)

# 3. Sur le NAS via SSH
ssh loklas@<ip-nas>
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
# Coller la clé, Ctrl+X, Y, Entrée

# 4. Fixer les permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
exit
```

---

## **Étape 3 : Tester la connexion sans mot de passe**

```bash
ssh user@<ip-nas>

# Ça devrait se connecter SANS demander de mot de passe !
```

Si ça demande le mot de passe, vérifier :
```bash
# Sur le NAS
ssh-keygen -l -f ~/.ssh/authorized_keys
# Devrait afficher votre clé publique

# Vérifier les permissions
ls -la ~/.ssh/
# authorized_keys doit être 600
# .ssh/ doit être 700
```

---

## **Étape 4 : Créer un alias SSH (TRÈS pratique)**

Créer un fichier `~/.ssh/config` pour simplifier :

### macOS/Linux
```bash
nano ~/.ssh/config
```

### Windows (PowerShell)
```powershell
notepad "$env:USERPROFILE\.ssh\config"
```

### Contenu du fichier
```
Host nas
    HostName <ip-nas>
    User loklas
    IdentityFile ~/.ssh/id_ed25519
    
Host nas-tailscale
    HostName <votre-domaine-tailscale>
    User loklas
    IdentityFile ~/.ssh/id_ed25519
```

**Maintenant vous pouvez :**
```bash
ssh nas                    # Connexion locale
ssh nas-tailscale          # Via Tailscale

# Et même
scp nas:/tmp/file.txt .    # Copier des fichiers
```

---

## **Étape 5 : Automatiser le déploiement avec la clé**

Créer un script `deploy-to-nas.sh` sur votre ordinateur :

```bash
#!/bin/bash

# Script de déploiement automatisé via SSH

NAS_HOST="nas"  # Utilise l'alias SSH config
DEPLOY_PATH="/volume1/docker"

echo "🚀 Déploiement sur le NAS via SSH..."

# Exécuter le déploiement automatique sur le NAS
ssh $NAS_HOST << 'EOF'
cd /tmp
curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/deploy.sh
chmod +x deploy.sh
bash deploy.sh
EOF

echo "✅ Déploiement terminé !"
echo ""
echo "Accédez à l'application via :"
echo "  - Tailscale: http://<votre-domaine>:8500"
echo "  - Ou trouvez l'IP avec: ssh nas tailscale ip -4"
```

**Utilisation :**
```bash
chmod +x deploy-to-nas.sh
./deploy-to-nas.sh
```

---

## 🔒 **Sécurité - Ne JAMAIS commiter**

### Ajouter au `.gitignore` (déjà devrait être présent)

```bash
# Vérifier votre .gitignore
cat .gitignore
```

Il devrait contenir :
```
# Credentials
*.pem
*.key
.env
.env.local
credentials.json

# SSH
.ssh/
id_rsa*
id_ed25519*
```

### Vérifier que rien n'a été committé
```bash
git log --all --full-history -- "*id_ed25519*"
git log --all --full-history -- "*.pem"
```

Si quelque chose a été accidentellement committé :
```bash
# C'est ok, Git a l'historique. Pour nettoyer :
git filter-branch --tree-filter 'rm -f id_ed25519*' HEAD
# (À ne faire que si vraiment nécessaire)
```

---

## 📋 **Checklist**

- [ ] Généré une clé SSH localement
- [ ] Copié la clé sur le NAS
- [ ] Testé `ssh user@<ip-nas>` sans mot de passe
- [ ] Créé l'alias SSH dans `~/.ssh/config`
- [ ] Testé `ssh nas` (fonctionne)
- [ ] Vérifier `.gitignore` contient les fichiers sensibles
- [ ] Vérifier aucune clé n'a été committée

---

## 🚀 **Désormais**

```bash
# Connexion simple
ssh nas

# Déploiement simple
ssh nas "cd /tmp && curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/deploy.sh && chmod +x deploy.sh && bash deploy.sh"

# Ou avec le script local
./deploy-to-nas.sh

# Consulter les logs
ssh nas "cd /volume1/docker/nihongo-vocab-test && docker-compose logs -f"

# Voir l'IP Tailscale
ssh nas "tailscale ip -4"
```

---

## 🆘 **Dépannage**

### "Permission denied (publickey)"
```bash
# La clé n'est pas au bon endroit sur le NAS
# Vérifier :
ssh nas "ls -la ~/.ssh/authorized_keys"

# Si fichier n'existe pas, le recréer manuellement (voir Étape 2 Option B)
```

### "Connection refused"
```bash
# SSH n'est pas lancé sur le NAS
# Vérifier que vous pouvez vous connecter avec mot de passe d'abord
ssh -o PubkeyAuthentication=no loklas@<ip-nas>
```

### Windows : "command not found: ssh-keygen"
```powershell
# SSH n'est pas installé
# Settings → System → Optional features → Search "OpenSSH" → Install
```

---

## 💡 **Bonus : Script multi-commandes**

Créer `nas-commands.sh` pour utiliser commune alias :

```bash
#!/bin/bash

case "$1" in
  logs)
    ssh nas "cd /volume1/docker/nihongo-vocab-test && docker-compose logs -f" ;;
  restart)
    ssh nas "cd /volume1/docker/nihongo-vocab-test && docker-compose restart" ;;
  ip)
    ssh nas "tailscale ip -4" ;;
  shell)
    ssh nas ;;
  deploy)
    ssh nas "cd /tmp && curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/deploy.sh && chmod +x deploy.sh && bash deploy.sh" ;;
  *)
    echo "Usage: $0 {logs|restart|ip|shell|deploy}"
    ;;
esac
```

**Utilisation :**
```bash
chmod +x nas-commands.sh

./nas-commands.sh ip          # Voir l'IP Tailscale
./nas-commands.sh logs        # Voir les logs
./nas-commands.sh restart     # Redémarrer l'app
./nas-commands.sh shell       # Connexion SSH
./nas-commands.sh deploy      # Déploiement automatique
```

---

**Voilà !** Vous avez une configuration SSH complètement sécurisée, rien à stocker, et tout automatisé ! 🔐
