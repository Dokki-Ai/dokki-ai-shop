#!/bin/bash

# 1. Скачиваем Flutter SDK (если папки еще нет)
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Добавляем в PATH для текущей сессии
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Настройка и получение зависимостей
./flutter/bin/flutter config --enable-web
./flutter/bin/flutter pub get

# 4. ГЕНЕРАЦИЯ КОДА (Riverpod, Drift, JSON Serializable)
# Это создаст все необходимые .g.dart файлы перед сборкой
./flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs

# 5. ФИНАЛЬНАЯ СБОРКА
./flutter/bin/flutter build web --release