# 🔐 Guide Rapide SSH (2 minutes)

## Pourquoi SSH Keys ?

Au lieu de taper :
```bash
ssh loklas@192.168.1.100
Password: ••••••••
```

Vous tapez :
```bash
ssh nas
# ✓ Connecté directement
```

**Zéro mot de passe, zéro credential à stocker, zéro risque de leak.**

---

## Installation (30 secondes)

Sur votre ordinateur :

```bash
# Télécharger le script
curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/setup-ssh.sh

# Lancer (remplacer les valeurs)
bash setup-ssh.sh loklas 192.168.1.100 nas.my-tailscale.ts.net
```

**C'est tout !** Le script :
- ✅ Génère une clé SSH
- ✅ La copie sur le NAS
- ✅ Configure les alias
- ✅ Crée des scripts helper

---

## Utilisation ensuite

```bash
# Connexion simple
ssh nas

# Voir l'IP Tailscale
./nas-commands.sh ip

# Voir les logs
./nas-commands.sh logs

# Déployer automatiquement
./nas-commands.sh deploy

# Redémarrer l'app
./nas-commands.sh restart
```

---

## Sécurité

- ✅ `.gitignore` contient `id_rsa*` et `id_ed25519*`
- ✅ Rien n'est committé
- ✅ Rien à mémoriser
- ✅ Clé locale, personne n'y a accès

---

## Dépannage rapide

```bash
# Vérifier que la clé fonctionne
ssh nas "echo OK"

# Voir les logs SSH
ssh -vvv nas "echo OK"
```

---

**Voilà !** Vous avez une configuration SSH 100% sécurisée. 🔐
