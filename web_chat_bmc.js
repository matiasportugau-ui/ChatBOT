// BMC Chat Interface - Main JavaScript
// Configuration
const RASA_URL = 'http://localhost:5005';
const TRAINING_API_URL = 'http://localhost:5006'; // Optional training API
const senderId = `bmc_user_${Date.now()}`;

// State Management
let conversationHistory = [];
let analyticsData = {
    totalMessages: 0,
    intents: {},
    entities: {},
    confidenceScores: []
};
let intentChart = null;
let entityChart = null;
let availableIntents = [];

// DOM Elements
const elements = {
    chatMessages: document.getElementById('chatMessages'),
    messageInput: document.getElementById('messageInput'),
    sendButton: document.getElementById('sendButton'),
    chatForm: document.getElementById('chatForm'),
    serverStatus: document.getElementById('serverStatus'),
    intentSelect: document.getElementById('intentSelect'),
    exampleText: document.getElementById('exampleText'),
    addExampleBtn: document.getElementById('addExampleBtn'),
    viewExamplesBtn: document.getElementById('viewExamplesBtn'),
    trainModelBtn: document.getElementById('trainModelBtn'),
    examplesList: document.getElementById('examplesList'),
    trainingStatus: document.getElementById('trainingStatus'),
    totalMessages: document.getElementById('totalMessages'),
    totalIntents: document.getElementById('totalIntents'),
    totalEntities: document.getElementById('totalEntities'),
    avgConfidence: document.getElementById('avgConfidence'),
    intentDistribution: document.getElementById('intentDistribution'),
    loadingOverlay: document.getElementById('loadingOverlay'),
    toastContainer: document.getElementById('toastContainer')
};

// Initialize Application
document.addEventListener('DOMContentLoaded', () => {
    initializeEventListeners();
    checkServerStatus();
    loadIntents();
    initializeCharts();
    setInterval(checkServerStatus, 30000); // Check every 30 seconds
});

// Event Listeners
function initializeEventListeners() {
    // Chat form submission
    elements.chatForm.addEventListener('submit', handleChatSubmit);
    
    // Navigation buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const panel = e.target.dataset.panel;
            switchPanel(panel);
        });
    });

    // Panel toggles
    document.querySelectorAll('.panel-toggle').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const panel = e.target.dataset.panel;
            togglePanel(panel);
        });
    });

    // Training buttons
    elements.addExampleBtn.addEventListener('click', handleAddExample);
    elements.viewExamplesBtn.addEventListener('click', handleViewExamples);
    elements.trainModelBtn.addEventListener('click', handleTrainModel);
    document.getElementById('newIntentBtn').addEventListener('click', handleNewIntent);
}

// Server Status Check
async function checkServerStatus() {
    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);
        const response = await fetch(`${RASA_URL}/status`, { signal: controller.signal });
        clearTimeout(timeoutId);
        if (response.ok) {
            elements.serverStatus.textContent = '✅ Conectado';
            elements.serverStatus.className = 'status-indicator connected';
            return true;
        }
    } catch (error) {
        elements.serverStatus.textContent = '❌ Desconectado';
        elements.serverStatus.className = 'status-indicator disconnected';
        return false;
    }
}

// Panel Management
function switchPanel(panelName) {
    // Update nav buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.panel === panelName);
    });

    // Show/hide panels
    document.querySelectorAll('.panel').forEach(panel => {
        panel.classList.toggle('active', panel.id === `${panelName}Panel`);
    });
}

function togglePanel(panelName) {
    const panel = document.getElementById(`${panelName}Panel`);
    const isCollapsed = panel.classList.contains('collapsed');
    
    if (panelName === 'analytics') {
        panel.classList.toggle('collapsed');
        const toggleBtn = panel.querySelector('.panel-toggle');
        toggleBtn.textContent = isCollapsed ? '−' : '+';
    }
}

