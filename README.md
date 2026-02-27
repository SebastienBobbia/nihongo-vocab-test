# Nihongo Vocab Test Generator

Scripts Python pour générer et corriger des tests de vocabulaire japonais (N4/N5) à partir d'un fichier Excel Google Sheets exporté.

## Structure du projet

```
nihongo-vocab-test/
├── config.py           # Configuration : chemins, profils utilisateurs
├── generate_test.py    # Génération des tests Excel
├── correct_test.py     # Correction automatique des tests
├── requirements.txt    # Dépendances Python
└── output/             # Dossier de sortie local (ignoré par git)
```

## Prérequis

- Python 3.10+
- Packages : `openpyxl`, `pandas`

```bash
pip install -r requirements.txt
```

## Configuration

Modifier `config.py` pour ajuster les chemins vers vos fichiers Excel et dossiers de sortie.

Chaque **profil** correspond à un utilisateur/niveau :
| Profil    | Fichier source              | Dossier de sortie               |
|-----------|-----------------------------|---------------------------------|
| `bob_N4`  | `Kanji_bob_N4.xlsx`         | `Test/N4/`                      |
| `bob_N5`  | `Kanji_bob_N5.xlsx`         | `Test/N5/`                      |
| `zizi_N4` | `Kanji_bob_N4.xlsx` (zizi)  | `N4_test/Zizi/`                 |

## Génération des tests

```bash
# Générer tous les tests de tous les profils
python generate_test.py

# Générer tous les tests d'un profil
python generate_test.py --profile bob_N4

# Générer un test spécifique
python generate_test.py --profile bob_N4 --sheets N4-14

# Générer plusieurs tests spécifiques
python generate_test.py --profile bob_N4 --sheets N4-14 N4-15
```

Chaque test produit un fichier `{LEVEL}-{NUM}_voc_test.xlsx` contenant :
- **Feuille 1 — Kanji→Hiragana** : kanji affiché, choisir la bonne lecture parmi 4
- **Feuille 2 — FR→JP** : mot français affiché, choisir le bon kanji parmi 4

## Correction des tests

Une fois le fichier rempli par l'élève (réponses surlignées en **bleu**) :

```bash
# Corriger tous les tests d'un profil
python correct_test.py --profile bob_N4

# Corriger un test spécifique
python correct_test.py --profile bob_N4 --test N4-14
```

Le fichier corrigé `{LEVEL}-{NUM}_corrige.xlsx` est généré dans le même dossier :
- Numéro de question **vert** = bonne réponse
- Numéro de question **rouge** = mauvaise réponse (la bonne réponse est encadrée en vert)
- Feuille **Correction** avec le score détaillé par section

## Format du fichier vocabulaire

Le fichier Excel source doit avoir des feuilles nommées `N4-1`, `N4-2`, etc.  
Chaque feuille contient (à partir de la ligne 2) :

| Col E (index 4) | Col F (index 5) | Col G (index 6) |
|-----------------|-----------------|-----------------|
| Kanji/Vocab     | Hiragana        | Traduction FR   |

## Notes

- Les mots en doublon dans une feuille sont automatiquement dédupliqués.
- Si une feuille contient trop peu de mots uniques, le nombre de questions est ajusté automatiquement avec un avertissement.
- Les deux feuilles du test (Kanji→Kana et FR→JP) n'utilisent jamais les mêmes mots.
