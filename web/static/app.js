/**
 * Nihongo Vocab Test - Frontend Application
 */

// ============================================================================
// State
// ============================================================================

const state = {
    currentScreen:        'menu',
    currentProfile:       null,
    selectedSheets:       [],
    allSheets:            [],
    testData:             null,   // { sections: [ { name, questions: [...] } ] }
    allQuestions:         [],     // flat list built from sections
    currentQuestionIndex: 0,
    userAnswers:          {},     // { "question_id": chosen_index }
};

// ============================================================================
// Screen Navigation
// ============================================================================

function showScreen(screenName) {
    document.querySelectorAll('.screen').forEach(s => s.classList.add('hidden'));
    const screen = document.getElementById(`${screenName}-screen`);
    if (screen) {
        screen.classList.remove('hidden');
        state.currentScreen = screenName;
    }
}

function goToMenu() {
    resetTestState();
    showScreen('menu');
}

// ============================================================================
// Sheet Selection
// ============================================================================

function startTest(profile) {
    state.currentProfile = profile;
    state.selectedSheets = [];
    loadSheets(profile);
}

async function loadSheets(profile) {
    showLoading(true);
    try {
        const response = await fetch(`/api/available-sheets/${profile}`);
        if (!response.ok) throw new Error('Failed to load sheets');

        const data = await response.json();
        state.allSheets = data.sheets;  // already sorted numerically by backend

        document.getElementById('level-name').textContent = profile;
        renderSheetsList();
        showScreen('level');
    } catch (error) {
        showError(`Failed to load sheets: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

function renderSheetsList() {
    const container = document.getElementById('sheets-list');
    container.innerHTML = '';

    state.allSheets.forEach(sheet => {
        const btn = document.createElement('button');
        btn.className = 'sheet-btn';
        btn.textContent = sheet.split('-')[1];  // "14" from "N4-14"
        btn.setAttribute('aria-label', sheet);
        if (state.selectedSheets.includes(sheet)) btn.classList.add('selected');
        btn.onclick = () => toggleSheet(sheet, btn);
        container.appendChild(btn);
    });
}

function toggleSheet(sheet, btn) {
    const idx = state.selectedSheets.indexOf(sheet);
    if (idx > -1) {
        state.selectedSheets.splice(idx, 1);
        btn.classList.remove('selected');
    } else {
        state.selectedSheets.push(sheet);
        btn.classList.add('selected');
    }
}

// ============================================================================
// Test Generation
// ============================================================================

async function startSelectedTest() {
    if (state.selectedSheets.length === 0) {
        showError('Sélectionne au moins une feuille.');
        return;
    }

    showLoading(true);
    try {
        const response = await fetch('/api/generate', {
            method:  'POST',
            headers: { 'Content-Type': 'application/json' },
            body:    JSON.stringify({
                profile: state.currentProfile,
                sheets:  state.selectedSheets,
            }),
        });

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.detail || 'Failed to generate test');
        }

        const data = await response.json();

        // Validate structure
        if (!data.test_data || !Array.isArray(data.test_data.sections)) {
            throw new Error('Unexpected response format from server');
        }

        state.testData   = data.test_data;
        // Flatten all sections into one question list
        state.allQuestions = data.test_data.sections.flatMap(s => s.questions);

        if (state.allQuestions.length === 0) {
            throw new Error('No questions generated');
        }

        state.currentQuestionIndex = 0;
        state.userAnswers = {};

        displayTest();
        showScreen('test');
    } catch (error) {
        showError(`Failed to generate test: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

// ============================================================================
// Test Display
// ============================================================================

function displayTest() {
    const question = state.allQuestions[state.currentQuestionIndex];
    if (!question) return;

    updateProgressBar();
    displayQuestion(question);
    updateNavigationButtons();
}

function displayQuestion(question) {
    const isKanjiType = question.type === 'kanji_kana';

    if (isKanjiType) {
        document.getElementById('q-type-1').classList.remove('hidden');
        document.getElementById('q-type-2').classList.add('hidden');
        document.getElementById('q-kanji').textContent = question.question;
        renderChoices(question, 'choices-1');
    } else {
        document.getElementById('q-type-1').classList.add('hidden');
        document.getElementById('q-type-2').classList.remove('hidden');
        document.getElementById('q-french').textContent = question.question;
        renderChoices(question, 'choices-2');
    }

    document.getElementById('current-q').textContent = state.currentQuestionIndex + 1;
    document.getElementById('total-q').textContent   = state.allQuestions.length;
}

function renderChoices(question, containerId) {
    const container = document.getElementById(containerId);
    container.innerHTML = '';

    question.choices.forEach((choice, index) => {
        const btn = document.createElement('button');
        btn.className   = 'choice-btn';
        btn.textContent = choice;

        if (state.userAnswers[question.id] === index) {
            btn.classList.add('selected');
        }

        btn.onclick = () => selectAnswer(question.id, index, question, containerId);
        container.appendChild(btn);
    });
}

function selectAnswer(questionId, answerIndex, question, containerId) {
    state.userAnswers[questionId] = answerIndex;

    // Re-render choices to show selection
    renderChoices(question, containerId);

    // Auto-advance after a short delay
    setTimeout(() => nextQuestion(), 500);
}

// ============================================================================
// Progress & Navigation
// ============================================================================

function updateProgressBar() {
    const total    = state.allQuestions.length;
    const progress = ((state.currentQuestionIndex + 1) / total) * 100;
    document.getElementById('progress-fill').style.width = progress + '%';
}

function updateNavigationButtons() {
    const total = state.allQuestions.length;
    document.getElementById('prev-btn').disabled = state.currentQuestionIndex === 0;
    document.getElementById('next-btn').disabled = state.currentQuestionIndex === total - 1;
}

function nextQuestion() {
    if (state.currentQuestionIndex < state.allQuestions.length - 1) {
        state.currentQuestionIndex++;
        displayTest();
    } else {
        finishTest();
    }
}

function previousQuestion() {
    if (state.currentQuestionIndex > 0) {
        state.currentQuestionIndex--;
        displayTest();
    }
}

function skipQuestion() {
    nextQuestion();
}

// ============================================================================
// Finish & Correction
// ============================================================================

async function finishTest() {
    showLoading(true);
    try {
        // Echo the full question list back so the server can check correct_index
        const response = await fetch('/api/correct', {
            method:  'POST',
            headers: { 'Content-Type': 'application/json' },
            body:    JSON.stringify({
                profile:   state.currentProfile,
                answers:   state.userAnswers,
                questions: state.allQuestions,
            }),
        });

        if (!response.ok) {
            const err = await response.json().catch(() => ({}));
            throw new Error(err.detail || 'Failed to correct test');
        }

        const data = await response.json();
        displayResults(data.correction);
        showScreen('results');
    } catch (error) {
        showError(`Failed to finish test: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

// ============================================================================
// Results
// ============================================================================

function displayResults(correction) {
    const pct = Math.round((correction.correct_answers / correction.total_questions) * 100);
    document.getElementById('score-percent').textContent = pct + '%';
    document.getElementById('score-text').textContent =
        `${correction.correct_answers} / ${correction.total_questions} correct`;

    const container = document.getElementById('correction-details');
    container.innerHTML = '';

    (correction.details || []).forEach(detail => {
        const div = document.createElement('div');
        div.className = 'detail-item';
        div.innerHTML = `
            <div class="detail-item-q">Q${detail.question_number}: ${detail.question}</div>
            <div class="detail-item-result">
                <span>Réponse: ${detail.user_answer}</span>
                <span class="${detail.is_correct ? 'result-correct' : 'result-wrong'}">
                    ${detail.is_correct ? '✓ Correct' : '✗ Incorrect — ' + detail.correct_answer}
                </span>
            </div>
        `;
        container.appendChild(div);
    });
}

function retakeTest() {
    state.currentQuestionIndex = 0;
    state.userAnswers = {};
    startSelectedTest();
}

// ============================================================================
// Utilities
// ============================================================================

function showLoading(show) {
    document.getElementById('loading').classList.toggle('hidden', !show);
}

function showError(message) {
    const el = document.getElementById('error-banner');
    el.textContent = message;
    el.classList.remove('hidden');
    setTimeout(() => el.classList.add('hidden'), 6000);
}

function resetTestState() {
    state.currentQuestionIndex = 0;
    state.userAnswers   = {};
    state.testData      = null;
    state.allQuestions  = [];
    state.selectedSheets = [];
    state.currentProfile = null;
}

// ============================================================================
// Dark mode toggle
// ============================================================================

function toggleDarkMode() {
    const isDark = document.documentElement.classList.toggle('dark');
    localStorage.setItem('darkMode', isDark ? '1' : '0');
    updateDarkModeIcon(isDark);
}

function updateDarkModeIcon(isDark) {
    const btn = document.getElementById('dark-mode-btn');
    if (btn) btn.textContent = isDark ? '☀️' : '🌙';
}

// ============================================================================
// Init
// ============================================================================

document.addEventListener('DOMContentLoaded', () => {
    // Restore dark mode preference
    const savedDark = localStorage.getItem('darkMode') === '1';
    if (savedDark) {
        document.documentElement.classList.add('dark');
        updateDarkModeIcon(true);
    }

    showScreen('menu');

    fetch('/health')
        .then(r => r.ok ? null : Promise.reject())
        .catch(() => showError('API connection failed. Check server.'));
});
