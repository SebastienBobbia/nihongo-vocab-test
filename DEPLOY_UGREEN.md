# 📱 Guide de déploiement sur UGREEN DXP2800 + Tailscale

## 🎯 Configuration finale
- **NAS** : UGREEN DXP2800
- **Chemin** : `/volume1/docker/nihongo-vocab-test`
- **Port** : 8500
- **Accès** : Tailscale (domaine personnalisé)

---

## **Option 1 : Déploiement automatisé (RECOMMANDÉ) ⚡**

C'est la solution la plus simple et fiable.

### Étape 1 : Connexion SSH au NAS
```bash
ssh user@<ip-nas>
```

### Étape 2 : Télécharger le script de déploiement
```bash
cd /tmp
curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/deploy.sh
chmod +x deploy.sh
```

### Étape 3 : Exécuter le déploiement
```bash
bash deploy.sh
```

Le script fera automatiquement :
- ✅ Vérifier les prérequis (Docker, docker-compose, Git)
- ✅ Créer `/volume1/docker` s'il n'existe pas
- ✅ Cloner le repository
- ✅ Construire l'image Docker
- ✅ Lancer le container sur le port 8500
- ✅ Tester que l'API fonctionne
- ✅ Afficher les informations de connexion

### Résultat attendu
```
════════════════════════════════════════════════════
  Déploiement terminé avec succès!
════════════════════════════════════════════════════

🎉 L'application est maintenant déployée!

Configuration:
  • Chemin: /volume1/docker/nihongo-vocab-test
  • Port: 8500
  • Container: nihongo-vocab-test

Accès depuis iPhone via Tailscale:
  • Domaine: http://<votre-domaine-tailscale>:8500
  • IP Tailscale: http://100.x.x.x:8500

Accès local sur le NAS:
  • http://localhost:8500
  • http://192.168.x.x:8500

Commandes utiles:
  • Voir les logs: docker-compose -f /volume1/docker/nihongo-vocab-test/docker-compose.yml logs -f
  • Arrêter: docker-compose -f /volume1/docker/nihongo-vocab-test/docker-compose.yml down
  • Redémarrer: docker-compose -f /volume1/docker/nihongo-vocab-test/docker-compose.yml restart
```

---

## **Option 2 : Déploiement manuel**

Si vous préférez le faire étape par étape.

### Étape 2.1 : Créer le répertoire et cloner
```bash
mkdir -p /volume1/docker
cd /volume1/docker
git clone https://github.com/SebastienBobbia/nihongo-vocab-test.git
cd nihongo-vocab-test
```

### Étape 2.2 : Vérifier la structure
```bash
ls -la
# Devrait voir: docker-compose.yml, Dockerfile, requirements.txt, resources/, etc.
```

### Étape 2.3 : Construire et lancer
```bash
docker-compose build
docker-compose up -d
```

### Étape 2.4 : Vérifier le statut
```bash
docker-compose ps
# Devrait afficher "Up" pour nihongo-vocab-test

# Voir les logs
docker-compose logs -f
```

### Étape 2.5 : Tester l'API
```bash
curl http://localhost:8500/health
# Résultat attendu: {"status":"ok"}
```

---

## 📱 **Accès depuis iPhone via Tailscale**

### Option A : Avec domaine Tailscale (recommandé)

Si vous avez configuré un domaine personnalisé dans Tailscale (ex: `nas.my-tailscale.ts.net`) :

1. Sur l'iPhone avec Tailscale connecté
2. Ouvrez **Safari**
3. Allez à : `http://nas.my-tailscale.ts.net:8500`
4. Vous verrez l'interface des tests

### Option B : Avec IP Tailscale

1. Trouvez l'IP Tailscale du NAS :
```bash
tailscale ip -4
# Exemple: 100.64.123.45
```

2. Sur l'iPhone :
   - Safari → `http://100.64.123.45:8500`

### Option C : Ajouter à l'écran d'accueil

Pour un accès rapide comme une "app" :

1. Ouvrez l'URL dans Safari
2. Appuyez sur l'icône de partage (↗️ en haut à droite)
3. Sélectionnez "Ajouter à l'écran d'accueil"
4. Donnez le nom "日本語 Test" ou "Nihongo"
5. L'app apparaît sur votre écran d'accueil !

---

## 🔧 **Commandes utiles**

### Voir les logs en temps réel
```bash
cd /volume1/docker/nihongo-vocab-test
docker-compose logs -f
```

### Arrêter l'application
```bash
cd /volume1/docker/nihongo-vocab-test
docker-compose down
```

### Redémarrer l'application
```bash
cd /volume1/docker/nihongo-vocab-test
docker-compose restart
```

### Mettre à jour le code (si modifications sur GitHub)
```bash
cd /volume1/docker/nihongo-vocab-test
git pull origin main
docker-compose up -d --build
```

### Vérifier les fichiers générés
```bash
ls -la /volume1/docker/nihongo-vocab-test/output/N4/
ls -la /volume1/docker/nihongo-vocab-test/output/N5/
```

### Nettoyer les fichiers temporaires
```bash
cd /volume1/docker/nihongo-vocab-test
docker system prune -a
```

---

## 🐛 **Dépannage**

### Le container ne démarre pas
```bash
# Vérifier les logs
docker-compose logs

# Redémarrer
docker-compose down
docker-compose up -d

# Reconstruire de zéro
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### L'iPhone ne peut pas accéder
- ✓ Assurez-vous que Tailscale est actif sur l'iPhone
- ✓ Vérifiez l'IP Tailscale du NAS : `tailscale ip -4`
- ✓ Testez localement : `curl http://localhost:8500/health`
- ✓ Testez depuis un autre ordinateur sur le NAS : `curl http://<tailscale-ip>:8500/health`

### L'API répond mais pas l'interface
```bash
# Vérifier que les fichiers statiques existent
ls -la web/static/

# Redémarrer le container
docker-compose restart
```

### Le port 8500 est occupé
```bash
# Trouver quel processus utilise le port
lsof -i :8500

# Modifier le port dans docker-compose.yml
# Changer "8500:8000" en "8501:8000" (ou un autre port)
nano docker-compose.yml
docker-compose up -d
```

---

## ✅ **Checklist post-déploiement**

- [ ] Le script de déploiement s'est exécuté sans erreur
- [ ] `docker-compose ps` affiche le container "Up"
- [ ] `curl http://localhost:8500/health` retourne `{"status":"ok"}`
- [ ] L'iPhone peut accéder à `http://<tailscale-ip>:8500`
- [ ] La page charge et affiche les boutons N4/N5
- [ ] Vous pouvez sélectionner des feuilles et générer un test

---

## 📞 **Support**

Si vous rencontrez des problèmes :

1. Vérifiez les logs : `docker-compose logs -f`
2. Consultez le README : `cat README.md`
3. Consultez le guide rapide : `cat QUICK_START.md`
4. Consultez le guide web app : `cat WEB_APP_README.md`

---

## 🎉 **C'est prêt!**

Vous pouvez maintenant :
- Réviser depuis votre iPhone n'importe où sur le même réseau Tailscale
- Générer des tests rapidement
- Voir vos scores immédiatement

Bon courage pour vos révisions ! 🎌