// Chat Functionality
async function handleChatSubmit(e) {
    e.preventDefault();
    const text = elements.messageInput.value.trim();
    if (!text) return;

    await sendMessage(text);
}

async function sendMessage(text) {
    // Add user message
    addMessage(text, true);
    elements.messageInput.value = '';
    elements.sendButton.disabled = true;
    elements.sendButton.innerHTML = '<div class="loading-spinner" style="width:20px;height:20px;"></div>';

    try {
        // Get intent analysis
        const parseResponse = await fetch(`${RASA_URL}/model/parse`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text })
        });
        
        const intentInfo = parseResponse.ok ? await parseResponse.json() : null;

        // Send message to Rasa
        const response = await fetch(`${RASA_URL}/webhooks/rest/webhook`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                sender: senderId,
                message: text
            })
        });

        if (!response.ok) {
            throw new Error(`Server error: ${response.status}`);
        }

        const data = await response.json();
        
        // Display bot responses
        if (data && data.length > 0) {
            data.forEach(msg => {
                if (msg.text) {
                    addMessage(msg.text, false, intentInfo);
                }
            });
        } else {
            addMessage('No hay respuesta del chatbot', false);
        }

        // Update analytics
        updateAnalytics(text, intentInfo, data);

        // Save to history
        conversationHistory.push({
            timestamp: new Date().toISOString(),
            user_message: text,
            intent: intentInfo?.intent?.name,
            confidence: intentInfo?.intent?.confidence,
            entities: intentInfo?.entities || [],
            bot_responses: data
        });

    } catch (error) {
        showToast(`Error: ${error.message}`, 'error');
        console.error('Error:', error);
    } finally {
        elements.sendButton.disabled = false;
        elements.sendButton.innerHTML = '<span class="send-icon">➤</span>';
        elements.messageInput.focus();
    }
}

