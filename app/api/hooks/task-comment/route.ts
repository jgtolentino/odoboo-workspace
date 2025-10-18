import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  const secret = req.headers.get('x-webhook-secret');
  const expectedSecret = process.env.WQ_WEBHOOK_SECRET;

  // Verify webhook secret
  if (!secret || secret !== expectedSecret) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const body = await req.json();

    // Log the webhook payload for debugging
    console.log('Webhook received:', body);

    // In a real implementation, you might:
    // - Send real-time notifications to connected clients
    // - Update UI state
    // - Trigger additional workflows

    return NextResponse.json({ received: true, id: body.id });
  } catch (error) {
    console.error('Webhook error:', error);
    return NextResponse.json({ error: 'Invalid payload' }, { status: 400 });
  }
}
