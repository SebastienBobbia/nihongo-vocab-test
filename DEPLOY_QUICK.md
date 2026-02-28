# ⚡ DÉPLOIEMENT ULTRA-RAPIDE (5 minutes)

## Sur votre NAS via SSH

```bash
# 1. Connexion
ssh user@<ip-nas>

# 2. Télécharger et exécuter le script (c'est tout!)
cd /tmp && curl -O https://raw.githubusercontent.com/SebastienBobbia/nihongo-vocab-test/main/deploy.sh && chmod +x deploy.sh && bash deploy.sh
```

**C'est tout !** Le script fait tout automatiquement. ✅

---

## Sur iPhone après le déploiement

```
Safari → http://<votre-nom-tailscale>:8500
```

Ou trouvez l'IP :
```bash
# Sur le NAS
ssh user@<ip-nas>
tailscale ip -4
```

Puis sur iPhone : `http://<cette-ip>:8500`

---

## Commandes utiles ensuite

```bash
# Voir les logs
ssh user@<ip-nas>
cd /volume1/docker/nihongo-vocab-test
docker-compose logs -f

# Arrêter
docker-compose down

# Redémarrer
docker-compose restart

# Mettre à jour
git pull
docker-compose up -d --build
```

---

**Voilà !** 🚀 Plus de détails dans `DEPLOY_UGREEN.md`
