# Branch Protection Rules - Настройка

## 📋 **Обзор**

Данная документация описывает настройку Branch Protection Rules для автоматического CI/CD workflow в GitHub репозитории.

## **Цель**

- Защитить `main` ветку от прямых push
- Разрешить merge только через Pull Request
- Обеспечить автоматический merge после успешного dev workflow
- Защитить от случайных изменений

## 🔧 **Настройка через GitHub Rulesets**

### **1. Переход к настройкам:**
```
Repository → Settings → Rules → Rulesets → New branch ruleset
```

### **2. Основные настройки Ruleset:**

#### **✅ Ruleset Name:**
```
main
```

#### **✅ Enforcement status:**
```
Active
```

### **3. Target branches (Целевые ветки):**

#### **✅ Add target:**
1. Нажмите **"Add target"**
2. Выберите **"Branch name"**
3. Введите: `main`

### **4. Rules (Правила):**

#### **✅ Restrict creations:**
- **Включено** ✅
- **Описание:** Только пользователи с bypass могут создавать ветки

#### **✅ Restrict updates:**
- **Включено** ✅
- **Описание:** Только через Pull Request

#### **✅ Require pull request:**
- **Отключено** ❌ (автоматический merge из dev)
- **Причина:** Все изменения уже протестированы в dev перед merge

#### **✅ Require status checks:**
- **Отключено** ❌ (тестирование происходит в dev ветке)
- **Причина:** Все изменения уже протестированы в dev перед merge

#### **✅ Require linear history:**
- **Включено** ✅
- **Описание:** Запрещает merge commits (используется fast-forward merge)

#### **✅ Restrict pushes that create files:**
- **Включено** ✅
- **Описание:** Защита от случайных файлов

### **5. Bypass list (Список исключений):**

#### **✅ Add bypass:**
1. Нажмите **"+ Add bypass"**
2. Выберите **"Your username"**
3. **Роль:** `Admin`
4. **Описание:** Позволяет вам делать merge даже с включенными правилами

### **6. Дополнительные настройки (если доступны):**

#### **✅ Require conversation resolution:**
- **Отключено** ❌ (не нужно для автоматического merge)

#### **✅ Require deployments to succeed:**
- **Отключено** ❌ (у нас нет deployment environments)

#### **✅ Lock branch:**
- **Отключено** ❌ (блокирует все изменения)

## **Итоговая конфигурация:**

```
Ruleset Name: main
Enforcement: Active

Target branches:
├── Branch name: main

Rules:
├── Restrict creations ✅
├── Restrict updates ✅
├── Require pull request ❌
│   └── Автоматический merge из dev
├── Require status checks ❌
│   └── Тестирование в dev ветке
├── Require linear history ✅
└── Restrict pushes that create files ✅

Bypass list:
├── Your username (Admin)
├── github-actions[bot] (GitHub Actions)
└── GITHUB_TOKEN (Workflow token)
```

## **Важно: Fast-Forward Merge**

При включенном правиле **"Require linear history"** workflow использует **fast-forward merge** вместо обычного merge commit. Это означает:

- ✅ **Нет merge commits** - история остается линейной
- ✅ **Все коммиты из dev** переносятся в main
- ✅ **Соблюдаются правила** Branch Protection
- ⚠️ **Требует синхронизации** - dev должен быть впереди main

### **Если fast-forward невозможен:**
Workflow автоматически выполнит rebase dev на main, а затем fast-forward merge. Это означает:

1. **Автоматический rebase** - dev перебазируется на main
2. **Fast-forward merge** - main обновляется без merge commits
3. **Линейная история** - соблюдается правило "Require linear history"
4. **Никаких ручных действий** - все происходит автоматически

### **Алгоритм workflow:**
```
1. Проверить, можно ли fast-forward merge
2. Если ДА → выполнить fast-forward merge
3. Если НЕТ → rebase dev на main → fast-forward merge
4. Запушить обновленный main
```

## **Проверка настроек:**

### **1. Убедитесь, что workflow job называется правильно:**
В `deploy-dev.yml`:
```yaml
test_dev_environment:
  name: Test Development Environment  # ← Должно совпадать!
```

### **2. Проверьте, что workflow запускается:**
- Push в `dev` ветку
- Workflow должен запуститься
- Job должен завершиться успешно

### **3. Проверьте, что merge работает:**
- После успешного workflow
- `dev` должен автоматически смержиться в `main`

## 🚨 **Частые ошибки:**

### **1. Неправильное название status check:**
```
❌ Неправильно: "Test and Deploy to Dev Environment"
✅ Правильно: "Test Development Environment"
```

### **2. Bypass list пустой:**
```
❌ Без этого вы не сможете делать merge
✅ Добавьте себя в bypass list
```

### **3. Неправильный branch name:**
```
❌ "main*" или "*/main"
✅ "main"
```

## **Скриншоты для справки:**

### **1. Target branches:**
```
Add target → Branch name → main
```

### **2. Rules:**
```
Restrict creations ✅
Restrict updates ✅
Require pull request ✅
Require status checks ✅
Require linear history ✅
Restrict pushes that create files ✅
```

### **3. Bypass list:**
```
+ Add bypass → Your username → Admin
```

## 🎯 **Результат после настройки:**

1. **Прямые push в `main`** будут заблокированы
2. **Merge возможен только** через PR
3. **PR может быть смержен** только после успешного dev workflow
4. **Вы сможете** делать merge (благодаря bypass list)
5. **Автоматический merge** будет работать

## **Следующие шаги:**

1. **Настройте Ruleset** согласно документации
2. **Протестируйте** workflow
3. **Проверьте**, что merge работает
4. **Убедитесь**, что production деплой запускается

## 📚 **Дополнительные ресурсы:**

- [GitHub Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- [GitHub Rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [GitHub Actions Workflows](https://docs.github.com/en/actions/using-workflows)

---

**Настройте именно так, и ваш workflow будет работать идеально!** 🚀
