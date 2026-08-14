// Supabase configuration for CareQA
module.exports = {
  project: 'your-project-ref',
  schema: 'public',
  db: {
    url: process.env.DATABASE_URL,
    port: 5432,
    schema: 'public',
    extensions: ['uuid-ossp']
  },
  auth: {
    enable_signup: true,
    enable_email_confirmed: true,
    enable_email_change: true,
    enable_password_reset: true,
    enable_email_verification: true
  },
  storage: {
    file_size_limit: '5MB',
    allowed_mime_types: ['image/*', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
  },
  realtime: {
    enable: true,
    channels: ['public']
  }
};