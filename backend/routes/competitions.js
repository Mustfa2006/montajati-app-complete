const express = require('express');
const router = express.Router();

const { supabase, supabaseAdmin } = require('../config/supabase');

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
      .select('id, name, description, product_name, prize, target, completed, is_active, starts_at, ends_at, created_at, updated_at')
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (error) throw error;

    // Filter by date range and map product_name -> product
    const now = new Date();
    const filtered = (data || []).filter((c) => {
      const s = c.starts_at ? new Date(c.starts_at) : null;
      const e = c.ends_at ? new Date(c.ends_at) : null;
      const afterStart = !s || s <= now;
      const beforeEnd = !e || e >= now;
      return afterStart && beforeEnd;
    });
    const mapped = filtered.map((c) => ({
      ...c,
      product: c.product_name,
    }));

    return res.json({ success: true, data: mapped });
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
      .select('id, name, description, product_name, prize, target, completed, is_active, starts_at, ends_at, created_at, updated_at')
      .order('created_at', { ascending: false });

    if (error) throw error;

    const mapped = (data || []).map((c) => ({
      ...c,
      product: c.product_name,
    }));

    return res.json({ success: true, data: mapped });
  } catch (e) {
    console.error('GET /competitions error:', e.message);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

// POST /api/competitions -> create (admin)
router.post('/', requireAdmin, async (req, res) => {
  try {
    const { name, description, product_name, prize, target, completed, is_active, starts_at, ends_at } = req.body || {};

    if (!name) return res.status(400).json({ success: false, message: 'name is required' });

    const payload = {
      name,
      description: description || '',
      product_name: product_name || '',
      prize: prize || '',
      target: Number.isFinite(target) ? target : parseInt(target || 0, 10),
      completed: Number.isFinite(completed) ? completed : parseInt(completed || 0, 10),
      is_active: typeof is_active === 'boolean' ? is_active : true,
      starts_at: starts_at || null,
      ends_at: ends_at || null,
    };

    const { data, error } = await supabaseAdmin
      .from('competitions')
      .insert(payload)
      .select('id, name, description, product_name, prize, target, completed, is_active, starts_at, ends_at, created_at, updated_at')
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
    const { name, description, product_name, prize, target, completed, is_active, starts_at, ends_at } = req.body || {};

    const payload = {};
    if (name !== undefined) payload.name = name;
    if (description !== undefined) payload.description = description;
    if (product_name !== undefined) payload.product_name = product_name;
    if (prize !== undefined) payload.prize = prize;
    if (target !== undefined) payload.target = Number.isFinite(target) ? target : parseInt(target || 0, 10);
    if (completed !== undefined) payload.completed = Number.isFinite(completed) ? completed : parseInt(completed || 0, 10);
    if (is_active !== undefined) payload.is_active = !!is_active;
    if (starts_at !== undefined) payload.starts_at = starts_at;
    if (ends_at !== undefined) payload.ends_at = ends_at;

    const { data, error } = await supabaseAdmin
      .from('competitions')
      .update(payload)
      .eq('id', id)
      .select('id, name, description, product_name, prize, target, completed, is_active, starts_at, ends_at, created_at, updated_at')
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

