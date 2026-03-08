const app = document.getElementById('app');
const slotBadge = document.getElementById('slotBadge');
const slotsGrid = document.getElementById('slotsGrid');
const characterDetails = document.getElementById('characterDetails');
const characterActions = document.getElementById('characterActions');
const createPanel = document.getElementById('createPanel');
const createSlotLabel = document.getElementById('createSlotLabel');
const createForm = document.getElementById('createForm');
const feedback = document.getElementById('feedback');
const refreshBtn = document.getElementById('refreshBtn');
const closeBtn = document.getElementById('closeBtn');
const playBtn = document.getElementById('playBtn');
const deleteBtn = document.getElementById('deleteBtn');
const newCharacterBtn = document.getElementById('newCharacterBtn');
const randomIdentityBtn = document.getElementById('randomIdentityBtn');
const cancelCreateBtn = document.getElementById('cancelCreateBtn');
const dobDay = document.getElementById('dobDay');
const dobMonth = document.getElementById('dobMonth');
const dobYear = document.getElementById('dobYear');

const state = {
  characters: [],
  maxSlots: 0,
  selectedSlot: 1,
  createSlot: 1,
  busy: false
};

const identityPool = {
  firstNames: ['Lucas', 'Noah', 'Ethan', 'Adam', 'Hugo', 'Lina', 'Emma', 'Lea', 'Sarah', 'Jade'],
  lastNames: ['Morel', 'Leroy', 'Durand', 'Fournier', 'Mercier', 'Roux', 'Lambert', 'Bonnet', 'Dupuis', 'Caron'],
  nationalities: ['Francaise', 'Belge', 'Canadienne', 'Espagnole', 'Italienne', 'Portugaise']
};

