const appbox = document.getElementById('appbox');
const devicebox = document.getElementById('devicebox');

let device_id;

devicebox.addEventListener('change', event => window.location.hash = event.target.selectedIndex );
appbox.addEventListener('click', cardClick);

main();

async function main() {
  const response = await fetch('data.json');
  const data = await response.json();
  loadDevice(data);
  loadCards(data);
  window.location.hash = window.location.hash || 0;
  devicebox.selectedIndex = window.location.hash.substring(1);
}

function loadDevice(data) {
  data.devices.forEach(device => {
    if (device.enabled) {
      const option = document.createElement('option');
      option.value = device.id;
      option.text = device.name;
      devicebox.add(option);
    }
  });
}

function cardClick(event) {
  if (event.target.matches('.install-btn')) {
    const device_id = devicebox.value;
    const app_id = event.target.parentNode.id;
    const manifest_url = `${window.location.origin}/manifest/${device_id}/${app_id}.plist`;
    window.location.href = `itms-services://?action=download-manifest&url=${encodeURIComponent(manifest_url)}`;
  }
}

function loadCards(data) {
  data.apps.forEach(item => {
    const manifest_url = `${window.location.origin}/manifest/${item.device}_${item.app_id}.plist`;
    const card = document.createElement("div");
    card.id = item.app_id;
    card.className = "card";
    card.innerHTML = `
        <img src="${item.img_url}"/>
        <h3>${item.app_name}</h3>
        <p>${item.app_id}</p>
        <div class="install-btn">Install</div>
    `;
    appbox.appendChild(card);
  });
}
