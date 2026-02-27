/**
 * Nihongo Vocab Test - Frontend Application
 * Handles UI logic and API communication
 */

// ============================================================================
// State Management
// ============================================================================

const state = {
    currentScreen: 'menu',
    currentProfile: null,
    selectedSheets: [],
    currentTest: null,
    currentQuestionIndex: 0,
    userAnswers: {}, // { questionId: answerIndex }
    testData: null,
    allSheets: []
};

// ============================================================================
// Screen Navigation
// ============================================================================

function showScreen(screenName) {
    // Hide all screens
    document.querySelectorAll('.screen').forEach(screen => {
        screen.classList.add('hidden');
    });

    // Show selected screen
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

function startTest(profile) {
    state.currentProfile = profile;
    state.selectedSheets = [];
    
    // Load available sheets
    loadSheets(profile);
}

async function loadSheets(profile) {
    showLoading(true);
    try {
        const response = await fetch(`/api/available-sheets/${profile}`);
        if (!response.ok) throw new Error('Failed to load sheets');
        
        const data = await response.json();
        state.allSheets = data.sheets;
        
        // Display level selection screen
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
        btn.textContent = sheet.split('-')[1]; // Show only the number (e.g., "14" from "N4-14")
        btn.onclick = () => toggleSheet(sheet);
        
        if (state.selectedSheets.includes(sheet)) {
            btn.classList.add('selected');
        }
        
        container.appendChild(btn);
    });
}

function toggleSheet(sheet) {
    const index = state.selectedSheets.indexOf(sheet);
    if (index > -1) {
        state.selectedSheets.splice(index, 1);
    } else {
        state.selectedSheets.push(sheet);
    }
    renderSheetsList();
}

async function startSelectedTest() {
    if (state.selectedSheets.length === 0) {
        showError('Please select at least one sheet');
        return;
    }
    
    showLoading(true);
    try {
        const response = await fetch('/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                profile: state.currentProfile,
                sheets: state.selectedSheets
            })
        });
        
        if (!response.ok) throw new Error('Failed to generate test');
        
        const data = await response.json();
        state.testData = data.test_data;
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
    const question = getCurrentQuestion();
    if (!question) return;
    
    updateProgressBar();
    displayQuestion(question);
    updateNavigationButtons();
}

function getCurrentQuestion() {
    if (!state.testData || !state.testData.sections.length) return null;
    
    // Flatten all questions from all sections
    const allQuestions = [];
    state.testData.sections.forEach(section => {
        allQuestions.push(...section.questions);
    });
    
    return allQuestions[state.currentQuestionIndex] || null;
}

function displayQuestion(question) {
    const questionId = question.id;
    const isKanjiType = state.currentQuestionIndex % 2 === 0; // Alternate between types
    
    if (isKanjiType) {
        // Kanji → Hiragana
        document.getElementById('q-type-1').classList.remove('hidden');
        document.getElementById('q-type-2').classList.add('hidden');
        
        document.getElementById('q-kanji').textContent = question.question;
        renderChoices(question.choices, 'choices-1', questionId);
    } else {
        // French → Japanese
        document.getElementById('q-type-1').classList.add('hidden');
        document.getElementById('q-type-2').classList.remove('hidden');
        
        document.getElementById('q-french').textContent = question.question;
        renderChoices(question.choices, 'choices-2', questionId);
    }
    
    // Update question counter
    document.getElementById('current-q').textContent = state.currentQuestionIndex + 1;
    document.getElementById('total-q').textContent = getTotalQuestions();
}

function renderChoices(choices, containerId, questionId) {
    const container = document.getElementById(containerId);
    container.innerHTML = '';
    
    choices.forEach((choice, index) => {
        const btn = document.createElement('button');
        btn.className = 'choice-btn';
        btn.textContent = choice;
        btn.onclick = () => selectAnswer(questionId, index);
        
        // Highlight previously selected answer
        if (state.userAnswers[questionId] === index) {
            btn.classList.add('selected');
        }
        
        container.appendChild(btn);
    });
}

