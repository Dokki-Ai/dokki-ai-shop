import { serve } from "https://deno.land/std@0.177.1/http/server.ts"
import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')

    // Верификация через Supabase Auth API
    const userRes = await fetch(`${Deno.env.get('SUPABASE_URL')}/auth/v1/user`, {
      headers: {
        'Authorization': authHeader,
        'apikey': Deno.env.get('SUPABASE_ANON_KEY') ?? ''
      }
    })

    const userData = await userRes.json()
    if (!userRes.ok || !userData.id) {
      console.error('Auth failed:', userData)
      throw new Error('401: Unauthorized')
    }

    const userId = userData.id
    const userEmail = userData.email

    const { plan, successUrl, cancelUrl } = await req.json()
    if (!plan) throw new Error('Plan обязателен')

    const priceMap: Record<string, string> = {
      'monthly_50': Deno.env.get('STRIPE_PRICE_BASIC') ?? '',
      'monthly_100': Deno.env.get('STRIPE_PRICE_PRO') ?? '',
    }

    const priceId = priceMap[plan]
    if (!priceId) throw new Error(`Неизвестный план: ${plan}`)

    console.log(`🛠 Создание сессии для ${userId} (${userEmail}), план: ${plan}`)

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{ price: priceId, quantity: 1 }],
      mode: 'subscription',
      client_reference_id: userId,
      customer_email: userEmail,
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: { user_id: userId, plan: plan },
    })

    console.log(`✅ Сессия создана: ${session.id}`)

    return new Response(JSON.stringify({ url: session.url }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error: any) {
    console.error('❌ Ошибка:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})