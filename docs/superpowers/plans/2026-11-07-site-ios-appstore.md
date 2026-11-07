# План: iOS-версия в App Store на сайте

Спека: `docs/superpowers/specs/2026-11-07-site-ios-appstore-design.md`.

## Задача 1. Кнопка, FAQ и JSON-LD на обеих страницах

Файлы: `site/index.html`, `site/en/index.html`, `site/assets/style.css`.

1. CSS: `.btns { display: flex; flex-wrap: wrap; gap: 10px; }` и `.btn.alt` (прозрачный фон, `color: var(--accent)`, `box-shadow: inset 0 0 0 1.5px var(--accent)` — без смены размеров относительно `.btn`).
2. В `.dl` обернуть `#download` и новую App Store-ссылку в `<div class="btns">`; после строки «Бесплатно…» добавить `<span class="note">iPhone · iOS 26.1+</span>`.
3. FAQ: пункт в конец `#faq .small`.
4. JSON-LD: второй `SoftwareApplication` `#software-ios`.

Проверка: `scripts/test-sync-site.sh`; `grep -c 'id="download"'` и `id="release"` = 1 на страницу; JSON-LD парсится и содержит 2 `SoftwareApplication`; скрин 375px и 1280px.
