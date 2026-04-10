#!/bin/bash

# 1. Скачиваем Flutter SDK (если папки еще нет)
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b 3.38.7
fi

# 2. Добавляем в PATH для текущей сессии
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Экспортируем переменные для build_runner (чтобы Envied их увидел)
export SUPABASE_URL=$SUPABASE_URL
export SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
export DEPLOY_SERVICE_URL=$DEPLOY_SERVICE_URL

# 4. Настройка и получение зависимостей
./flutter/bin/flutter config --enable-web
./flutter/bin/flutter pub get

# 5. ГЕНЕРАЦИЯ КОДА (Riverpod, Envied и др.)
# ./flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs

# 6. ФИНАЛЬНАЯ СБОРКА
./flutter/bin/flutter build web --release