function selectAnswer(questionId, answerIndex) {
    state.userAnswers[questionId] = answerIndex;
    
    // Update UI to show selection
    const question = getCurrentQuestion();
    if (question) {
        const isKanjiType = state.currentQuestionIndex % 2 === 0;
        const containerId = isKanjiType ? 'choices-1' : 'choices-2';
        renderChoices(question.choices, containerId, questionId);
    }
    
    // Auto-advance to next question after selection
    setTimeout(() => nextQuestion(), 500);
}

function updateProgressBar() {
    const totalQuestions = getTotalQuestions();
    const progress = ((state.currentQuestionIndex + 1) / totalQuestions) * 100;
    document.getElementById('progress-fill').style.width = progress + '%';
}

function updateNavigationButtons() {
    const totalQuestions = getTotalQuestions();
    const prevBtn = document.getElementById('prev-btn');
    const nextBtn = document.getElementById('next-btn');
    
    prevBtn.disabled = state.currentQuestionIndex === 0;
    nextBtn.disabled = state.currentQuestionIndex === totalQuestions - 1;
}

function getTotalQuestions() {
    if (!state.testData || !state.testData.sections.length) return 0;
    return state.testData.sections.reduce((total, section) => {
        return total + section.questions.length;
    }, 0);
}

// ============================================================================
// Navigation
// ============================================================================

function nextQuestion() {
    const totalQuestions = getTotalQuestions();
    if (state.currentQuestionIndex < totalQuestions - 1) {
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

async function finishTest() {
    showLoading(true);
    try {
        // Call correction API
        const response = await fetch('/api/correct', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                profile: state.currentProfile,
                test_name: state.selectedSheets.join('_'),
                answers: state.userAnswers
            })
        });
        
        if (!response.ok) throw new Error('Failed to correct test');
        
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
// Results Display
// ============================================================================

function displayResults(correction) {
    const scorePercent = Math.round((correction.correct_answers / correction.total_questions) * 100);
    document.getElementById('score-percent').textContent = scorePercent + '%';
    document.getElementById('score-text').textContent = 
        `${correction.correct_answers} / ${correction.total_questions} correct`;
    
    // Display detailed corrections
    const detailsContainer = document.getElementById('correction-details');
    detailsContainer.innerHTML = '';
    
    if (correction.details && correction.details.length > 0) {
        correction.details.forEach(detail => {
            const div = document.createElement('div');
            div.className = 'detail-item';
            div.innerHTML = `
                <div class="detail-item-q">Q${detail.question_number}: ${detail.question}</div>
                <div class="detail-item-result">
                    <span>Your answer: ${detail.user_answer}</span>
                    <span class="${detail.is_correct ? 'result-correct' : 'result-wrong'}">
                        ${detail.is_correct ? '✓ Correct' : '✗ Wrong - ' + detail.correct_answer}
                    </span>
                </div>
            `;
            detailsContainer.appendChild(div);
        });
    }
}

function retakeTest() {
    state.currentQuestionIndex = 0;
    state.userAnswers = {};
    startSelectedTest();
}

// ============================================================================
// Utility Functions
// ============================================================================

function showLoading(show) {
    const loadingEl = document.getElementById('loading');
    if (show) {
        loadingEl.classList.remove('hidden');
    } else {
        loadingEl.classList.add('hidden');
    }
}

function showError(message) {
    const errorEl = document.getElementById('error-banner');
    errorEl.textContent = message;
    errorEl.classList.remove('hidden');
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        errorEl.classList.add('hidden');
    }, 5000);
}

function viewStats() {
    alert('Statistics feature coming soon!');
}

function resetTestState() {
    state.currentQuestionIndex = 0;
    state.userAnswers = {};
    state.testData = null;
    state.selectedSheets = [];
    state.currentProfile = null;
}

// ============================================================================
// Initialization
// ============================================================================

document.addEventListener('DOMContentLoaded', () => {
    showScreen('menu');
    
    // Check API health
    fetch('/health')
        .then(r => r.ok ? null : Promise.reject())
        .catch(() => showError('API connection failed. Check server.'));
});
