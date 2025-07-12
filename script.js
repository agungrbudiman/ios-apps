document.getElementById('filters').addEventListener('change', filters);
document.getElementById('container').addEventListener('click', cardClick);

const container = document.getElementById('container');
let device_id = document.getElementById('filters').value;

main();

async function main() {
  const response = await fetch('data.json');
  const data = await response.json();
  loadCards(data);
}

function cardClick(event) {
  event.stopPropagation();
  if (event.target.matches('.install-btn')) {
    event.preventDefault();
    const device_id = document.getElementById('filters').value;
    const manifest_url = `${window.location.origin}/manifest/${device_id}_${this.id}.plist`;
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