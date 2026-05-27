// Lablio – delete-account Edge Function
//
// Permanently deletes the calling user's account. Deleting the auth user
// cascades to profiles / reports / biomarker_entries (all reference
// auth.users ON DELETE CASCADE). Storage objects are removed explicitly
// since storage is not covered by the DB cascade.
//
// Deployed with verify_jwt = true, so Supabase validates the caller's JWT
// before invocation; we additionally resolve the user from the token to know
// whose data to delete. Uses the service-role key (injected at runtime).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const authHeader = req.headers.get('Authorization') ?? ''
    const token = authHeader.replace('Bearer ', '').trim()
    if (!token) return json({ error: 'Missing access token' }, 401)

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    )

    const { data: userData, error: userErr } = await admin.auth.getUser(token)
    if (userErr || !userData?.user) return json({ error: 'Invalid user' }, 401)
    const userId = userData.user.id

    for (const bucket of ['avatars', 'reports']) {
      const { data: files } = await admin.storage.from(bucket).list(userId)
      if (files && files.length > 0) {
        await admin.storage
          .from(bucket)
          .remove(files.map((f) => `${userId}/${f.name}`))
      }
    }

    const { error: delErr } = await admin.auth.admin.deleteUser(userId)
    if (delErr) return json({ error: delErr.message }, 500)

    return json({ success: true }, 200)
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})
