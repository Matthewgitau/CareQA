class Endpoints {
  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String verify2FA = '/api/auth/verify-2fa';
  static const String resetPassword = '/api/auth/reset-password';
  static const String me = '/api/auth/me';

  // Shifts
  static const String shifts = '/api/shifts';
  static const String clientShifts = '/api/shifts/clients';
  static const String carerShifts = '/api/shifts/carer';
  static const String adminShifts = '/api/shifts/admin';
  static const String shiftById = '/api/shifts/';

  // Users
  static const String users = '/api/users';
  static const String userById = '/api/users/';
  static const String carers = '/api/users/carers';
  static const String serviceUsers = '/api/users/service-users';
  static const String clients = '/api/users/clients';

  // Invoices
  static const String invoices = '/api/invoices';
  static const String invoiceById = '/api/invoices/';
  static const String clientInvoices = '/api/invoices/client';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String notificationById = '/api/notifications/';
  static const String unreadNotifications = '/api/notifications/unread';

  // Visits
  static const String visits = '/api/visits';
  static const String visitById = '/api/visits/';
  static const String carerVisits = '/api/visits/carer';
  static const String checkIn = '/api/visits/check-in';
  static const String checkOut = '/api/visits/check-out';

  // Messages
  static const String messages = '/api/messages';
  static const String messageById = '/api/messages/';
  static const String inbox = '/api/messages/inbox';
  static const String sent = '/api/messages/sent';

  // Service Users
  static const String serviceUserById = '/api/service-users/';

  // Clients
  static const String clientById = '/api/clients/';

  // Carers
  static const String carerById = '/api/carers/';
}
</arg_value>
<task_progress>
- [x] Create shared packages (core, api_client, ui_kit)
- [ ] Build client app structure
- [ ] Build carer app structure  
- [ ] Build API gateway
- [ ] Build shift service
</task_progress>
</write_to_file></tool_call>