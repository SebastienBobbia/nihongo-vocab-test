"""
FastAPI application for Japanese vocabulary test generator
Accessible from iOS via web interface on NAS
"""

import os
import sys
import random
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
from pydantic import BaseModel
import pandas as pd

# Add parent directory to path to import config and modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from config import PROFILES
from generate_test import detect_sheets, load_vocabulary, get_wrong_choices

app = FastAPI(title="Nihongo Vocab Test")

# Serve static files
static_dir = Path(__file__).parent / "static"
static_dir.mkdir(exist_ok=True)
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")


# ============================================================================
# Models
# ============================================================================

class TestRequest(BaseModel):
    """Request to generate a new test"""
    profile: str          # "N4" or "N5"
    sheets: Optional[list] = None  # e.g. ["N4-14", "N4-15"]


class TestCorrectRequest(BaseModel):
    """Request to correct a test"""
    profile: str
    answers: dict         # { "question_id": correct_index }
    questions: list       # Full question list echoed back from frontend


# ============================================================================
# Endpoints
# ============================================================================

@app.get("/", response_class=HTMLResponse)
async def root():
    """Serve the main HTML interface"""
    html_path = Path(__file__).parent / "static" / "index.html"
    if html_path.exists():
        return FileResponse(html_path)
    return "<h1>Nihongo Vocab Test App</h1>"


@app.get("/api/profiles")
async def get_profiles():
    """Get available profiles (N4, N5)"""
    return {"profiles": list(PROFILES.keys())}


@app.get("/api/available-sheets/{profile}")
async def get_available_sheets(profile: str):
    """Get list of available sheet names for a profile, sorted numerically."""
    if profile not in PROFILES:
        raise HTTPException(status_code=400, detail=f"Unknown profile: {profile}")

    profile_config = PROFILES[profile]
    vocab_file = profile_config["vocab_file"]

    if not Path(vocab_file).exists():
        raise HTTPException(status_code=404, detail=f"Vocabulary file not found: {vocab_file}")

    try:
        xls = pd.ExcelFile(vocab_file)
        level = profile_config["level"]
        sheets = [s for s in xls.sheet_names if s.startswith(level + "-")]
        # Sort numerically: N4-2 < N4-10 < N4-11
        sheets.sort(key=lambda s: int(s.split("-")[1]))
        return {"sheets": sheets}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/generate")
async def generate(request: TestRequest):
    """
    Generate a test and return all questions as a flat list with sections.
    The frontend expects: { test_data: { sections: [ { name, questions: [...] } ] } }
    """
    if request.profile not in PROFILES:
        raise HTTPException(status_code=400, detail=f"Unknown profile: {request.profile}")

    profile_config = PROFILES[request.profile]

    try:
        sheets = request.sheets or detect_sheets(
            profile_config["vocab_file"], profile_config["level"]
        )
        if not sheets:
            raise ValueError("No sheets found")

        # Load full vocabulary for all selected sheets (needed for good distractors)
        df_all = load_vocabulary(profile_config["vocab_file"], sheets)

        if df_all.empty:
            raise ValueError("No vocabulary data found in selected sheets")

        # Deduplicate on Kanji to avoid sampling issues
        df_unique = df_all.drop_duplicates(subset=["Kanji"]).reset_index(drop=True)
        n_available = len(df_unique)

        # 50 questions per section max, split evenly between the two types
        n_per_type = min(25, n_available // 2)
        if n_per_type < 1:
            raise ValueError("Not enough vocabulary to generate a test")

        sample1 = df_unique.sample(n=n_per_type).reset_index(drop=True)
        used = set(sample1["Kanji"])
        remaining = df_unique[~df_unique["Kanji"].isin(used)]
        n_type2 = min(n_per_type, len(remaining))
        sample2 = remaining.sample(n=n_type2).reset_index(drop=True)

        # Build section 1: Kanji → Hiragana
        q_id = 1
        section1_questions = []
        for _, row in sample1.iterrows():
            kanji    = str(row["Kanji"]).strip()
            hiragana = str(row["Hiragana"]).strip()
            wrong    = get_wrong_choices(hiragana, "Hiragana", df_all)
            choices  = [hiragana] + wrong
            random.shuffle(choices)
            section1_questions.append({
                "id":            q_id,
                "type":          "kanji_kana",
                "question":      kanji,
                "choices":       choices,
                "correct_index": choices.index(hiragana),
            })
            q_id += 1

        # Build section 2: French → Kanji
        section2_questions = []
        for _, row in sample2.iterrows():
            french = str(row["Francais"]).strip()
            kanji  = str(row["Kanji"]).strip()
            wrong  = get_wrong_choices(kanji, "Kanji", df_all)
            choices = [kanji] + wrong
            random.shuffle(choices)
            section2_questions.append({
                "id":            q_id,
                "type":          "fr_jp",
                "question":      french,
                "choices":       choices,
                "correct_index": choices.index(kanji),
            })
            q_id += 1

        test_data = {
            "sections": [
                {"name": "Kanji→Hiragana", "questions": section1_questions},
                {"name": "FR→JP",          "questions": section2_questions},
            ]
        }

        return {
            "success":        True,
            "test_data":      test_data,
            "total_questions": len(section1_questions) + len(section2_questions),
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/correct")
async def correct(request: TestCorrectRequest):
    """
    Correct a test.
    The frontend echoes back the full question list (with correct_index) and the
    user's answers { question_id: chosen_index }.
    """
    try:
        correct_count = 0
        details = []

        for question in request.questions:
            q_id        = question["id"]
            user_idx    = request.answers.get(str(q_id))  # JS keys are strings
            correct_idx = question["correct_index"]
            is_correct  = user_idx is not None and int(user_idx) == correct_idx

            if is_correct:
                correct_count += 1

            details.append({
                "question_number": q_id,
                "question":        question["question"],
                "user_answer":     question["choices"][int(user_idx)] if user_idx is not None else "—",
                "correct_answer":  question["choices"][correct_idx],
                "is_correct":      is_correct,
            })

        total = len(request.questions)
        return {
            "success": True,
            "correction": {
                "total_questions":  total,
                "correct_answers":  correct_count,
                "score":            round(correct_count / total * 100, 1) if total else 0,
                "details":          details,
            }
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# Health check
# ============================================================================

@app.get("/health")
async def health_check():
    return {"status": "ok"}
