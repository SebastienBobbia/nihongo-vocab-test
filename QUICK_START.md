# 🚀 Déploiement rapide sur votre NAS

## Étapes simples

### 1. **Cloner le projet sur le NAS**
```bash
git clone https://github.com/SebastienBobbia/nihongo-vocab-test.git
cd nihongo-vocab-test
```

### 2. **Lancer avec Docker Compose**
```bash
docker-compose up -d
```

✅ C'est tout ! Le service démarre sur le port 8000

### 3. **Accéder depuis iPhone/iPad**
- Ouvrez **Safari**
- Allez à : `http://<IP-NAS>:8000`
  - Exemple : `http://192.168.1.100:8000`

### 4. **Ajouter à l'écran d'accueil (optionnel)**
- Appuyez sur l'icône de partage (↗️)
- Sélectionnez "Ajouter à l'écran d'accueil"
- Utilisez comme une app native !

---

## 🔍 Trouver l'IP de votre NAS

**Si c'est un Synology :**
- Allez à **Assistant d'installation** ou ouvrez l'app Synology sur iPhone
- L'IP est affichée (ex: 192.168.1.100)

**Sinon :**
- Sur votre Mac : `arp -a | grep -i "<NAS-name>"`
- Sur Windows (PowerShell) : `arp -a`
- Sur le NAS lui-même : `hostname -I`

---

## 📱 Utilisation

1. Sélectionnez N4 ou N5
2. Choisissez les feuilles de vocabulaire
3. Répondez aux questions (auto-avance)
4. Consultez votre score

---

## 🛑 Arrêter le service

```bash
docker-compose down
```

---

## ⚙️ Commandes utiles

**Voir les logs :**
```bash
docker-compose logs -f
```

**Reconstruire l'image (après mise à jour du code) :**
```bash
docker-compose up -d --build
```

**Accéder au terminal du container :**
```bash
docker-compose exec nihongo-vocab-app bash
```

---

## 🐛 Dépannage

**L'app ne charge pas :**
- Vérifiez que l'IP du NAS est correcte
- Assurez-vous que le port 8000 est ouvert
- Consultez les logs : `docker-compose logs`

**Les tests ne se génèrent pas :**
- Vérifiez que `resources/vocabulary_N4.xlsx` existe
- Relancez : `docker-compose down && docker-compose up -d`

---

Bon courage pour vos révisions ! 🎌
