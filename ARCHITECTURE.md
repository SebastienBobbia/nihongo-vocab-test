# 🎨 Architecture & Workflow Visuel

## 🏗️ Architecture Complète

```
┌─────────────────────────────────────────────────────────────────┐
│                        VOTRE IPHONE                             │
│                    (Tailscale connecté)                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Safari : http://nas.domain.ts.net:8500                 │  │
│  │  ▼                                                       │  │
│  │  Interface Responsive HTML/CSS/JS                       │  │
│  │  - Sélection N4/N5                                      │  │
│  │  - Choix des feuilles                                   │  │
│  │  - Affichage questions                                  │  │
│  │  - Affichage scores                                     │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              △
                              │ Tailscale VPN
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    UGREEN DXP2800 NAS                           │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Port 8500                                               │  │
│  │  Docker Container (nihongo-vocab-test)                   │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │  FastAPI Backend (app.py)                          │ │  │
│  │  │  - GET  /health                                    │ │  │
│  │  │  - GET  /api/profiles                              │ │  │
│  │  │  - GET  /api/available-sheets/{profile}            │ │  │
│  │  │  - POST /api/generate                              │ │  │
│  │  │  - POST /api/correct                               │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │  Python Modules                                    │ │  │
│  │  │  - generate_test.py                                │ │  │
│  │  │  - correct_test.py                                 │ │  │
│  │  │  - config.py                                       │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │  Volumes                                           │ │  │
│  │  │  - /volume1/docker/nihongo-vocab-test/resources    │ │  │
│  │  │  - /volume1/docker/nihongo-vocab-test/output       │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  SSH Port 22 (sécurisé avec clés)                              │
│  ▲                                                              │
└──────────────────────────────────────────────────────────────────┘
    │ Clé SSH ed25519
    │ (pas de mot de passe)
    │
┌───▼──────────────────────────────────────────────────────────┐
│              VOTRE ORDINATEUR                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  ~/.ssh/id_ed25519 (clé privée)                       │ │
│  │  ~/.ssh/config                                        │ │
│  │    Host nas                                           │ │
│  │      HostName <ip-nas>                               │ │
│  │      User loklas                                      │ │
│  │      IdentityFile ~/.ssh/id_ed25519                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Scripts                                                    │
│  - setup-ssh.sh      → Configurer SSH                      │
│  - deploy.sh         → Déployer sur NAS                    │
│  - nas-commands.sh   → Gérer l'app                         │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔄 Workflow Complet

### Étape 1 : Configuration SSH (Une fois)

```
┌─────────────────────────────────┐
│  bash setup-ssh.sh              │
│  loklas                         │
│  192.168.1.100                  │
│  nas.domain.ts.net              │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  ✓ Génère clé SSH (si besoin)  │
│  ✓ Copie clé sur NAS            │
│  ✓ Configure alias SSH          │
│  ✓ Crée nas-commands.sh         │
│  ✓ Teste la connexion           │
└──────────────┬──────────────────┘
               │
               ▼
        ssh nas "echo OK"
               │
               ▼
        ✓ Connexion sans mot de passe
```

### Étape 2 : Déploiement (Une fois)

```
┌─────────────────────────────────┐
│  ./nas-commands.sh deploy       │
│  (ou ssh nas "bash deploy.sh")  │
└──────────────┬──────────────────┘
               │
               ▼
        Sur le NAS :
┌─────────────────────────────────┐
│  • Clone le repo GitHub         │
│  • Construit l'image Docker     │
│  • Lance le container           │
│  • Teste l'API                  │
│  • Affiche les URLs d'accès     │
└──────────────┬──────────────────┘
               │
               ▼
        Port 8500 LIVE ✓
```

### Étape 3 : Utilisation Quotidienne

```
                      IPHONE
                         │
                         ▼
                  Safari ouvre
            http://nas.domain.ts.net:8500
                         │
                         ▼
            Interface web responsive
                         │
           ┌─────────────┼─────────────┐
           ▼             ▼             ▼
      Sélectionner   Choisir      Générer
       N4 ou N5      feuilles      test
           │             │            │
           └─────────────┼────────────┘
                         ▼
              API FastAPI /api/generate
                         │
                         ▼
            Python (generate_test.py)
                         │
         ┌───────────────┴──────────────┐
         ▼                              ▼
      Charger               Créer questions
      vocabulaire      + distracteurs
         │                              │
         └───────────────┬──────────────┘
                         ▼
              JSON questions retourné
                         │
                         ▼
            Afficher interface test
            (alternance type 1 & 2)
                         │
         ┌───────────────┴─────────────┐
         ▼                             ▼
     Répondre à      Auto-avance
     une question    question suivante
         │                             │
         └───────────────┬─────────────┘
                         ▼
                    Test complété
                         │
                         ▼
            API /api/correct appelée
                         │
                         ▼
            Python (correct_test.py)
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
           Comparer          Calculer
           réponses            score
              │                     │
              └──────────┬──────────┘
                         ▼
            Résultat JSON retourné
                         │
                         ▼
        Afficher score + corrections
