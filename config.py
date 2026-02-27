# =============================================================================
# config.py — Configuration centrale du générateur de tests de vocabulaire
# =============================================================================
# Modifiez ce fichier pour adapter les chemins et les tests à générer.

import os

# -----------------------------------------------------------------------------
# Chemins des fichiers source (vocabulaire)
# -----------------------------------------------------------------------------

# Bob (local)
VOCAB_FILE_BOB_N4 = r"S:\Documents\Japan\Nihongo\Vocabulary_sheets\Kanji_bob_N4.xlsx"
VOCAB_FILE_BOB_N5 = r"S:\Documents\Japan\Nihongo\Vocabulary_sheets\Kanji_bob_N5.xlsx"

# Zizi (OneDrive — adapter si nécessaire)
VOCAB_FILE_ZIZI_N4 = r"C:\Users\Aurelien\OneDrive\Bureau\Japonais objectif 2025\Kanji_bob_N4.xlsx"

# -----------------------------------------------------------------------------
# Dossiers de sortie (tests générés et corrections)
# -----------------------------------------------------------------------------

OUTPUT_DIR_BOB_N4 = r"S:\Documents\Japan\Nihongo\Test\N4"
OUTPUT_DIR_BOB_N5 = r"S:\Documents\Japan\Nihongo\Test\N5"

OUTPUT_DIR_ZIZI_N4 = r"C:\Users\Aurelien\OneDrive\Bureau\Japonais objectif 2025\N4_test\Zizi"

# -----------------------------------------------------------------------------
# Nombre de questions par test
# -----------------------------------------------------------------------------
QUESTIONS_PER_TEST = 50

# -----------------------------------------------------------------------------
# Couleur de sélection de l'élève (bleu Excel)
# -----------------------------------------------------------------------------
SELECTION_COLOR = "FF00B0F0"

# -----------------------------------------------------------------------------
# Définition des profils utilisateurs
# Chaque profil contient :
#   - vocab_file  : fichier source Excel
#   - output_dir  : dossier de sortie
#   - level       : niveau (N4, N5, ...)
#   - sheets      : liste des feuilles à traiter (None = toutes détectées automatiquement)
# -----------------------------------------------------------------------------

PROFILES = {
    "bob_N4": {
        "vocab_file": VOCAB_FILE_BOB_N4,
        "output_dir": OUTPUT_DIR_BOB_N4,
        "level": "N4",
        "sheets": None,  # None = toutes les feuilles N4-x détectées automatiquement
    },
    "bob_N5": {
        "vocab_file": VOCAB_FILE_BOB_N5,
        "output_dir": OUTPUT_DIR_BOB_N5,
        "level": "N5",
        "sheets": None,
    },
    "zizi_N4": {
        "vocab_file": VOCAB_FILE_ZIZI_N4,
        "output_dir": OUTPUT_DIR_ZIZI_N4,
        "level": "N4",
        "sheets": None,
    },
}
