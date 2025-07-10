function loadCards(data) {
  data.forEach(item => {
    const manifest_url = `https://raw.githubusercontent.com/agungrbudiman/ios-apps/refs/heads/manifest/manifest/${item.device}_${item.app_id}.plist`;
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

document.addEventListener('DOMContentLoaded', async function() {
  const response = await fetch('data.json');
  const data = await response.json();
  loadCards(data);
  filters();
});

document.getElementById('filters').addEventListener('change', filters);

function filters() {
  const selected = this.value ?? document.getElementById('filters').value;
  const cards = document.querySelectorAll('.card');
  cards.forEach(card => {
    if (card.getAttribute('device') === selected) {
      card.style.display = '';
    } else {
      card.style.display = 'none';
    }
  });
}