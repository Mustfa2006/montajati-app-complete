const express = require('express');
const router = express.Router();

const { supabase, supabaseAdmin } = require('../config/supabase');

// Helpers to compute delivered count per competition
function isDeliveredStatus(s) {
  const t = (s || '').toString().toLowerCase();
  return t.includes('delivered') || t.includes('تم التسليم');
}

async function computeDeliveredCount({ productName, startsAt, endsAt }) {
  try {
    // Build inclusive window: from start 00:00 up to end-of-next-day 23:59:59.999
    const start = startsAt ? new Date(startsAt) : null;
    const end = endsAt ? new Date(endsAt) : null;

    let windowStart = start ? new Date(start.getFullYear(), start.getMonth(), start.getDate(), 0, 0, 0, 0) : new Date('2000-01-01T00:00:00.000Z');
    let windowEnd = end
      ? new Date(end.getFullYear(), end.getMonth(), end.getDate(), 23, 59, 59, 999)
      : new Date('2100-01-01T23:59:59.999Z');
    // include next day entirely as requested
    windowEnd = new Date(windowEnd.getTime() + 24 * 60 * 60 * 1000);

    // 1) Fetch status history within window, then filter to delivered
    const { data: hist, error: histErr } = await supabaseAdmin
      .from('order_status_history')
      .select('order_id, new_status, created_at')
      .gte('created_at', windowStart.toISOString())
      .lte('created_at', windowEnd.toISOString());

    if (histErr) throw histErr;

    const deliveredOrderIds = new Set((hist || [])
      .filter((h) => isDeliveredStatus(h.new_status))
      .map((h) => h.order_id));

    if (deliveredOrderIds.size === 0) return 0;

    // 2) Filter by product via order_items
    const ids = Array.from(deliveredOrderIds);
    // Chunk to avoid URL length issues
    const chunkSize = 500;
    const found = new Set();
    for (let i = 0; i < ids.length; i += chunkSize) {
      const slice = ids.slice(i, i + chunkSize);
      const { data: items, error: itemsErr } = await supabaseAdmin
        .from('order_items')
        .select('order_id, product_name')
        .in('order_id', slice)
        .eq('product_name', productName);
      if (itemsErr) throw itemsErr;
      (items || []).forEach((it) => found.add(it.order_id));
    }

    return found.size;
  } catch (e) {
    console.error('computeDeliveredCount error:', e.message);
    return 0;
  }
}

// Count delivered orders for a product within [startDate..endDate]
async function countCompetitionOrders(productId, startDate, endDate) {
  try {
    if (!productId) return 0;
    const startIso = startDate ? new Date(startDate).toISOString() : null;
    const endIso = endDate ? new Date(endDate).toISOString() : null;

    let q = supabaseAdmin
      .from('order_status_history')
      .select('order_id, new_status, created_at');
    if (startIso) q = q.gte('created_at', startIso);
    if (endIso) q = q.lte('created_at', endIso);
    // Arabic delivered phrase match (covers "تم التسليم" and variants containing it)
    q = q.ilike('new_status', '%تم التسليم%');

    const { data: hist, error: histErr } = await q;
    if (histErr) throw histErr;

    const deliveredIds = Array.from(new Set((hist || []).map((h) => h.order_id)));
    if (deliveredIds.length === 0) return 0;

    const chunk = 500;
    const matched = new Set();
    for (let i = 0; i < deliveredIds.length; i += chunk) {
      const slice = deliveredIds.slice(i, i + chunk);
      const { data: items, error: itemsErr } = await supabaseAdmin
        .from('order_items')
        .select('order_id')
        .in('order_id', slice)
        .eq('product_id', productId);
      if (itemsErr) throw itemsErr;
      (items || []).forEach((it) => matched.add(it.order_id));
    }

    return matched.size;
  } catch (e) {
    console.error('countCompetitionOrders error:', e.message);
    return 0;
  }
}

// Helpers
function getToken(req) {
  const h = req.headers['authorization'] || '';
  if (!h) return null;
  const parts = h.split(' ');
  if (parts.length === 2 && /^bearer$/i.test(parts[0])) return parts[1];
  return h; // fallback
}

function getUserIdFromLocalToken(token) {
  // Our mobile app uses a local token format: token_<userId>_<ts>
  if (!token || typeof token !== 'string') return null;
  if (!token.startsWith('token_')) return null;
  const parts = token.split('_');
  if (parts.length < 3) return null;
  return parts[1];
}

