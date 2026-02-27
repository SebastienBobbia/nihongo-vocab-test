# =============================================================================
# config.py — Configuration centrale du générateur de tests de vocabulaire
# =============================================================================
# Modifiez ce fichier pour adapter les chemins et les paramètres.

import os

# Répertoire racine du projet (chemin absolu, indépendant du CWD)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# -----------------------------------------------------------------------------
# Fichiers source (vocabulaire) — dans resources/
# -----------------------------------------------------------------------------

VOCAB_FILE_N4 = os.path.join(BASE_DIR, "resources", "vocabulary_N4.xlsx")
VOCAB_FILE_N5 = os.path.join(BASE_DIR, "resources", "vocabulary_N5.xlsx")

# -----------------------------------------------------------------------------
# Dossiers de sortie (tests générés et corrections)
# -----------------------------------------------------------------------------

OUTPUT_DIR_N4 = os.path.join(BASE_DIR, "output", "N4")
OUTPUT_DIR_N5 = os.path.join(BASE_DIR, "output", "N5")

# -----------------------------------------------------------------------------
# Paramètres du test
# -----------------------------------------------------------------------------

# Nombre de questions par section (le script ajuste automatiquement si nécessaire)
QUESTIONS_PER_TEST = 50

# Code couleur Excel de la réponse sélectionnée par l'élève (bleu)
SELECTION_COLOR = "FF00B0F0"

# -----------------------------------------------------------------------------
# Profils
# Chaque profil définit :
#   - vocab_file : fichier Excel source du vocabulaire
#   - output_dir : dossier de sortie pour les tests et corrections
#   - level      : préfixe des feuilles (ex: "N4" → feuilles N4-1, N4-2, ...)
#   - sheets     : liste explicite de feuilles, ou None pour toutes les détecter
# -----------------------------------------------------------------------------

PROFILES = {
    "N4": {
        "vocab_file": VOCAB_FILE_N4,
        "output_dir": OUTPUT_DIR_N4,
        "level": "N4",
        "sheets": None,
    },
    "N5": {
        "vocab_file": VOCAB_FILE_N5,
        "output_dir": OUTPUT_DIR_N5,
        "level": "N5",
        "sheets": None,
    },
}
