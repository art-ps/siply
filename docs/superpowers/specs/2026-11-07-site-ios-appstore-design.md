# Сайт: iOS-версия в App Store

## Зачем

Siply вышел для iPhone в App Store: https://apps.apple.com/app/siply-simple-player/id6828888848. Сайт siply.top сейчас говорит только про Mac. Посетитель с iPhone должен узнать, что есть версия для него, и одним нажатием попасть в App Store.

Факты об iOS-версии (из `../siply-ios`): бесплатная, только iPhone, iOS 26.1+, те же папки/FLAC/lossless без медиатеки.

## Что меняется (`site/index.html` и `site/en/index.html` одинаково)

1. **Hero, блок `.dl`.** Рядом с кнопкой «Скачать для macOS» — вторая кнопка-ссылка на App Store:
   - RU «Скачать для iOS», EN «Download for iOS»;
   - `data-umami-event="download-ios"`;
   - вторичный стиль: контур и текст цвета `var(--accent)`, прозрачный фон (новый класс, например `.btn.alt`), чтобы Mac-кнопка оставалась главной;
   - кнопки в один ряд с переносом на узких экранах;
   - под существующими строками — новая строка `.note`: RU «iPhone · iOS 26.1+», EN «iPhone · iOS 26.1+».
2. **FAQ.** Новый пункт в конце: RU «Есть ли Siply для iPhone?» — «Да, в App Store, бесплатно. Нужна iOS 26.1 или новее.» со ссылкой на App Store; EN «Is there Siply for iPhone?» — «Yes, on the App Store, free. Requires iOS 26.1 or later.»
3. **JSON-LD.** В `@graph` второй `SoftwareApplication` с `@id` `https://siply.top/#software-ios`: name «Siply», `operatingSystem` «iOS 26.1 or later», `applicationCategory` MultimediaApplication, `isAccessibleForFree` true, `downloadUrl` = ссылка App Store, `offers` цена 0 USD, `url` https://siply.top/, author/license как у Mac-версии.

## Ограничения

- `scripts/sync-site.sh` требует ровно один `id="download"` и один `id="release"` на странице. Новые элементы эти id не используют.
- Без JS, без новых файлов/картинок, без внешних зависимостей.

## Не делаем

- title, meta description, og/twitter — остаются про Mac (SEO). h1 — «для macOS и iOS» (решение пользователя).
- Шаги «Установка» — остаются про dmg.
- Официальный бейдж Apple «Download on the App Store» — не ставим (моё решение; можно добавить позже).
- sitemap/robots не трогаем.

## Приёмка (проверки)

- `scripts/test-sync-site.sh` проходит.
- В каждой странице ровно один `id="download"`, один `id="release"`, ровно одна ссылка `apps.apple.com/app/siply-simple-player/id6828888848` в hero (+ одна в FAQ, + в JSON-LD).
- JSON-LD обеих страниц парсится (`python3 -c json.loads`) и содержит два `SoftwareApplication`.
- На ширине 375px обе кнопки видны, нет горизонтальной прокрутки; в светлой и тёмной теме контурная кнопка читаема.
