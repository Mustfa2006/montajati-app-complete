const supabase = require('./supabaseClient');

async function checkTables() {
  try {
    console.log('Checking user_fcm_tokens table...');
    const { data: fcmTokens, error: fcmError } = await supabase
      .from('user_fcm_tokens')
      .select('*')
      .limit(5);

    if (fcmError) {
      console.error('Error fetching user_fcm_tokens:', fcmError.message);
    } else {
      console.log('user_fcm_tokens data:', fcmTokens);
    }

    console.log('Checking notification_queue table...');
    const { data: notifications, error: notificationError } = await supabase
      .from('notification_queue')
      .select('*')
      .limit(5);

    if (notificationError) {
      console.error('Error fetching notification_queue:', notificationError.message);
    } else {
      console.log('notification_queue data:', notifications);
    }
  } catch (err) {
    console.error('Unexpected error:', err.message);
  }
}

checkTables();
