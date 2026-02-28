# ✅ Checklist Pré-Déploiement

Utilisez cette checklist pour vérifier que tout est prêt avant de déployer.

---

## 🔒 Préparation Sécurité

- [ ] **SSH Setup**
  ```bash
  bash setup-ssh.sh loklas <ip-nas> <domaine-tailscale>
  ```
  - [ ] Clé SSH générée
  - [ ] Clé copiée sur le NAS
  - [ ] `ssh nas "echo OK"` fonctionne
  - [ ] Alias `nas` et `nas-tailscale` créés

- [ ] **Vérifier .gitignore**
  ```bash
  cat .gitignore | grep -E "id_rsa|id_ed25519|\.env"
  ```
  - [ ] Contient les exclusions SSH
  - [ ] Contient les exclusions .env
  - [ ] Contient les exclusions credentials

- [ ] **Aucun secret dans Git**
  ```bash
  git log --all --full-history -- "*id_rsa*" "*id_ed25519*" ".env*"
  # Doit retourner RIEN
  ```

---

## 📡 Vérification NAS

- [ ] **Accès SSH au NAS**
  ```bash
  ssh nas "uname -a"
  ```
  - [ ] Retourne info sur le NAS sans demander de mot de passe

- [ ] **Docker sur le NAS**
  ```bash
  ssh nas "docker --version && docker-compose --version"
  ```
  - [ ] Affiche les versions

- [ ] **Espace disque**
  ```bash
  ssh nas "df -h /volume1 | tail -1"
  ```
  - [ ] Au moins 2-3 GB libres

- [ ] **Tailscale sur NAS** (optionnel mais recommandé)
  ```bash
  ssh nas "tailscale ip -4"
  ```
  - [ ] Retourne une IP Tailscale

- [ ] **Répertoire de déploiement**
  ```bash
  ssh nas "ls -la /volume1/ | grep docker"
  ```
  - [ ] `/volume1/docker` existe (sera créé par script sinon)

---

## 🐙 Vérification GitHub

- [ ] **Repository pushé**
  ```bash
  git log --oneline | head -5
  git push
  ```
  - [ ] Derniers commits sont poussés

- [ ] **Branches à jour**
  ```bash
  git status
  ```
  - [ ] "Your branch is up to date with 'origin/main'"

---

## 🔧 Configuration de Déploiement

- [ ] **Port 8500 libre**
  ```bash
  ssh nas "lsof -i :8500 2>/dev/null || echo 'Port libre'"
  ```
  - [ ] Port n'est pas utilisé

- [ ] **docker-compose.yml modifié**
  ```bash
  grep "8500" docker-compose.yml
  ```
  - [ ] Contient `8500:8000`

- [ ] **Fichiers vocabulaire présents**
  ```bash
  ls -lh resources/vocabulary_*.xlsx
  ```
  - [ ] `vocabulary_N4.xlsx` existe
  - [ ] `vocabulary_N5.xlsx` existe

---

## 🌐 Vérification Tailscale

- [ ] **Tailscale connecté sur ordinateur**
  - [ ] VPN icon visible
  - [ ] Peut accéder à d'autres machines Tailscale

- [ ] **Tailscale connecté sur iPhone**
  - [ ] VPN icon visible dans status bar
  - [ ] Peut accéder à d'autres machines Tailscale

- [ ] **Nom de domaine Tailscale** (optionnel mais recommandé)
  - [ ] Ex: `nas.my-tailscale.ts.net` configuré
  - [ ] Testable : `ping nas.my-tailscale.ts.net`

---

## 📋 Documentation

- [ ] **Vérifier les guides**
  ```bash
  ls -1 *.md
  ```
  - [ ] `SSH_CONFIG.md` présent
  - [ ] `SSH_QUICK.md` présent
  - [ ] `DEPLOY_UGREEN.md` présent
  - [ ] `DEPLOY_QUICK.md` présent
  - [ ] `SECURITY_OVERVIEW.md` présent

---

## 🚀 Déploiement

### Phase 1 : Script de déploiement

- [ ] **Télécharger le script**
  ```bash
  cd /tmp
  curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/deploy.sh
  chmod +x deploy.sh
  ```

- [ ] **Exécuter via SSH**
  ```bash
  ssh nas "bash /tmp/deploy.sh"
  ```
  Ou faire les étapes manuelles

### Phase 2 : Vérification post-déploiement

- [ ] **Container démarre**
  ```bash
  ssh nas "docker-compose -f /volume1/docker/nihongo-vocab-test/docker-compose.yml ps"
  ```
  - [ ] Affiche "Up"

- [ ] **API répond**
  ```bash
  ssh nas "curl http://localhost:8500/health"
  ```
  - [ ] Retourne `{"status":"ok"}`

- [ ] **Voir les logs**
  ```bash
  ./nas-commands.sh logs
  # Ou
  ssh nas "cd /volume1/docker/nihongo-vocab-test && docker-compose logs"
  ```
  - [ ] Pas d'erreurs critiques

---

## 📱 Test sur iPhone

- [ ] **Trouver l'IP/domaine**
  ```bash
  ./nas-commands.sh ip
  ```

- [ ] **Accéder via Safari**
  - [ ] Ouvrir Safari sur iPhone
  - [ ] Aller à `http://<ip-ou-domaine>:8500`
  - [ ] Page charge

- [ ] **Interface responsive**
  - [ ] Boutons N4/N5 visibles
  - [ ] Interface adaptée à l'écran

- [ ] **Générer un test**
  - [ ] Sélectionner N4
  - [ ] Choisir une feuille
  - [ ] Cliquer "Start Test"
  - [ ] Questions apparaissent

- [ ] **Répondre aux questions**
  - [ ] Cliquer sur une réponse
  - [ ] Auto-avance à la question suivante
  - [ ] Score visible à la fin

- [ ] **Ajouter à l'écran d'accueil** (optionnel)
  - [ ] Partage → "Ajouter à l'écran d'accueil"
  - [ ] Icon apparaît sur home screen

---

## 🐛 Dépannage

Si quelque chose ne fonctionne pas :

- [ ] **Logs du container**
  ```bash
  ./nas-commands.sh logs
  ```

- [ ] **Redémarrer l'app**
  ```bash
  ./nas-commands.sh restart
  ```

- [ ] **Redéployer**
  ```bash
  ./nas-commands.sh deploy
  ```

- [ ] **SSH au NAS**
  ```bash
  ssh nas
  cd /volume1/docker/nihongo-vocab-test
  docker-compose down
  docker-compose up -d
  docker-compose logs -f
  ```

---

## ✅ Final

- [ ] Tout fonctionne localement
- [ ] SSH est configuré sans mot de passe
- [ ] Secrets sont protégés
- [ ] App est déployée et accessible
- [ ] iPhone peut accéder via Tailscale
- [ ] Tests peuvent être générés et complétés

**🎉 Vous êtes prêt !**

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Consultez les logs : `./nas-commands.sh logs`
2. Relancez : `./nas-commands.sh restart`
3. Redéployez : `./nas-commands.sh deploy`
4. Consultez la documentation du problème

Bon courage pour vos révisions ! 🎌
