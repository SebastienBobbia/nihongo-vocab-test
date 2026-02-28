# 📑 INDEX DE LA DOCUMENTATION

Trouvez rapidement le document qui vous convient.

---

## 🚀 JE VEUX DÉPLOYER MAINTENANT

**→ Commencez par [`DEPLOY_QUICK.md`](DEPLOY_QUICK.md)** ⚡
- 5 minutes
- Une seule commande
- C'est tout

---

## 🎯 JE VEUX COMPRENDRE LE SETUP COMPLET

**→ Consultez [`README_FINAL.md`](README_FINAL.md)**
- Vue d'ensemble
- Les 3 commandes essentielles
- Sécurité expliquée

---

## 🔐 SÉCURITÉ & SSH

### Je n'ai jamais utilisé SSH
**→ Lisez [`SSH_QUICK.md`](SSH_QUICK.md)** (2 min)
- Guide super simple
- Configuration rapide

### Je veux comprendre SSH en détail
**→ Lisez [`SSH_CONFIG.md`](SSH_CONFIG.md)** (20 min)
- Explication complète
- Bonnes pratiques
- Troubleshooting

### Je veux automatiser SSH
**→ Utilisez `setup-ssh.sh`**
```bash
bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net
```
- Script fait tout automatiquement
- Source : `setup-ssh.sh`

### Je veux comprendre comment les secrets sont protégés
**→ Lisez [`SECURITY_OVERVIEW.md`](SECURITY_OVERVIEW.md)**
- Protection .gitignore
- Ce qui est/n'est pas committé
- Checklist de sécurité

---

## 🚀 DÉPLOIEMENT

### Je suis sur NAS UGREEN et je veux une guide complète
**→ Lisez [`DEPLOY_UGREEN.md`](DEPLOY_UGREEN.md)** (20 min)
- 2 options : automatisée ou manuelle
- Configuration Tailscale
- Dépannage détaillé

### Je veux juste les commandes rapides
**→ Consultez [`DEPLOY_QUICK.md`](DEPLOY_QUICK.md)** (5 min)
- 1 commande = déploiement complet

### Je veux vérifier que tout est prêt avant de déployer
**→ Utilisez [`CHECKLIST.md`](CHECKLIST.md)**
- Checklist complète
- Vérifications pré-déploiement
- Dépannage post-déploiement

---

## 📱 APPLICATION WEB

### Je veux comprendre l'app web
**→ Lisez [`WEB_APP_README.md`](WEB_APP_README.md)**
- Guide sur la web app
- Fonctionnalités
- API endpoints

### Je veux déployer l'app web en tant que container
**→ Consultez [`DEPLOY_UGREEN.md`](DEPLOY_UGREEN.md)**
- Docker setup
- Port 8500
- Accès iPhone

---

## 🔍 INDEX PAR FICHIER

### Documentation (à lire)
| Fichier | Objectif | Temps |
|---------|----------|-------|
| `README_FINAL.md` | Vue d'ensemble complète | 5 min |
| `DEPLOY_QUICK.md` | Déploiement ultra-rapide | 5 min |
| `DEPLOY_UGREEN.md` | Guide complet NAS | 20 min |
| `SSH_QUICK.md` | SSH rapide | 2 min |
| `SSH_CONFIG.md` | SSH détaillé | 20 min |
| `SECURITY_OVERVIEW.md` | Sécurité complète | 5 min |
| `CHECKLIST.md` | Vérifications | 10 min |
| `WEB_APP_README.md` | App web | 10 min |
| `QUICK_START.md` | Résumé 3 commandes | 2 min |

### Scripts (à exécuter)
| Fichier | Objectif |
|---------|----------|
| `setup-ssh.sh` | Configuration SSH automatisée |
| `deploy.sh` | Déploiement NAS automatisé |
| `nas-commands.sh` | Scripts helper (généré par setup-ssh.sh) |

### Configuration
| Fichier | Objectif |
|---------|----------|
| `docker-compose.yml` | Configuration Docker (port 8500) |
| `Dockerfile` | Image Docker |
| `.gitignore` | Protection des secrets |

---

## ❓ FAQ RAPIDE

### Quelle commande pour déployer ?
```bash
bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net
./nas-commands.sh deploy
```

### Comment accéder depuis iPhone ?
```
Safari → http://domaine-tailscale:8500
```

### Comment voir les logs ?
```bash
./nas-commands.sh logs
```

### Comment redémarrer l'app ?
```bash
./nas-commands.sh restart
```

### Comment SSH sans mot de passe ?
```bash
ssh nas
```

### Où sont les secrets ?
**Nulle part !** Clés SSH seulement, rien dans Git.

### Comment vérifier que tout est prêt ?
```bash
# Consultez CHECKLIST.md
```

---

## 🎯 ORDRE RECOMMANDÉ DE LECTURE

1. **`README_FINAL.md`** - Comprendre le concept (5 min)
2. **`SSH_QUICK.md`** - Configurer SSH (2 min)
3. **`DEPLOY_QUICK.md`** - Déployer (5 min)
4. **`CHECKLIST.md`** - Vérifier avant de lancer (10 min)
5. **Lancer le déploiement !**
6. **`DEPLOY_UGREEN.md`** - En cas de problème (besoin de référence)

---

## 🆘 VOUS AVEZ UN PROBLÈME ?

### Problème SSH
→ `SSH_CONFIG.md` section "Dépannage"

### Problème de déploiement
→ `DEPLOY_UGREEN.md` section "Dépannage"

### Problème d'accès iPhone
→ `CHECKLIST.md` section "Test sur iPhone"

### Questions de sécurité
→ `SECURITY_OVERVIEW.md`

### Pour réexécuter le setup
```bash
bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net
```

---

## 📞 SUPPORT RAPIDE

```bash
# Voir les logs
./nas-commands.sh logs

# Redémarrer l'app
./nas-commands.sh restart

# Réinstaller SSH
bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net

# Redéployer l'app
./nas-commands.sh deploy
```

---

**Vous ne savez pas par où commencer ?** → Consultez `README_FINAL.md` 🚀

**Vous êtes pressé ?** → Utilisez `DEPLOY_QUICK.md` ⚡

**Vous avez un problème ?** → Consultez `CHECKLIST.md` ✓
