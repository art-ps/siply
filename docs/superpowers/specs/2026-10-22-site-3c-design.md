# Сайт Siply в дизайне 3c «Папка»

## Зачем

Переделать лендинг https://art-ps.github.io/siply/ по выбранному макету 3c (папка `~/Downloads/Переработка дизайна плеера/`, файл `Siply 3c.dc.html`, описание в `HANDOFF.md`).

## Источник

Макет — HTML со стилями инлайн и шаблонизатором `support.js` (`<x-dc>`, `{{ }}`, `<sc-for>`). Значения (цвета, размеры, отступы, тексты, структура) берутся из макета дословно. В сайт идёт статический HTML + `site/assets/style.css`, без `support.js` и шаблонов.

## Поведение

1. `site/index.html` (ru) — по макету 3c: тёплый фон `light-dark(#f7f4ee,#141210)`, акцент `oklch(0.58 0.14 55)`, шапка (иконка, «Siply», «Simple Player», навигация: Возможности, Установка, GitHub, English), hero (заголовок, подзаголовок, кнопка «Скачать для macOS», мета-строка, повёрнутый скриншот + плашка дерева папок), «Что умеет» (3 большие карточки с мини-иллюстрациями: папки, устройство вывода, Finder + 5 компактных), «Установка» (4 шага), футер. Тексты — из `renderVals()` макета (big3 = функции 0, 4, 5; small5 = 1, 2, 3, 6, 7).
2. `site/en/index.html` — тот же дизайн, тексты макета переведены на английский в той же (сокращённой) редакции; навигация «Features, Install, GitHub, Русский», ссылка на `/siply/`.
3. Тема следует системе: `color-scheme: light dark` + `light-dark()`. Переключателя темы нет (prop `theme` макета — только для редактора).
4. Скриншот: `site/assets/screenshot.png` заменяется скриншотом из макета (`uploads/screenshot-1792667660748-ez38.png`, Friday soundtrack). Он же в `og:image`. Можно ужать (размер/сжатие) без видимой потери.
5. **Кнопка «Скачать» сразу ведёт на последний DMG — как в LangFlip** (`langflip-site/scripts/sync-release.mjs`): ссылка и подпись вписаны в HTML статически, без запроса к GitHub API. `href="https://github.com/art-ps/siply/releases/download/vX.Y.Z/Siply-X.Y.Z.dmg"`, под кнопкой строка «Версия X.Y.Z · N,N МБ» (en: «Version X.Y.Z · N.N MB»). Новый `scripts/sync-site.sh path/to/Siply-X.Y.Z.dmg`: берёт версию из имени файла и размер из файла, переписывает href и строку версии в `site/index.html` и `site/en/index.html`; без аргумента — печатает, что сейчас на сайте. Вызывается в процессе релиза после `release.sh`, до коммита версии. `site/assets/release.js` удаляется. Сейчас сайт указывает на 1.2.1 (`Siply-1.2.1.dmg`).
6. **Сохраняем с текущего сайта** (решения Claude): `<title>`, `description`, `og:*`, `hreflang`, favicon, скрипт статистики `stats.pisarev.me`, `data-umami-event="download"` на кнопке. Ссылки на icon — относительные (`assets/icon.png`), не абсолютные как в макете.
7. Мобильная вёрстка (макет её не прорабатывал; решение Claude): на ширине 390 px нет горизонтального скролла, боковые отступы 16–20 px, hero в одну колонку, скриншот не вылезает за экран, карточки в одну колонку.
8. Доступность: у скриншота alt из макета, декоративные иконки `alt=""`, видимый фокус у ссылок/кнопки.

## Проверки

- Визуально в Chrome: ru и en, ширина ~1280 и 390, светлая и тёмная тема — совпадает с макетом 3c (макет открыть рядом для сравнения).
- Нет горизонтального скролла на 390 px (`document.documentElement.scrollWidth <= innerWidth`).
- `curl -sIL` по href кнопки (ru и en) отдаёт 200, DMG 1.2.1; строка версии совпадает с размером файла.
- `scripts/sync-site.sh` на копии с фиктивным `Siply-9.9.9.dmg` меняет href и строку в обеих страницах; на неверном имени файла падает с ошибкой; повторный запуск ничего не меняет.
- Нет ссылок на `support.js`, `uploads/`, `{{`.
- Все ссылки рабочие: `/siply/en/` ↔ `/siply/`, релизы, GitHub, vibecoded.ru/products/siply.

## Не делаем

- Переключатель темы, анимации, новые разделы.
- Изменения в приложении.
- Варианты 1c и 2c.

## Правка 2026-10-22: шаг 1 установки

Шаг 1 на сайте — «Скачайте Siply кнопкой выше.» (en: «Download Siply with the button above.»), простой текст без ссылки (кнопка — единственное место со ссылкой на DMG, её обновляет `sync-site.sh`). README не меняется: там кнопки нет.

## Правка 2026-10-22: домен siply.top

Сайт переехал на https://siply.top/ (Pages custom domain задан в настройках репозитория, файл `CNAME` не нужен — деплой через Actions). Все абсолютные `https://art-ps.github.io/siply/…` → `https://siply.top/…`: `og:image`, `hreflang` в `site/index.html` и `site/en/index.html`, ссылка «Сайт/Website» в `README.ru.md`/`README.md` (en → `https://siply.top/en/`). Проверка: `grep -rn "art-ps.github.io" site README*.md` пусто; после деплоя `curl -sI https://siply.top/` → 200, `https://art-ps.github.io/siply/` → 301 на siply.top.