function addMessage(text, isUser, intentInfo = null) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${isUser ? 'user' : 'bot'}`;
    
    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';
    
    // Highlight entities in text
    let displayText = text;
    if (intentInfo && intentInfo.entities && intentInfo.entities.length > 0) {
        intentInfo.entities.forEach(entity => {
            const regex = new RegExp(entity.value, 'gi');
            displayText = displayText.replace(regex, 
                `<span class="entity-highlight" title="${entity.entity}">${entity.value}</span>`
            );
        });
    }
    contentDiv.innerHTML = displayText;
    
    messageDiv.appendChild(contentDiv);
    
    // Add intent info for bot messages
    if (intentInfo && !isUser) {
        const infoDiv = document.createElement('div');
        infoDiv.className = 'message-info';
        const confidence = ((intentInfo.intent?.confidence || 0) * 100).toFixed(1);
        infoDiv.innerHTML = `
            <span class="intent-badge">${intentInfo.intent?.name || 'unknown'}</span>
            Confianza: ${confidence}%
        `;
        messageDiv.appendChild(infoDiv);
    }
    
    elements.chatMessages.appendChild(messageDiv);
    elements.chatMessages.scrollTop = elements.chatMessages.scrollHeight;
}

// Training Functionality
async function loadIntents() {
    try {
        // Try to fetch from training API, fallback to defaults
        try {
            const response = await fetch(`${TRAINING_API_URL}/api/intents`);
            if (response.ok) {
                const data = await response.json();
                availableIntents = data.intents.map(i => i.name);
            } else {
                throw new Error('API not available');
            }
        } catch (error) {
            // Fallback to default intents
            console.log('Training API not available, using defaults');
            availableIntents = ['saludo', 'despedida', 'cotizar_producto', 'fallback'];
        }
        
        elements.intentSelect.innerHTML = '<option value="">Seleccionar intent...</option>';
        availableIntents.forEach(intent => {
            const option = document.createElement('option');
            option.value = intent;
            option.textContent = intent;
            elements.intentSelect.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading intents:', error);
        availableIntents = ['saludo', 'despedida', 'cotizar_producto', 'fallback'];
    }
}

function handleNewIntent() {
    const intentName = prompt('Nombre del nuevo intent:');
    if (intentName && intentName.trim()) {
        const newIntent = intentName.trim().toLowerCase().replace(/\s+/g, '_');
        availableIntents.push(newIntent);
        
        const option = document.createElement('option');
        option.value = newIntent;
        option.textContent = newIntent;
        option.selected = true;
        elements.intentSelect.appendChild(option);
        
        showToast(`Intent "${newIntent}" creado`, 'success');
    }
}

async function handleAddExample() {
    const intent = elements.intentSelect.value;
    const example = elements.exampleText.value.trim();
    
    if (!intent) {
        showToast('Por favor selecciona un intent', 'warning');
        return;
    }
    
    if (!example) {
        showToast('Por favor ingresa un ejemplo', 'warning');
        return;
    }

    showLoading('Agregando ejemplo...');
    
    try {
        // Try to use training API
        try {
            const response = await fetch(`${TRAINING_API_URL}/api/examples`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ intent, example })
            });
            
            if (response.ok) {
                const data = await response.json();
                showToast(data.message || `Ejemplo agregado a "${intent}"`, 'success');
                elements.exampleText.value = '';
                await loadExamples(intent);
                return;
            }
        } catch (apiError) {
            console.log('Training API not available, using simulation');
        }
        
        // Fallback: simulate (user should use train_chatbot.py directly)
        await new Promise(resolve => setTimeout(resolve, 500));
        showToast(`Ejemplo preparado para "${intent}". Usa train_chatbot.py para guardarlo.`, 'info');
        elements.exampleText.value = '';
    } catch (error) {
        showToast(`Error: ${error.message}`, 'error');
    } finally {
        hideLoading();
    }
}

async function handleViewExamples() {
    const intent = elements.intentSelect.value;
    if (!intent) {
        showToast('Por favor selecciona un intent', 'warning');
        return;
    }
    
    await loadExamples(intent);
}

async function loadExamples(intent) {
    try {
        // Try to fetch from training API
        try {
            const response = await fetch(`${TRAINING_API_URL}/api/intents/${intent}/examples`);
            if (response.ok) {
                const data = await response.json();
                if (data.examples && data.examples.length > 0) {
                    elements.examplesList.innerHTML = '';
                    data.examples.forEach(example => {
                        const item = document.createElement('div');
                        item.className = 'example-item';
                        item.textContent = example;
                        elements.examplesList.appendChild(item);
                    });
                    return;
                }
            }
        } catch (apiError) {
            console.log('Training API not available');
        }
        
        // Fallback: show placeholder
        elements.examplesList.innerHTML = `
            <div class="example-item">
                Ejemplos para "${intent}" - Inicia training_api.py para ver ejemplos reales
            </div>
        `;
    } catch (error) {
        console.error('Error loading examples:', error);
    }
}

async function handleTrainModel() {
    if (!confirm('¿Estás seguro de que quieres entrenar el modelo? Esto puede tomar varios minutos.')) {
        return;
    }

    showLoading('Entrenando modelo...');
    elements.trainingStatus.className = 'training-status info';
    elements.trainingStatus.textContent = 'Iniciando entrenamiento...';
    elements.trainingStatus.classList.remove('hidden');

    try {
        // Try to use training API
        try {
            const response = await fetch(`${TRAINING_API_URL}/api/train`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            });
            
            if (response.ok) {
                const data = await response.json();
                elements.trainingStatus.className = 'training-status success';
                elements.trainingStatus.textContent = '✅ ' + data.message;
                showToast('Modelo entrenado exitosamente', 'success');
                return;
            } else {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Training failed');
            }
        } catch (apiError) {
            console.log('Training API not available');
            // Fallback: show instruction
            elements.trainingStatus.className = 'training-status info';
            elements.trainingStatus.textContent = '⚠️ Inicia training_api.py o usa train_chatbot.py directamente';
            showToast('Usa train_chatbot.py o inicia training_api.py para entrenar', 'warning');
        }
    } catch (error) {
        elements.trainingStatus.className = 'training-status error';
        elements.trainingStatus.textContent = `❌ Error: ${error.message}`;
        showToast(`Error al entrenar: ${error.message}`, 'error');
    } finally {
        hideLoading();
    }
}

// Analytics Functionality
function updateAnalytics(userMessage, intentInfo, botResponses) {
    analyticsData.totalMessages++;
    
    // Update intent counts
    if (intentInfo?.intent?.name) {
        const intentName = intentInfo.intent.name;
        analyticsData.intents[intentName] = (analyticsData.intents[intentName] || 0) + 1;
        
        // Update confidence scores
        if (intentInfo.intent.confidence) {
            analyticsData.confidenceScores.push(intentInfo.intent.confidence);
        }
    }
    
    // Update entity counts
    if (intentInfo?.entities) {
        intentInfo.entities.forEach(entity => {
            const entityName = entity.entity;
            analyticsData.entities[entityName] = (analyticsData.entities[entityName] || 0) + 1;
        });
    }
    
    // Update UI
    updateAnalyticsUI();
    updateCharts();
}

function updateAnalyticsUI() {
    elements.totalMessages.textContent = analyticsData.totalMessages;
    elements.totalIntents.textContent = Object.keys(analyticsData.intents).length;
    elements.totalEntities.textContent = Object.keys(analyticsData.entities).length;
    
    // Calculate average confidence
    if (analyticsData.confidenceScores.length > 0) {
        const avg = analyticsData.confidenceScores.reduce((a, b) => a + b, 0) / analyticsData.confidenceScores.length;
        elements.avgConfidence.textContent = `${(avg * 100).toFixed(1)}%`;
    }
    
    // Update intent distribution
    elements.intentDistribution.innerHTML = '';
    Object.entries(analyticsData.intents)
        .sort((a, b) => b[1] - a[1])
        .forEach(([intent, count]) => {
            const item = document.createElement('div');
            item.className = 'intent-item';
            item.innerHTML = `
                <span class="intent-name">${intent}</span>
                <span class="intent-count">${count}</span>
            `;
            elements.intentDistribution.appendChild(item);
        });
}

function initializeCharts() {
    // Intent Confidence Chart
    const intentCtx = document.getElementById('intentChart');
    if (intentCtx) {
        intentChart = new Chart(intentCtx, {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: 'Confianza (%)',
                    data: [],
                    backgroundColor: '#000F9F',
                    borderColor: '#000000',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
    }

    // Entity Chart
    const entityCtx = document.getElementById('entityChart');
    if (entityCtx) {
        entityChart = new Chart(entityCtx, {
            type: 'doughnut',
            data: {
                labels: [],
                datasets: [{
                    data: [],
                    backgroundColor: [
                        '#000F9F',
                        '#4CAF50',
                        '#FF9800',
                        '#2196F3',
                        '#9C27B0'
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
    }
}

function updateCharts() {
    // Update intent chart
    if (intentChart) {
        const intents = Object.keys(analyticsData.intents);
        const counts = Object.values(analyticsData.intents);
        intentChart.data.labels = intents;
        intentChart.data.datasets[0].data = counts;
        intentChart.update();
    }

    // Update entity chart
    if (entityChart) {
        const entities = Object.keys(analyticsData.entities);
        const counts = Object.values(analyticsData.entities);
        entityChart.data.labels = entities;
        entityChart.data.datasets[0].data = counts;
        entityChart.update();
    }
}

// Utility Functions
function showLoading(text = 'Procesando...') {
    elements.loadingOverlay.querySelector('.loading-text').textContent = text;
    elements.loadingOverlay.classList.remove('hidden');
}

function hideLoading() {
    elements.loadingOverlay.classList.add('hidden');
}

function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    elements.toastContainer.appendChild(toast);
    
    setTimeout(() => {
        toast.style.animation = 'slideIn 0.3s ease-out reverse';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