```

### Étape 4 : Gestion Quotidienne

```
Commandes disponibles :

./nas-commands.sh ip        → Voir IP Tailscale
./nas-commands.sh logs      → Voir les logs
./nas-commands.sh restart   → Redémarrer l'app
./nas-commands.sh stop      → Arrêter l'app
./nas-commands.sh start     → Démarrer l'app
./nas-commands.sh shell     → SSH direct
./nas-commands.sh deploy    → Redéployer
```

---

## 🔐 Flux de Sécurité

```
┌─────────────────────────────────────────────────────────────┐
│  SÉCURITÉ : Zéro credential en clair                       │
└─────────────────────────────────────────────────────────────┘

Approche classique (MAUVAIS) ❌
┌──────────────────┐
│  user: loklas    │ ← Stocké en clair
│  pass: ****      │ ← Dans scripts/env
│  token: xxxxx    │ ← Risque de leak
└──────────────────┘

Approche SSH (BON) ✓
┌──────────────────┐
│  ~/.ssh/config   │ ← Alias seulement
│  Host nas        │
│  HostName IP     │
│  User loklas     │
│  IdentityFile    │ ← Clé locale seulement
└──────────────────┘

Protection Git ✓
┌──────────────────┐
│  .gitignore      │
│  - *id_rsa*      │
│  - *id_ed25519*  │
│  - .env*         │
│  - credentials   │
└──────────────────┘
```

---

## 📊 Flux de Données API

```
REQUÊTE CLIENT (iPhone)
         │
         ▼
    POST /api/generate
    {
      "profile": "N4",
      "sheets": ["N4-1"]
    }
         │
         ▼
    FastAPI (app.py)
         │
         ├─ detect_sheets()
         │
         ├─ load_vocabulary()
         │
         ├─ prepare_test_for_web()
         │
         └─ Créer JSON questions
         │
         ▼
    RÉPONSE JSON
    {
      "test_data": {
        "questions": [
          {
            "id": 1,
            "type": "kanji_kana",
            "question": "漢字",
            "choices": [...]
          }
        ]
      }
    }
         │
         ▼
    Frontend JavaScript
    (affichage)
```

---

## 📁 Structure Fichiers

```
/volume1/docker/nihongo-vocab-test/
│
├── web/                          # App web
│   ├── app.py                    # FastAPI backend
│   └── static/
│       ├── index.html            # Interface
│       ├── app.js                # Logique JS
│       └── style.css             # Design
│
├── resources/                    # Vocabulaire (SOURCE)
│   ├── vocabulary_N4.xlsx
│   └── vocabulary_N5.xlsx
│
├── output/                       # Tests générés
│   ├── N4/
│   │   ├── N4-1_voc_test.xlsx
│   │   └── ...
│   └── N5/
│       ├── N5-1_voc_test.xlsx
│       └── ...
│
├── generate_test.py              # Générateur
├── correct_test.py               # Correcteur
├── config.py                     # Configuration
├── Dockerfile                    # Image Docker
├── docker-compose.yml            # Config Docker
└── requirements.txt              # Dépendances
```

---

## 🎯 Points de synchronisation

```
┌─────────────────────────────────────────────────────────────┐
│  Tout est synchronisé via Git                              │
│                                                              │
│  GitHub                                                     │
│    ↓                                                        │
│  git clone                                                  │
│    ↓                                                        │
│  /volume1/docker/nihongo-vocab-test/                       │
│    ↓                                                        │
│  Docker build                                              │
│    ↓                                                        │
│  Container en exécution                                    │
│    ↓                                                        │
│  API accessible sur port 8500                              │
│    ↓                                                        │
│  iPhone peut accéder via Tailscale                         │
└─────────────────────────────────────────────────────────────┘

Aucun secret n'est stocké localement.
Tout fonctionne avec des clés SSH.
Tout est versionné dans Git.
```

---

## 💻 Commandes Résumé

```
┌─────────────────────────────────────────────────────────────┐
│  Configuration (une fois)                                   │
└─────────────────────────────────────────────────────────────┘

bash setup-ssh.sh loklas 192.168.1.100 nas.domain.ts.net
  → Configure SSH sans mot de passe

┌─────────────────────────────────────────────────────────────┐
│  Déploiement (une fois)                                    │
└─────────────────────────────────────────────────────────────┘

./nas-commands.sh deploy
  → Déploie l'app sur le NAS

┌─────────────────────────────────────────────────────────────┐
│  Utilisation quotidienne                                    │
└─────────────────────────────────────────────────────────────┘

./nas-commands.sh ip         → Voir l'IP Tailscale
./nas-commands.sh logs       → Voir les logs
./nas-commands.sh restart    → Redémarrer
ssh nas                      → SSH direct
ssh nas "commande"           → Exécuter sur NAS
```

---

**Voilà le workflow complet !** 🎉 Tout est automatisé et sécurisé. 🔐
