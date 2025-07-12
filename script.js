const container = document.getElementById('container');
const filter = document.getElementById('filters');
const devices = [{"id": "401E", "name": "iPhone 13"}, {"id": "001C", "name": "iPhone 15"}];

let device_id = document.getElementById('filters').value;

filter.addEventListener('change', filters);

main();

async function main() {
  populateDevice();
  const response = await fetch('data.json');
  const data = await response.json();
  loadCards(data);
}

function populateDevice() {
  devices.forEach(device => {
    const option = document.createElement('option');
    option.value = device.id;
    option.text = device.name;
    filter.add(option);
  });
}

function cardClick(event) {
  if (event.target.matches('.install-btn')) {
    event.preventDefault();
    const device_id = document.getElementById('filters').value;
    const manifest_url = `${window.location.origin}/manifest/${device_id}/${this.id}.plist`;
    window.location.href = `itms-services://?action=download-manifest&url=${encodeURIComponent(manifest_url)}`;
  }
}

function loadCards(data) {
  data.forEach(item => {
    const manifest_url = `${window.location.origin}/manifest/${item.device}_${item.app_id}.plist`;
    const card = document.createElement("div");
    card.id = item.app_id;
    card.className = "card";
    card.addEventListener('click', cardClick);
    card.innerHTML = `
        <img src="${item.img_url}"/>
        <h3>${item.app_name}</h3>
        <p>${item.app_id}</p>
        <a class="install-btn">Install</div>
    `;
    container.appendChild(card);
  });
}

function filters(event) {
  device_id = this.value;
}