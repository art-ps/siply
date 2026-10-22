# Ссылка vibecoded.ru Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** подпись «проект vibecoded.ru» со ссылкой в тулбаре и в «О программе».

**Architecture:** `ProjectLink` view в `ToolbarItem(.primaryAction)` на detail-колонке `ContentView`; `Credits.rtf` в `Siply/` — стандартная About-панель берёт его сама.

**Tech Stack:** SwiftUI, AppKit, XCTest, xcodegen.

**Spec:** `docs/superpowers/specs/2026-10-22-vibecoded-link-design.md`

## Global Constraints

- Deployment target macOS 14.0; API macOS 26 только под `#available(macOS 26, *)`.
- URL ровно `https://vibecoded.ru`. Текст ровно «проект vibecoded.ru».
- Без сторонних зависимостей. Info.plist генерирует xcodegen — правки только в `project.yml` (если вообще нужны).
- Не запускать и не убивать установленный Siply пользователя, не трогать UserDefaults `info.pisarev.siply`.
- Коммиты без `Co-Authored-By`.

## Review Focus

- Сборка под macOS 14: `sharedBackgroundVisibility` не должен ломать компиляцию/запуск ниже 26.
- Credits.rtf реально попадает в бандл (Copy Bundle Resources), а не только лежит в репо.
- Ссылка в RTF кликабельна (поле HYPERLINK), а не просто синий текст.

---

### Task 1: Credits.rtf и ссылка в тулбаре

**Files:**
- Create: `Siply/Credits.rtf`
- Create: `Siply/UI/ProjectLink.swift`
- Modify: `Siply/UI/ContentView.swift` (toolbar на detail-`Group`)
- Test: `SiplyTests/ProjectLinkTests.swift`

- [ ] **Step 1: тест** `testCreditsLinksToVibecoded`: `Bundle.main.url(forResource: "Credits", withExtension: "rtf")` не nil; `NSAttributedString(url:options:documentAttributes:)` → `string` содержит «проект vibecoded.ru»; атрибут `.link` в диапазоне «vibecoded.ru» равен `URL(string: "https://vibecoded.ru")` (атрибут может быть URL или String — сравнить по `absoluteString`/описанию).
- [ ] **Step 2:** прогнать — FAIL.
- [ ] **Step 3:** `Siply/Credits.rtf` — по центру, системный шрифт, «проект » + HYPERLINK "https://vibecoded.ru" на «vibecoded.ru». Убедиться, что xcodegen кладёт его в ресурсы.
- [ ] **Step 4:** тест PASS.
- [ ] **Step 5:** `struct ProjectLink: View` по спеке п.1 (комментарий-строка как в mac-transcribe). В `ContentView` detail-`Group` → `.toolbar { ToolbarItem(placement: .primaryAction) { ProjectLink() } }` + скрытие подложки на macOS 26 (спека п.2), так чтобы собиралось под 14.
- [ ] **Step 6:** полный прогон тестов — зелёные.
- [ ] **Step 7:** commit `feat: ссылка «проект vibecoded.ru» в тулбаре и в «О программе»`.