function esc(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function pad2(value) {
  return String(value).padStart(2, '0');
}

function setFeedback(message = '', type = 'warn') {
  feedback.textContent = message;
  feedback.style.color = type === 'ok' ? 'var(--ok)' : type === 'error' ? 'var(--danger)' : 'var(--warn)';
}

async function nui(route, data = {}) {
  const response = await fetch(`https://${GetParentResourceName()}/${route}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
  return response.json();
}

function setBusy(value) {
  state.busy = value;
  app.querySelectorAll('button').forEach((button) => {
    button.disabled = value;
  });
}

function getCharacterBySlot(slot) {
  return state.characters.find((character) => Number(character.slot) === Number(slot)) || null;
}

function getFirstEmptySlot() {
  for (let i = 1; i <= state.maxSlots; i += 1) {
    if (!getCharacterBySlot(i)) {
      return i;
    }
  }
  return null;
}

function buildDobSelects() {
  if (dobDay.childElementCount > 0) {
    return;
  }

  for (let day = 1; day <= 31; day += 1) {
    dobDay.insertAdjacentHTML('beforeend', `<option value="${day}">${day}</option>`);
  }

  const months = ['Janvier', 'Fevrier', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Aout', 'Septembre', 'Octobre', 'Novembre', 'Decembre'];
  months.forEach((month, index) => {
    dobMonth.insertAdjacentHTML('beforeend', `<option value="${index + 1}">${month}</option>`);
  });

  for (let year = 2010; year >= 1940; year -= 1) {
    dobYear.insertAdjacentHTML('beforeend', `<option value="${year}">${year}</option>`);
  }
}

function composeBirthDate() {
  const day = Number(dobDay.value);
  const month = Number(dobMonth.value);
  const year = Number(dobYear.value);

  if (!day || !month || !year) {
    return null;
  }

  return `${year}-${pad2(month)}-${pad2(day)}`;
}

function randomizeIdentity() {
  const firstName = identityPool.firstNames[Math.floor(Math.random() * identityPool.firstNames.length)];
  const lastName = identityPool.lastNames[Math.floor(Math.random() * identityPool.lastNames.length)];
  const nationality = identityPool.nationalities[Math.floor(Math.random() * identityPool.nationalities.length)];

  createForm.elements.firstName.value = firstName;
  createForm.elements.lastName.value = lastName;
  createForm.elements.nationality.value = nationality;
}

function renderSlots() {
  slotBadge.textContent = `${state.characters.length} / ${state.maxSlots} slots`;

  const cards = [];
  for (let slot = 1; slot <= state.maxSlots; slot += 1) {
    const character = getCharacterBySlot(slot);
    const selectedClass = state.selectedSlot === slot ? 'selected' : '';

    if (character) {
      cards.push(`
        <button class="slot-card ${selectedClass}" data-slot="${slot}">
          <h3>Slot #${slot} • ${esc(character.firstName)} ${esc(character.lastName)}</h3>
          <p>${esc(character.sex.toUpperCase())} • ${esc(character.birthDate)}</p>
          <p>${esc(character.nationality)}</p>
        </button>
      `);
    } else {
      cards.push(`
        <button class="slot-card slot-empty ${selectedClass}" data-slot="${slot}">
          <h3>Slot #${slot}</h3>
          <p>Libre - clique pour creer</p>
        </button>
      `);
    }
  }

  slotsGrid.innerHTML = cards.join('');
}

function renderDetails() {
  const selectedCharacter = getCharacterBySlot(state.selectedSlot);

  if (!selectedCharacter) {
    characterDetails.innerHTML = `
      <p class="detail-main">Slot #${state.selectedSlot}</p>
      <p class="detail-line">Aucun personnage sur ce slot.</p>
      <p class="detail-line muted">Clique sur "Nouveau personnage" pour commencer la creation.</p>
    `;
    characterActions.classList.add('hidden');
    return;
  }

  characterDetails.innerHTML = `
    <p class="detail-main">${esc(selectedCharacter.firstName)} ${esc(selectedCharacter.lastName)}</p>
    <p class="detail-line">Sexe: ${esc(selectedCharacter.sex.toUpperCase())}</p>
    <p class="detail-line">Date de naissance: ${esc(selectedCharacter.birthDate)}</p>
    <p class="detail-line">Nationalite: ${esc(selectedCharacter.nationality)}</p>
    <p class="detail-line">Job: ${esc(selectedCharacter.job)} (grade ${esc(selectedCharacter.jobGrade)})</p>
    <p class="detail-line">Cash: ${esc(selectedCharacter.money)}$ • Banque: ${esc(selectedCharacter.bank)}$</p>
  `;

  characterActions.classList.remove('hidden');
}

function openCreatePanel(slot) {
  const castedSlot = Number(slot);
  if (!castedSlot || castedSlot < 1 || castedSlot > state.maxSlots) {
    return;
  }

  if (getCharacterBySlot(castedSlot)) {
    setFeedback('Ce slot est deja occupe.', 'error');
    return;
  }

  state.createSlot = castedSlot;
  createSlotLabel.textContent = `Slot #${castedSlot}`;
  createPanel.classList.remove('hidden');
}

function closeCreatePanel() {
  createPanel.classList.add('hidden');
}

function renderAll() {
  renderSlots();
  renderDetails();
}

async function refreshCharacters() {
  setBusy(true);
  setFeedback('Actualisation en cours...');

  try {
    const result = await nui('mc:refresh');
    if (!result?.ok) {
      setFeedback(`Erreur: ${result?.error || 'refresh_failed'}`, 'error');
      return;
    }

    state.characters = result.characters || [];
    state.maxSlots = result.maxSlots || 0;
    if (state.selectedSlot > state.maxSlots) {
      state.selectedSlot = 1;
    }

    renderAll();
    setFeedback('Liste actualisee.', 'ok');
  } catch (error) {
    setFeedback(`Erreur NUI: ${error.message}`, 'error');
  } finally {
    setBusy(false);
  }
}

slotsGrid.addEventListener('click', (event) => {
  const slotCard = event.target.closest('.slot-card');
  if (!slotCard || state.busy) {
    return;
  }

  const slot = Number(slotCard.dataset.slot);
  state.selectedSlot = slot;
  renderAll();

  if (getCharacterBySlot(slot)) {
    closeCreatePanel();
  } else {
    openCreatePanel(slot);
  }
});

newCharacterBtn.addEventListener('click', () => {
  const slot = getFirstEmptySlot();
  if (!slot) {
    setFeedback('Tous les slots sont occupes.', 'error');
    return;
  }

  state.selectedSlot = slot;
  renderAll();
  openCreatePanel(slot);
});

playBtn.addEventListener('click', async () => {
  const selectedCharacter = getCharacterBySlot(state.selectedSlot);
  if (!selectedCharacter) {
    setFeedback('Aucun personnage selectionne.', 'error');
    return;
  }

  setBusy(true);
  setFeedback('Connexion en cours...');

  try {
    const result = await nui('mc:selectCharacter', { characterId: selectedCharacter.characterId });
    if (!result?.ok) {
      setFeedback(`Connexion refusee: ${result?.error || 'unknown'}`, 'error');
      return;
    }
    setFeedback('Personnage charge.', 'ok');
  } catch (error) {
    setFeedback(`Erreur NUI: ${error.message}`, 'error');
  } finally {
    setBusy(false);
  }
});

deleteBtn.addEventListener('click', async () => {
  const selectedCharacter = getCharacterBySlot(state.selectedSlot);
  if (!selectedCharacter) {
    setFeedback('Aucun personnage selectionne.', 'error');
    return;
  }

  const confirmDelete = confirm(`Supprimer ${selectedCharacter.firstName} ${selectedCharacter.lastName} ?`);
  if (!confirmDelete) {
    return;
  }

  setBusy(true);
  setFeedback('Suppression en cours...');

  try {
    const result = await nui('mc:deleteCharacter', { characterId: selectedCharacter.characterId });
    if (!result?.ok) {
      setFeedback(`Suppression refusee: ${result?.error || 'unknown'}`, 'error');
      return;
    }

    setFeedback('Personnage supprime.', 'ok');
    await refreshCharacters();
  } catch (error) {
    setFeedback(`Erreur NUI: ${error.message}`, 'error');
  } finally {
    setBusy(false);
  }
});

randomIdentityBtn.addEventListener('click', randomizeIdentity);
cancelCreateBtn.addEventListener('click', closeCreatePanel);

createForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  if (state.characters.length >= state.maxSlots) {
    setFeedback('Tu as atteint la limite de slots.', 'error');
    return;
  }

  if (getCharacterBySlot(state.createSlot)) {
    setFeedback('Le slot choisi est deja occupe.', 'error');
    return;
  }

  const birthDate = composeBirthDate();
  if (!birthDate) {
    setFeedback('DOB invalide.', 'error');
    return;
  }

  const payload = {
    firstName: String(createForm.elements.firstName.value || '').trim(),
    lastName: String(createForm.elements.lastName.value || '').trim(),
    sex: createForm.elements.sex.value,
    nationality: String(createForm.elements.nationality.value || '').trim(),
    birthDate,
    slot: state.createSlot
  };

  setBusy(true);
  setFeedback('Creation du personnage...');

  try {
    const result = await nui('mc:createCharacter', payload);
    if (!result?.ok) {
      setFeedback(`Creation refusee: ${result?.error || 'unknown'}`, 'error');
      return;
    }

    setFeedback('Personnage cree avec succes.', 'ok');
    closeCreatePanel();
    createForm.reset();
    await refreshCharacters();
    state.selectedSlot = Number(result.character?.slot || state.selectedSlot);
    renderAll();
  } catch (error) {
    setFeedback(`Erreur NUI: ${error.message}`, 'error');
  } finally {
    setBusy(false);
  }
});

refreshBtn.addEventListener('click', refreshCharacters);

closeBtn.addEventListener('click', async () => {
  await nui('mc:closeAttempt');
});

window.addEventListener('message', (event) => {
  const { action, payload } = event.data || {};

  if (action === 'open') {
    buildDobSelects();
    app.classList.remove('hidden');
    state.characters = payload.characters || [];
    state.maxSlots = payload.maxSlots || 0;

    state.selectedSlot = 1;
    const firstOccupied = state.characters[0];
    if (firstOccupied) {
      state.selectedSlot = Number(firstOccupied.slot);
    }

    renderAll();
    closeCreatePanel();
    setFeedback('');
    return;
  }

  if (action === 'close') {
    app.classList.add('hidden');
    closeCreatePanel();
    setFeedback('');
  }
});
