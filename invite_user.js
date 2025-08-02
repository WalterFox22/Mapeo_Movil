const express = require('express');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const app = express();
app.use(express.json());

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY 
);

app.post('/invite', async (req, res) => {
  const { email, rol } = req.body;
  try {
    const { data, error } = await supabase.auth.admin.inviteUserByEmail(email, { data: { rol } });
    if (error) return res.status(400).json({ error: error.message });
    res.json({ user: data.user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = 5005;
app.listen(PORT, () => console.log('Servidor de invitaciones corriendo en puerto', PORT));
