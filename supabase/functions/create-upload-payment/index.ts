import { serve } from "https://deno.land/std@0.177.1/http/server.ts"
import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno'

/**
 * Инициализация Stripe с использованием Fetch HttpClient для работы в среде Deno
 */
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

/**
 * CORS заголовки для доступа из Flutter-приложения (Web/Mobile)
 */
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  // Обработка Preflight-запросов браузера
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. ПРОВЕРКА АВТОРИЗАЦИИ
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')

    // Проверяем токен пользователя через встроенный API Supabase Auth
    const userRes = await fetch(`${Deno.env.get('SUPABASE_URL')}/auth/v1/user`, {
      headers: {
        'Authorization': authHeader,
        'apikey': Deno.env.get('SUPABASE_ANON_KEY') ?? ''
      }
    })
    
    const userData = await userRes.json()
    if (!userRes.ok || !userData.id) {
      throw new Error('401: Unauthorized access')
    }

    // 2. ПОЛУЧЕНИЕ ПАРАМЕТРОВ ПЛАТЕЖА
    const { businessId, charsNeeded } = await req.json()
    
    if (!businessId || !charsNeeded) {
      throw new Error('Параметры businessId и charsNeeded обязательны')
    }

    // 3. РАСЧЕТ ПАКЕТОВ (Логика: $1 за каждые 10,000 символов)
    // Округляем количество символов вверх до ближайшего пакета в 10к
    const packages = Math.ceil(charsNeeded / 10000)
    const totalChars = packages * 10000
    const amountCents = packages * 100  // 100 центов = $1

    // 4. СОЗДАНИЕ СЕССИИ STRIPE CHECKOUT
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'usd',
          product_data: {
            name: `Дополнительный объем данных: ${totalChars.toLocaleString()} символов`,
            description: `Разовое пополнение баланса для бизнеса (ID: ${businessId})`,
          },
          unit_amount: amountCents,
        },
        quantity: 1,
      }],
      mode: 'payment', // Разовый платеж, НЕ подписка
      client_reference_id: userData.id,
      customer_email: userData.email,
      
      // Ссылки для возврата (замени на свои домены, если нужно)
      success_url: 'https://app.dokki.org/',
      cancel_url: 'https://app.dokki.org/',

      // КРИТИЧНО: Метаданные для нашего вебхука
      metadata: {
        type: 'upload_credits',      // Маркер типа транзакции
        business_id: businessId,     // UUID бизнеса для начисления
        chars_amount: totalChars.toString(), // Количество купленных символов
        user_id: userData.id,        // ID пользователя
      },
    })

    // 5. ОТВЕТ КЛИЕНТУ
    return new Response(
      JSON.stringify({ 
        url: session.url, 
        totalChars, 
        amount: amountCents / 100,
        currency: 'USD'
      }), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error: any) {
    console.error(`❌ Payment session error: ${error.message}`)
    
    return new Response(
      JSON.stringify({ error: error.message }), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})