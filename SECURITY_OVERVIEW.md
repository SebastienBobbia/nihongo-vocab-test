# 🔒 Setup Complet & Sécurisé - Vue d'ensemble

## ✅ Ce qui a été mis en place

Vous avez maintenant une **solution complète et sécurisée** pour :
1. **Accéder au NAS** sans mot de passe (clés SSH)
2. **Déployer l'app** automatiquement 
3. **Gérer les secrets** correctement (rien dans Git)
4. **Accéder depuis iPhone** via Tailscale
5. **Gérer facilement** l'app avec des scripts helper

---

## 🚀 Pour déployer (première fois)

### Sur votre ordinateur

```bash
# 1. Configurer SSH (une fois)
curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/setup-ssh.sh
bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net

# 2. Déployer l'app sur le NAS
./nas-commands.sh deploy

# Ou en une ligne
ssh nas "cd /tmp && curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/deploy.sh && bash deploy.sh"
```

### C'est tout ! ✓

---

## 📱 Accéder depuis iPhone

```
Safari → http://<votre-domaine-tailscale>:8500
```

Ou trouvez l'IP :
```bash
./nas-commands.sh ip
```

---

## 🎯 Commandes quotidiennes

```bash
# Voir l'adresse IP Tailscale
./nas-commands.sh ip

# Voir les logs en temps réel
./nas-commands.sh logs

# Redémarrer l'app
./nas-commands.sh restart

# Arrêter/Démarrer
./nas-commands.sh stop
./nas-commands.sh start

# Connexion SSH directe
./nas-commands.sh shell
# Ou simplement : ssh nas
```

---

## 🔐 Sécurité : Ce qui est protégé

### ✅ Jamais committé dans Git

```
❌ id_rsa, id_ed25519 (clés privées SSH)
❌ .env, .env.local (variables d'environnement)
❌ credentials.json (identifiants)
❌ passwords (mots de passe)
❌ tokens (tokens API)
```

### ✅ Protégé par .gitignore amélioré

Tout est configuré pour que :
- Aucune clé SSH ne soit committée
- Aucun mot de passe ne soit stocké
- Aucun token API ne soit exposé

### Vérifier (aucune secret dans Git)

```bash
# Cette commande ne devrait retourner RIEN
git log --all --full-history -- "*id_rsa*" "*id_ed25519*" ".env*"
```

---

## 📋 Structure finale

```
nihongo-vocab-test/
├── deploy.sh                    # Déploiement sur NAS
├── setup-ssh.sh                 # Configuration SSH automatisée
├── nas-commands.sh              # Scripts helper (généré)
├── .gitignore                   # Protège les secrets
├── SSH_CONFIG.md                # Guide SSH complet
├── SSH_QUICK.md                 # Guide SSH rapide
├── DEPLOY_UGREEN.md             # Guide UGREEN NAS
├── DEPLOY_QUICK.md              # Déploiement rapide
├── docker-compose.yml           # Docker config (port 8500)
├── Dockerfile                   # Image Docker
├── web/                         # App web
│   └── static/
│       ├── index.html
│       ├── app.js
│       └── style.css
└── resources/
    ├── vocabulary_N4.xlsx
    └── vocabulary_N5.xlsx
```

---

## 🔄 Workflow complet

### 1️⃣ **Installation initiale** (une fois)

```bash
# Sur votre ordinateur
bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net

# Vérifier
ssh nas "echo OK"  # ✓ Doit afficher "OK"
```

### 2️⃣ **Déploiement initial** (première fois)

```bash
./nas-commands.sh deploy
# Attend 2-5 minutes...
# ✓ App est live sur port 8500
```

### 3️⃣ **Accès quotidien**

```bash
# Voir l'IP
./nas-commands.sh ip

# Voir les logs
./nas-commands.sh logs

# Gérer l'app
./nas-commands.sh restart
./nas-commands.sh stop
./nas-commands.sh start

# SSH direct si besoin
ssh nas
```

### 4️⃣ **Sur iPhone**

```
Ouvrir Safari
Aller à : http://mon-nas-tailscale:8500
(Remplacer par votre domaine/IP)

Ajouter à l'écran d'accueil (optionnel mais recommandé)
```

---

## 🆘 Dépannage rapide

### SSH ne fonctionne pas
```bash
# Réexécuter setup
bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net
```

### App ne démarre pas
```bash
# Voir les erreurs
./nas-commands.sh logs

# Redéployer
./nas-commands.sh deploy
```

### iPhone ne peut pas accéder
```bash
# 1. Vérifier que Tailscale est connecté
# 2. Vérifier l'IP
./nas-commands.sh ip

# 3. Tester localement
ssh nas "curl http://localhost:8500/health"
```

### Le port 8500 est occupé
```bash
ssh nas
# Sur le NAS
lsof -i :8500
# Puis arrêter le processus ou changer le port dans docker-compose.yml
```

---

## 📚 Documentation disponible

- **`SSH_CONFIG.md`** - Guide détaillé SSH (20 min lecture)
- **`SSH_QUICK.md`** - Guide rapide SSH (2 min)
- **`setup-ssh.sh`** - Script automatisé
- **`DEPLOY_UGREEN.md`** - Guide complet NAS (30 min)
- **`DEPLOY_QUICK.md`** - Déploiement rapide (5 min)
- **`WEB_APP_README.md`** - Guide app web
- **`QUICK_START.md`** - Résumé 3 commandes

---

## 🎉 Résumé

Vous avez maintenant :

✅ **Connexion SSH sécurisée** sans mot de passe
✅ **Déploiement automatisé** en une commande  
✅ **Gestion facile** avec scripts helper
✅ **Secrets protégés** dans Git
✅ **App accessible** depuis iPhone via Tailscale
✅ **Documentation complète** pour tout

**Aucun mot de passe à stocker, aucun secret à mémoriser, zéro risque de leak.**

Bon courage pour vos révisions ! 🎌
