# Nihongo Vocab Test Generator

Scripts Python pour générer et corriger des tests de vocabulaire japonais (N4/N5) à partir des fichiers Excel de vocabulaire.

## Structure du projet

```
nihongo-vocab-test/
├── config.py           # Configuration : chemins, profils, paramètres
├── generate_test.py    # Génération des tests Excel
├── correct_test.py     # Correction automatique des tests
├── requirements.txt    # Dépendances Python
├── resources/          # Fichiers source du vocabulaire (versionnés)
│   ├── vocabulary_N4.xlsx
│   └── vocabulary_N5.xlsx
└── output/             # Tests et corrections générés (ignoré par git)
    ├── N4/
    └── N5/
```

## Prérequis

- Python 3.10+

```bash
pip install -r requirements.txt
```

## Génération des tests

```bash
# Générer tous les tests (N4 et N5)
python generate_test.py

# Générer tous les tests d'un niveau
python generate_test.py --profile N4

# Générer un test spécifique
python generate_test.py --profile N4 --sheets N4-14

# Générer plusieurs tests spécifiques
python generate_test.py --profile N4 --sheets N4-14 N4-15
```

Les fichiers générés dans `output/N4/` et `output/N5/` :
- `N4-14_voc_test.xlsx` — test à remettre à l'élève

Chaque test contient deux feuilles :
- **Kanji→Hiragana** : kanji affiché, choisir la bonne lecture parmi 4
- **FR→JP** : mot français affiché, choisir le bon kanji parmi 4

## Correction des tests

Une fois le test rempli par l'élève (réponses surlignées en **bleu**) :

```bash
# Corriger tous les tests d'un niveau
python correct_test.py --profile N4

# Corriger un test spécifique
python correct_test.py --profile N4 --test N4-14
```

Le fichier corrigé `N4-14_corrige.xlsx` est généré dans le même dossier :
- Numéro de question **vert** = bonne réponse
- Numéro de question **rouge** = mauvaise réponse (bonne réponse encadrée en vert)
- Feuille **Correction** avec le score par section et le total

## Format du fichier vocabulaire

Les fichiers dans `resources/` sont des exports Excel. Chaque feuille est nommée `N4-1`, `N4-2`, etc. et contient à partir de la ligne 2 :

| Col E (index 4) | Col F (index 5) | Col G (index 6) |
|-----------------|-----------------|-----------------|
| Kanji/Vocab     | Hiragana        | Traduction FR   |

## Notes

- Les mots en doublon dans une feuille sont automatiquement dédupliqués.
- Si une feuille contient trop peu de mots uniques, le nombre de questions est ajusté automatiquement avec un avertissement.
- Les deux sections du test (Kanji→Kana et FR→JP) n'utilisent jamais les mêmes mots.