async function requireAdmin(req, res, next) {
  try {
    const token = getToken(req);
    const userId = getUserIdFromLocalToken(token);
    if (!userId) return res.status(401).json({ success: false, message: 'Unauthorized' });

    const { data, error } = await supabaseAdmin
      .from('users')
      .select('id, is_admin')
      .eq('id', userId)
      .maybeSingle();

    if (error) throw error;
    if (!data || !data.is_admin) {
      return res.status(403).json({ success: false, message: 'Forbidden' });
    }

    req.adminUserId = userId;
    next();
  } catch (e) {
    console.error('requireAdmin error:', e.message);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
}

// GET /api/competitions/public -> active competitions for users
router.get('/public', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('competitions')
      .select('id, name, product_name, prize, target, completed, is_active, starts_at, ends_at, created_at, updated_at')
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (error) throw error;

    // Filter by date range and map product_name -> product
    const now = new Date();
    const filtered = (data || []).filter((c) => {
      const s = c.starts_at ? new Date(c.starts_at) : null;
      let e = c.ends_at ? new Date(c.ends_at) : null;
      // إذا لم يتم تحديد وقت النهاية (00:00:00.000)، اعتبر نهاية اليوم كاملة
      if (e && e.getHours() === 0 && e.getMinutes() === 0 && e.getSeconds() === 0 && e.getMilliseconds() === 0) {
        e = new Date(e.getTime());
        e.setHours(23, 59, 59, 999);
      }
      const afterStart = !s || s <= now;
      const beforeEnd = !e || e >= now;
      return afterStart && beforeEnd;
    });

    // enrich with computed "completed" based on delivered orders for the product within [start .. end]
    const enriched = await Promise.all(
      filtered.map(async (c) => {
        // resolve product id by name (fallback if competitions lack product_id)
        let productId = null;
        try {
          const { data: prodRows } = await supabaseAdmin
            .from('products')
            .select('id')
            .eq('name', c.product_name)
            .limit(1);
          if (Array.isArray(prodRows) && prodRows.length > 0) productId = prodRows[0].id;
        } catch (_) { }

        const s = c.starts_at ? new Date(c.starts_at).toISOString() : null;
        const e = c.ends_at ? new Date(c.ends_at).toISOString() : null;
        const completed = productId ? await countCompetitionOrders(productId, s, e) : 0;
        return { ...c, product: c.product_name, completed };
      })
    );

    return res.json({ success: true, data: enriched });
  } catch (e) {
    console.error('GET /public error:', e.message);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// GET /api/competitions -> admin list (all)
router.get('/', requireAdmin, async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('competitions')
      .select('id, name, product_name, prize, target, completed, is_active, starts_at, ends_at, created_at, updated_at')
      .order('created_at', { ascending: false });

    if (error) throw error;

    const enriched = await Promise.all(
      (data || []).map(async (c) => {
        let productId = null;
        try {
          const { data: prodRows } = await supabaseAdmin
            .from('products')
            .select('id')
            .eq('name', c.product_name)
            .limit(1);
          if (Array.isArray(prodRows) && prodRows.length > 0) productId = prodRows[0].id;
        } catch (_) { }
        const s = c.starts_at ? new Date(c.starts_at).toISOString() : null;
        const e = c.ends_at ? new Date(c.ends_at).toISOString() : null;
        const completed = productId ? await countCompetitionOrders(productId, s, e) : 0;
        return { ...c, product: c.product_name, completed };
      })
    );

    return res.json({ success: true, data: enriched });
  } catch (e) {
    console.error('GET /competitions error:', e.message);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/competitions -> create (admin)
router.post('/', requireAdmin, async (req, res) => {
  try {
    const { name, description, product_name, prize, target, is_active, starts_at, ends_at } = req.body || {};

    if (!name) return res.status(400).json({ success: false, message: 'name is required' });

    const payload = {
      name,
      description: description || '',
      product_name: product_name || '',
      prize: prize || '',
      target: Number.isFinite(target) ? target : parseInt(target || 0, 10),
      is_active: typeof is_active === 'boolean' ? is_active : true,
      starts_at: starts_at || null,
      ends_at: ends_at || null,
    };

    const { data, error } = await supabaseAdmin
      .from('competitions')
      .insert(payload)
      .select('id, name, product_name, prize, target, completed, is_active, starts_at, ends_at, created_at, updated_at')
      .single();

    if (error) throw error;

    const mapped = { ...data, product: data.product_name };
    return res.status(201).json({ success: true, data: mapped });
  } catch (e) {
    console.error('POST /competitions error:', e.message);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// PATCH /api/competitions/:id -> update (admin)
router.patch('/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, product_name, prize, target, is_active, starts_at, ends_at } = req.body || {};

    const payload = {};
    if (name !== undefined) payload.name = name;
    if (description !== undefined) payload.description = description;
    if (product_name !== undefined) payload.product_name = product_name;
    if (prize !== undefined) payload.prize = prize;
    if (target !== undefined) payload.target = Number.isFinite(target) ? target : parseInt(target || 0, 10);
    if (is_active !== undefined) payload.is_active = !!is_active;
    if (starts_at !== undefined) payload.starts_at = starts_at;
    if (ends_at !== undefined) payload.ends_at = ends_at;

    const { data, error } = await supabaseAdmin
      .from('competitions')
      .update(payload)
      .eq('id', id)
      .select('id, name, product_name, prize, target, completed, is_active, starts_at, ends_at, created_at, updated_at')
      .single();

    if (error) throw error;

    const mapped = { ...data, product: data.product_name };
    return res.json({ success: true, data: mapped });
  } catch (e) {
    console.error('PATCH /competitions/:id error:', e.message);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// DELETE /api/competitions/:id -> delete (admin)
router.delete('/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { error } = await supabaseAdmin
      .from('competitions')
      .delete()
      .eq('id', id);

    if (error) throw error;

    return res.json({ success: true });
  } catch (e) {
    console.error('DELETE /competitions/:id error:', e.message);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;

