#!/bin/bash
set -e

echo "🚀 Шаг 1: Сборка Flutter Web (Release)..."
# Убираем --web-renderer, чтобы Flutter сам выбрал оптимальный движок
flutter build web --release

echo "📦 Шаг 2: Переход в директорию сборки..."
cd build/web

echo "☁️ Шаг 3: Деплой на Vercel..."
# Используем --prod для моментального деплоя
vercel --prod --yes

echo "✅ Готово!"