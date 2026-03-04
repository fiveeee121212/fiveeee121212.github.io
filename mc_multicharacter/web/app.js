const app = document.getElementById('app');
const charactersList = document.getElementById('charactersList');
const createForm = document.getElementById('createForm');
const refreshBtn = document.getElementById('refreshBtn');
const closeBtn = document.getElementById('closeBtn');
const feedback = document.getElementById('feedback');
const slotBadge = document.getElementById('slotBadge');

const state = {
  characters: [],
  maxSlots: 0,
  busy: false
};

function esc(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
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

function renderCharacters() {
  slotBadge.textContent = `${state.characters.length} / ${state.maxSlots} slots utilisés`;

  if (state.characters.length === 0) {
    charactersList.innerHTML = '<p class="empty">Aucun personnage pour le moment.</p>';
    return;
  }

  charactersList.innerHTML = state.characters.map((character) => {
    const fullName = `${esc(character.firstName)} ${esc(character.lastName)}`;
    return `
      <article class="card" data-character-id="${esc(character.characterId)}">
        <h3>${fullName}</h3>
        <p class="meta">Sexe: ${esc(character.sex.toUpperCase())} • Naissance: ${esc(character.birthDate)}</p>
        <p class="meta">Nationalité: ${esc(character.nationality)}</p>
        <p class="meta">Job: ${esc(character.job)} (grade ${esc(character.jobGrade)})</p>
        <p class="meta">Argent: ${esc(character.money)}$ • Banque: ${esc(character.bank)}$</p>
        <div class="actions">
          <button class="success" data-action="select">Jouer</button>
          <button class="danger" data-action="delete">Supprimer</button>
        </div>
      </article>
    `;
  }).join('');
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
    renderCharacters();
    setFeedback('Liste actualisée.', 'ok');
  } catch (error) {
    setFeedback(`Erreur NUI: ${error.message}`, 'error');
  } finally {
    setBusy(false);
  }
}

createForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  if (state.characters.length >= state.maxSlots) {
    setFeedback('Tu as atteint la limite de slots.', 'error');
    return;
  }

  const formData = new FormData(createForm);
  const payload = Object.fromEntries(formData.entries());

  setBusy(true);
  setFeedback('Création du personnage...');

  try {
    const result = await nui('mc:createCharacter', payload);
    if (!result?.ok) {
      setFeedback(`Création refusée: ${result?.error || 'inconnue'}`, 'error');
      return;
    }

    createForm.reset();
    setFeedback('Personnage créé avec succès.', 'ok');
    await refreshCharacters();
  } catch (error) {
    setFeedback(`Erreur NUI: ${error.message}`, 'error');
  } finally {
    setBusy(false);
  }
});

charactersList.addEventListener('click', async (event) => {
  const button = event.target.closest('button[data-action]');
  if (!button || state.busy) {
    return;
  }

  const card = event.target.closest('.card');
  if (!card) {
    return;
  }

  const characterId = card.dataset.characterId;
  const action = button.dataset.action;

  if (!characterId || !action) {
    return;
  }

  if (action === 'delete') {
    const confirmDelete = confirm('Supprimer ce personnage définitivement ?');
    if (!confirmDelete) {
      return;
    }
  }

  setBusy(true);
  setFeedback(action === 'select' ? 'Connexion en cours...' : 'Suppression en cours...');

  try {
    const route = action === 'select' ? 'mc:selectCharacter' : 'mc:deleteCharacter';
    const result = await nui(route, { characterId });

    if (!result?.ok) {
      setFeedback(`Action refusée: ${result?.error || 'inconnue'}`, 'error');
      return;
    }

    if (action === 'select') {
      setFeedback('Personnage chargé.', 'ok');
      return;
    }

    setFeedback('Personnage supprimé.', 'ok');
    await refreshCharacters();
  } catch (error) {
    setFeedback(`Erreur NUI: ${error.message}`, 'error');
  } finally {
    setBusy(false);
  }
});

refreshBtn.addEventListener('click', () => {
  refreshCharacters();
});

closeBtn.addEventListener('click', async () => {
  await nui('mc:closeAttempt');
});

window.addEventListener('message', (event) => {
  const { action, payload } = event.data || {};

  if (action === 'open') {
    app.classList.remove('hidden');
    state.characters = payload.characters || [];
    state.maxSlots = payload.maxSlots || 0;
    renderCharacters();
    setFeedback('');
    return;
  }

  if (action === 'close') {
    app.classList.add('hidden');
    setFeedback('');
  }
});
