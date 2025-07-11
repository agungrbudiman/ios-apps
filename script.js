document.getElementById('filters').addEventListener('change', filters);
const container = document.getElementById('container');

main();

async function main() {
  const response = await fetch('data.json');
  const data = await response.json();
  loadCards(data);
  filters();
}

function loadCards(data) {
  data.forEach(item => {
    const manifest_url = `${window.location.origin}/manifest/${item.device}_${item.app_id}.plist`;
    const card = document.createElement("div");
    card.className = "card";
    card.setAttribute("device", item.device);
    card.innerHTML = `
        <img src="${item.img_url}"/>
        <h3>${item.app_name}</h3>
        <p>${item.app_id}</p>
        <a href="itms-services://?action=download-manifest&url=${encodeURIComponent(manifest_url)}" class="install-btn">Install</a>
    `;
    container.appendChild(card);
  });
}

function filters(event) {
  const selected = event?.target?.value ?? document.getElementById('filters').value;
  const cards = document.querySelectorAll('.card');
  cards.forEach(card => {
    if (card.getAttribute('device') === selected) {
      card.style.display = '';
    } else {
      card.style.display = 'none';
    }
  });
}