# Nihongo Vocab Test - Web App (iOS)

Application web responsive pour accéder aux tests de vocabulaire japonais depuis un téléphone iOS.

## 🚀 Déploiement sur NAS avec Docker

### Prérequis
- Docker installé sur votre NAS
- Docker Compose (généralement inclus)
- Accès à votre NAS via le réseau local

### Installation rapide

1. **Cloner ou copier le projet sur votre NAS**
   ```bash
   git clone https://github.com/SebastienBobbia/nihongo-vocab-test.git
   cd nihongo-vocab-test
   ```

2. **Construire et lancer le container**
   ```bash
   docker-compose up -d
   ```

   Ou sans docker-compose :
   ```bash
   docker build -t nihongo-vocab-app .
   docker run -d \
     -p 8000:8000 \
     -v $(pwd)/output:/app/output \
     -v $(pwd)/resources:/app/resources \
     --name nihongo-vocab-test \
     --restart unless-stopped \
     nihongo-vocab-app
   ```

3. **Vérifier que le service tourne**
   ```bash
   docker logs nihongo-vocab-test
   ```

### Accès depuis iOS

1. **Sur votre iPhone/iPad :**
   - Ouvrez Safari
   - Naviguez vers : `http://<IP-NAS>:8000`
   
   Exemple : `http://192.168.1.100:8000`

2. **Ajouter en favori (Booklet iOS) :**
   - Tapez l'URL
   - Appuyez sur le bouton de partage
   - Sélectionnez "Ajouter un favori" ou "Ajouter à l'écran d'accueil"

3. **Utilisation :**
   - Sélectionnez le niveau (N4/N5)
   - Choisissez les feuilles à étudier
   - Répondez aux questions
   - Consultez votre score à la fin

### Configuration du réseau

**Pour votre NAS Synology :**
1. Ouvrez le panneau de configuration
2. Allez à Container Manager (ou Docker)
3. Cliquez sur "Container" → créez à partir du fichier docker-compose.yml
4. Portez 8000 ↔ 8000

**Pour accéder depuis iOS sur le même réseau :**
- Trouvez l'IP locale de votre NAS : `hostname -I` sur le NAS
- Remplacez `<IP-NAS>` dans l'URL par cette adresse

### Arrêter le service

```bash
docker-compose down
```

ou

```bash
docker stop nihongo-vocab-test
```

### Redémarrer après un redémarrage du NAS

Le container est configuré avec `restart: unless-stopped`, il redémarrera automatiquement.

### Dépannage

**L'app ne se charge pas :**
- Vérifiez l'IP de votre NAS
- Assurez-vous que le port 8000 est accessible
- Vérifiez les logs : `docker logs nihongo-vocab-test`

**Les tests ne se génèrent pas :**
- Vérifiez que `resources/vocabulary_N4.xlsx` et `vocabulary_N5.xlsx` existent
- Consultez les logs : `docker logs nihongo-vocab-test`

**Problème de permissions :**
- Assurez-vous que les dossiers `output/` et `resources/` existent
- Donnez les permissions : `chmod 755 output/ resources/`

---

## 🏠 Développement local

Pour tester localement avant de déployer :

```bash
pip install -r requirements.txt
python -m uvicorn web.app:app --reload --host 0.0.0.0 --port 8000
```

Accédez ensuite à : `http://localhost:8000`

---

## 📱 Compatibilité

- ✅ iOS Safari (iPhone, iPad)
- ✅ Android Chrome
- ✅ Desktop browsers (development)
- ✅ PWA (peut être installée sur écran d'accueil)

---

## 🔧 Structure

```
.
├── web/
│   ├── app.py                 # API FastAPI
│   └── static/
│       ├── index.html         # Interface web
│       ├── style.css          # Styles responsive
│       └── app.js             # Logique frontend
├── generate_test.py           # Génération des tests
├── correct_test.py            # Correction des tests
├── config.py                  # Configuration
├── Dockerfile                 # Image Docker
├── docker-compose.yml         # Configuration Docker Compose
└── resources/                 # Fichiers vocabulaire (Excel)
```

---

## 📝 Notes

- Les réponses ne sont **pas persistées** - à chaque session, c'est un nouveau test
- Les fichiers Excel générés sont sauvegardés dans `output/`
- L'interface est **entièrement responsive** pour iOS en portrait et paysage

Bon courage pour réviser ! 🎌
