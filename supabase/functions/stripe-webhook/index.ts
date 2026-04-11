import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4'

/**
 * Инициализация Stripe с использованием секретного ключа из переменных окружения
 */
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

/**
 * Секрет вебхука для проверки подписи (берется из настроек Stripe Dashboard)
 */
const endpointSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '';

serve(async (req: Request) => {
  const signature = req.headers.get('stripe-signature');

  // Шаг 1: Проверка наличия подписи
  if (!signature) {
    return new Response(JSON.stringify({ error: 'Missing stripe-signature header' }), { status: 400 });
  }

  try {
    const body = await req.text();
    let event;

    // Шаг 2: Верификация того, что запрос пришел именно от Stripe
    try {
      event = stripe.webhooks.constructEvent(body, signature, endpointSecret);
    } catch (err: any) {
      console.error(`❌ Signature verification failed: ${err.message}`);
      return new Response(JSON.stringify({ error: `Webhook Error: ${err.message}` }), { status: 400 });
    }

    console.log(`📦 Received event: ${event.type}`);

    // Инициализация клиента Supabase с Service Role Key (для обхода RLS)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // --- ОБРАБОТКА ЗАВЕРШЕНИЯ ОПЛАТЫ ---
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as any;

      // СЦЕНАРИЙ А: ПОДПИСКА (Ежемесячные тарифы)
      if (session.mode === 'subscription') {
        const userId = session.client_reference_id;
        const subscriptionId = session.subscription;
        
        if (!userId) throw new Error('Missing client_reference_id in session');

        // Получаем детали подписки из Stripe
        const subscription = await stripe.subscriptions.retrieve(subscriptionId);

        // Обновляем или создаем запись о подписке пользователя
        const { error: subError } = await supabase.from('subscriptions').upsert({
          user_id: userId,
          stripe_customer_id: session.customer,
          stripe_subscription_id: subscriptionId,
          status: 'active',
          plan: session.metadata?.plan ?? 'monthly_50',
          current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
          updated_at: new Date().toISOString(),
        }, { onConflict: 'user_id' });

        if (subError) throw subError;

        // Активируем бизнес-запись (переводим в статус setup для настройки)
        const botIdSlug = session.metadata?.bot_id ?? 'sales_basic';
        const category = botIdSlug.split('_')[0];
        const botName = `Dokki ${category.charAt(0).toUpperCase() + category.slice(1)}`;

        const { error: bizError } = await supabase.from('businesses').upsert({
          user_id: userId,
          bot_id: botIdSlug,
          bot_name: botName,
          business_name: botName,
          bot_category: category,
          status: 'setup',
          updated_at: new Date().toISOString(),
        }, { onConflict: 'user_id, bot_id' });

        if (bizError) throw bizError;
        console.log(`✅ Subscription activated for user: ${userId}`);
      }

      // СЦЕНАРИЙ Б: РАЗОВЫЙ ПЛАТЕЖ (Покупка кредитов символов - Pay-per-use)
      if (session.mode === 'payment' && session.metadata?.type === 'upload_credits') {
        const businessUuid = session.metadata.business_id; // UUID бизнеса
        const charsAmount = parseInt(session.metadata.chars_amount, 10);

        if (!businessUuid) throw new Error('Missing business_id in metadata');

        // Проверяем текущий баланс кредитов
        const { data: existing } = await supabase
          .from('upload_credits')
          .select('balance_chars')
          .eq('business_id', businessUuid)
          .single();

        if (existing) {
          // Обновляем существующий баланс
          const { error: updateError } = await supabase.from('upload_credits').update({
            balance_chars: existing.balance_chars + charsAmount,
            last_payment_amount: charsAmount,
            stripe_payment_id: session.payment_intent,
            updated_at: new Date().toISOString(),
          }).eq('business_id', businessUuid);
          
          if (updateError) throw updateError;
        } else {
          // Создаем новую запись для кошелька бизнеса
          const { error: insertError } = await supabase.from('upload_credits').insert({
            business_id: businessUuid,
            balance_chars: charsAmount,
            last_payment_amount: charsAmount,
            stripe_payment_id: session.payment_intent,
          });
          
          if (insertError) throw insertError;
        }
        console.log(`💰 Credits added: +${charsAmount} symbols for business ${businessUuid}`);
      }
    }

    // --- ОБРАБОТКА ОТМЕНЫ ПОДПИСКИ ---
    if (event.type === 'customer.subscription.deleted') {
      const subscription = event.data.object as any;
      
      const { error: cancelError } = await supabase
        .from('subscriptions')
        .update({ 
          status: 'cancelled', 
          updated_at: new Date().toISOString() 
        })
        .eq('stripe_subscription_id', subscription.id);

      if (cancelError) throw cancelError;
      console.log(`🚫 Subscription cancelled in DB: ${subscription.id}`);
    }

    // Возвращаем успешный ответ Stripe
    return new Response(JSON.stringify({ received: true }), { 
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (err: any) {
    console.error(`❌ Webhook Handler Error: ${err.message}`);
    return new Response(JSON.stringify({ error: err.message }), { 
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
})