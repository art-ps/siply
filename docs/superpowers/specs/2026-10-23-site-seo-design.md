# SEO сайта siply.top

## Зачем

По итогам SEO-аудита (4 агента: technical, schema, content, GEO; оценка ~60/100) закрыть пробелы индексации, разметки, веса страницы и сигналов доверия. Критичных проблем нет; редиректы, HTTPS, lang, hreflang ru↔en в порядке.

## Решения пользователя

Берём технические пункты 1–5 и все четыре правки текста: title/description под запросы, «бесплатно, открытый код» + LICENSE (MIT), блок «Вопросы», автор в футере.

## Поведение

### 1. `<head>` обеих страниц (`site/index.html`, `site/en/index.html`)

- ru `<title>` и `og:title`: `Siply — бесплатный музыкальный плеер для Mac: FLAC и музыка из папок`
- ru `description` и `og:description`: `Бесплатный лёгкий плеер для macOS: открыл папку — слушаешь. FLAC, MP3, AAC, WAV без импорта и медиатеки. Нативный, с открытым кодом, macOS 14+.`
- en `<title>` и `og:title`: `Siply — free Mac music player for folders and FLAC`
- en `description` и `og:description`: `Free, lightweight native macOS music player: open a folder and listen. Plays FLAC, MP3, AAC and WAV with no import and no library. Open source, macOS 14+.`
- `<link rel="canonical">` на свой URL (`https://siply.top/`, `https://siply.top/en/`); `<link rel="alternate" hreflang="x-default" href="https://siply.top/">` рядом с ru/en.
- `og:url` (свой URL), `og:type` = `website`, `og:site_name` = `Siply`, `og:locale` (`ru_RU` / `en_US`) + `og:locale:alternate` (другой), `og:image` → `https://siply.top/assets/screenshot.jpg` + `og:image:width`/`height` (реальные), `og:image:alt`; `twitter:card` = `summary_large_image`.
- Иконки: `<link rel="icon" href="/favicon.ico" sizes="32x32">`, `<link rel="icon" href="/assets/icon.png" type="image/png">`, `<link rel="apple-touch-icon" href="/assets/apple-touch-icon.png">`.
- JSON-LD `@graph`: WebSite, WebPage (свой язык и URL), SoftwareApplication, Person — по образцу из аудита schema-агента. Без `softwareVersion`, `downloadUrl`, `fileSize`, рейтингов и отзывов (иначе расходится с `sync-site.sh`). `applicationCategory` = `MultimediaApplication`, `operatingSystem` = `macOS 14 or later`, `isAccessibleForFree`: true, `offers` price `0` USD с `url` своей страницы, `license` = `https://opensource.org/licenses/MIT`, `author` Person «Artem Pisarev» `https://github.com/art-ps`, `sameAs` GitHub-репо и `https://vibecoded.ru/products/siply`. `featureList` — заголовки карточек «Что умеет» этой страницы дословно. Без `codeRepository`.

### 2. Файлы в корне сайта

- `site/robots.txt`: `User-agent: *` / `Allow: /` / `Sitemap: https://siply.top/sitemap.xml`.
- `site/sitemap.xml`: обе страницы, у каждой `xhtml:link` ru, en, x-default.
- `site/404.html`: короткая двуязычная страница («Страница не найдена» / «Page not found», ссылки на `/` и `/en/`), стиль сайта, `<meta name="robots" content="noindex">`, все пути абсолютные (`/assets/style.css`).
- `site/favicon.ico` (32×32 из `assets/icon.png`), `site/assets/apple-touch-icon.png` (180×180).

### 3. Скриншот

`assets/screenshot.png` (912 КБ) заменяется: `assets/screenshot.webp` (2000 px) + `assets/screenshot-1000.webp` (1000 px) через `cwebp`, `assets/screenshot.jpg` (2000 px, q≈82) как fallback и `og:image`. В hero `<picture>` с `srcset` WebP и `<img src="assets/screenshot.jpg">` (en — `../assets/`), те же width/height/alt, `fetchpriority="high"`, без lazy. PNG удаляется, ссылок на него не остаётся.

### 4. Видимые тексты

- Мета-строка под кнопкой: ru `Бесплатно, открытый код · macOS 14+ · Apple Silicon и Intel`; en `Free and open source · macOS 14+ · Apple Silicon and Intel`.
- Блок «Вопросы» / «Questions» после «Установка», до футера: `<section id="faq">`, `h2`, 4 пары `h3` + `p`, вёрстка из существующих стилей карточек (как `.mini`). Без FAQPage-разметки.
  - ru:
    1. «Siply бесплатный?» — «Да. Siply бесплатный и с открытым кодом под лицензией MIT. Исходники и все версии лежат на GitHub.»
    2. «Какие форматы он играет?» — «Всё, что играет сама macOS: MP3, AAC/M4A, FLAC, WAV, AIFF и CAF, включая lossless. OGG и APE не поддерживаются.»
    3. «Нужна ли медиатека?» — «Нет. Siply читает папки как есть и ничего не импортирует и не индексирует. Открыли папку — слушаете.»
    4. «Какой нужен Mac?» — «macOS 14 или новее, Apple Silicon или Intel.»
  - en:
    1. «Is Siply free?» — «Yes. Siply is free and open source under the MIT license. The source and every release are on GitHub.»
    2. «Which formats does it play?» — «Everything macOS plays: MP3, AAC/M4A, FLAC, WAV, AIFF and CAF, lossless included. OGG and APE are not supported.»
    3. «Do I need a library?» — «No. Siply reads your folders as they are, with no import and no indexing. Open a folder and listen.»
    4. «Which Mac do I need?» — «macOS 14 or later, Apple Silicon or Intel.»
  - Ссылка «на GitHub» / «on GitHub» в ответе 1 → `https://github.com/art-ps/siply`.
- Футер: в начало `Автор — Артём Писарев` / `By Artem Pisarev`; к ссылкам справа `Сообщить о проблеме` / `Report an issue` → `https://github.com/art-ps/siply/issues`.
- Навигация в шапке не меняется.
- Упоминание нотаризации убирается с видимых страниц (решение пользователя).

### 5. Лицензия

`LICENSE` в корне репо — стандартный текст MIT, `Copyright (c) 2026 Artem Pisarev`. В `README.md` / `README.ru.md` — короткий раздел License / Лицензия: MIT.

## Проверки

- Рендер (WebKit, как раньше): ru и en, 1280 и 390, светлая/тёмная; нет горизонтального скролла; FAQ и футер в стиле макета.
- `bash scripts/test-sync-site.sh` → OK; `scripts/sync-site.sh build/release/Siply-1.2.1.dmg` не меняет `site/`.
- JSON-LD валиден (`python3 -c json.loads` на извлечённом блоке); после деплоя — validator.schema.org.
- После деплоя: `curl` 200 для `/robots.txt`, `/sitemap.xml`, `/favicon.ico`, `/assets/screenshot.webp`; 404 на несуществующем пути отдаёт свою страницу со статусом 404.
- `grep -rn "screenshot.png" site` пусто; вес hero-картинки ≤ 300 КБ.

## Не делаем

- Отдельную OG-картинку 1200×630, llms.txt, fingerprint ассетов, preconnect.
- FAQPage/HowTo-разметку, рейтинги.
- Сравнение с foobar2000 и прочие маркетинговые формулировки.
- Внешние площадки (Reddit, Product Hunt, AlternativeTo, YouTube) — только совет пользователю.
