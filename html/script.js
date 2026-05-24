const app = document.getElementById('app');
const closeBtn = document.getElementById('closeBtn');
const seatGrid = document.getElementById('seatGrid');

const post = (action, data = {}) => {
  fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
};

function renderSeats(seats = [], currentSeat = null) {
  if (!seatGrid) return;

  seatGrid.innerHTML = '';
  seatGrid.classList.remove('two-seats', 'four-seats');
  seatGrid.classList.add(seats.length <= 2 ? 'two-seats' : 'four-seats');

  seats.forEach((seat) => {
    const btn = document.createElement('button');
    btn.className = 'seat-btn';
    btn.textContent = seat.label;
    btn.dataset.action = 'seat';
    btn.dataset.seat = seat.id;

    if (seat.id === currentSeat) {
      btn.classList.add('active');
    }

    btn.addEventListener('click', () => {
      post('menuAction', {
        action: 'seat',
        seat: seat.id
      });
    });

    seatGrid.appendChild(btn);
  });
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data) return;

  if (data.action === 'openVehicleMenu') {
    app.classList.remove('hidden');
    applyState(data.state || {});
  }

  if (data.action === 'closeVehicleMenu') {
    app.classList.add('hidden');
  }

  if (data.action === 'syncVehicleMenu') {
    applyState(data.state || {});
  }
});

function applyState(state) {
  renderSeats(state.seats || [], state.currentSeat ?? null);

  document.querySelectorAll('[data-window]').forEach(btn => {
    const idx = Number(btn.dataset.window);
    btn.classList.toggle('active', !!(state.windows && state.windows[idx]));
  });

  document.querySelectorAll('[data-mode]').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.mode === state.lightMode);
  });

  document.querySelectorAll('[data-door]').forEach(btn => {
    const idx = Number(btn.dataset.door);
    btn.classList.toggle('active', !!(state.doors && state.doors[idx]));
  });

  const interior = document.querySelector('[data-action="interiorLight"]');
  if (interior) interior.classList.toggle('active', !!state.interiorLight);
}

closeBtn.addEventListener('click', () => post('closeMenu'));

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    post('closeMenu');
  }
});

document.querySelectorAll('[data-action]').forEach(btn => {
  if (btn.dataset.action === 'seat') return;

  btn.addEventListener('click', () => {
    const action = btn.dataset.action;
    const payload = { ...btn.dataset };
    post('menuAction', payload);
  });
});
