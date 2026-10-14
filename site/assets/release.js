// Кнопка «Скачать» → прямая ссылка на DMG последнего релиза, под ней версия и размер.
// Без сети или при лимите API кнопка ведёт на страницу последнего релиза.
(async () => {
  const ru = document.documentElement.lang === "ru";
  try {
    const r = await fetch("https://api.github.com/repos/art-ps/siply/releases/latest");
    if (!r.ok) return;
    const rel = await r.json();
    const dmg = rel.assets.find((a) => a.name.endsWith(".dmg"));
    if (!dmg) return;
    document.getElementById("download").href = dmg.browser_download_url;
    const mb = new Intl.NumberFormat(ru ? "ru" : "en", { maximumFractionDigits: 1 }).format(dmg.size / 1048576);
    const version = rel.tag_name.replace(/^v/, "");
    document.getElementById("release").textContent =
      ru ? `Версия ${version} · ${mb} МБ` : `Version ${version} · ${mb} MB`;
  } catch {}
})();
