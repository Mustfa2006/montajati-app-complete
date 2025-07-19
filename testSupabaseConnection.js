const supabase = require('./supabaseClient');

async function testConnection() {
  try {
    const { data, error } = await supabase.from('test_table').select('*');

    if (error) {
      console.error('Error fetching data:', error.message);
    } else {
      console.log('Data fetched successfully:', data);
    }
  } catch (err) {
    console.error('Unexpected error:', err.message);
  }
}

testConnection();
