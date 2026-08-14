# Spot Check Form — Dropdown Issues Diagnostic Report

## Issue Summary
Three dropdowns on the Spot Check form are not displaying data:
1. **Service User** dropdown (Basic Information section)
2. **Carer** dropdown (Basic Information section)
3. **Assign To** dropdown (Action Plan section)

---

## Issue 1: Service User Dropdown

### Location
`admin-app/lib/ui/audits/spot_check_screen.dart`, lines ~252-257

### Code
```dart
DropdownButtonFormField<String>(
  decoration: const InputDecoration(labelText: 'Service User *', border: OutlineInputBorder()),
  items: _users.map((u) => DropdownMenuItem(
    value: u['id'] as String,
    child: Text(u['name'] as String)
  )).toList(),
  onChanged: (v) {
    final u = _users.firstWhere((x) => x['id'] == v);
    setState(() { _serviceUserId = v; _serviceUserName = u['name']; });
  },
  validator: (v) => v == null ? 'Required' : null,
),
```

### Data Source
```dart
// spot_check_service.dart, line 44-46
Future<List<Map<String, dynamic>>> getServiceUsers() async {
  final data = await _client.from('service_users').select('id, name').order('name');
  return (data as List).cast<Map<String, dynamic>>();
}
```

### Potential Causes
1. **RLS Policy on `service_users` table** — If there's a Row-Level Security policy that restricts which rows the authenticated user can see, the query may return zero results.
   - Check in Supabase SQL Editor: `SELECT * FROM pg_policies WHERE tablename = 'service_users';`
   - If a restrictive policy exists, it may be filtering out all records.
2. **Table doesn't exist or has different column names** — Verify the table exists and has `id` and `name` columns.
   - Run: `SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'service_users';`
3. **Database connection issue** — The Supabase client may not be properly connected or the user may not be authenticated.

---

## Issue 2: Carer Dropdown

### Location
`admin-app/lib/ui/audits/spot_check_screen.dart`, lines ~258-265

### Code
```dart
DropdownButtonFormField<String>(
  decoration: const InputDecoration(labelText: 'Carer *', border: OutlineInputBorder()),
  items: _carers.map((c) => DropdownMenuItem(
    value: c['id'] as String,
    child: Text(c['name'] as String)
  )).toList(),
  onChanged: (v) {
    final c = _carers.firstWhere((x) => x['id'] == v);
    setState(() { _carerId = v; _carerName = c['name']; _carerRole = c['role']; });
  },
  validator: (v) => v == null ? 'Required' : null,
),
```

### Data Source
```dart
// spot_check_service.dart, line 49-51
Future<List<Map<String, dynamic>>> getCarers() async {
  final data = await _client.from('carers').select('id, name, role').order('name');
  return (data as List).cast<Map<String, dynamic>>();
}
```

### Potential Causes
1. **The `carers` table may not exist** — Check if there's a `carers` table in the database.
   - Run: `SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'carers');`
2. **Different column naming** — The table might use different column names like `full_name` instead of `name`, or `carer_id` instead of `id`.
   - Run: `SELECT column_name FROM information_schema.columns WHERE table_name = 'carers';`
3. **RLS Policy on `carers` table** — Similar to Issue 1, RLS may be blocking the query.
   - Check: `SELECT * FROM pg_policies WHERE tablename = 'carers';`
4. **Empty table** — There may simply be no records in the carers table.

---

## Issue 3: "Assign To" Dropdown (Action Plan)

### Location
`admin-app/lib/ui/audits/spot_check_screen.dart`, lines ~401-405

### Code
```dart
DropdownButtonFormField<String>(
  value: _actionAssignedTo,
  decoration: const InputDecoration(labelText: 'Assign To *', border: OutlineInputBorder()),
  items: _carers.map((c) => DropdownMenuItem(
    value: c['id'] as String,
    child: Text(c['name'] as String)
  )).toList(),
  onChanged: (v) => setState(() => _actionAssignedTo = v),
  validator: (v) => v == null ? 'Required' : null,
),
```

### Data Source
Same as Issue 2 — uses `_carers` list loaded from the `carers` table.

### Potential Cause
Since this uses the same `_carers` list as Issue 2, if the carer dropdown is empty, this will also be empty. However, **if the carer dropdown IS populated** but this one isn't, it could be because:
1. **Conditional rendering** — The action plan section only shows when `_reqAction()` returns `true` (line 391: `if (_reqAction()) ...`). This requires either `_hasFlags()` (any critical safety flag checked) or `_pct() < 70` (score below 70%). If neither condition is met, the entire action plan section—including this dropdown—is hidden.
2. Same root causes as Issue 2 (table doesn't exist, wrong columns, RLS, empty table).

---

## Diagnostic SQL Commands to Run in Supabase SQL Editor

Run these to identify which tables exist and what their schemas look like:

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('service_users', 'carers', 'profiles');

-- Check columns in service_users
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'service_users' ORDER BY ordinal_position;

-- Check columns in carers
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'carers' ORDER BY ordinal_position;

-- Check columns in profiles
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'profiles' ORDER BY ordinal_position;

-- Check RLS policies on carers
SELECT * FROM pg_policies WHERE tablename = 'carers';

-- Check RLS policies on service_users
SELECT * FROM pg_policies WHERE tablename = 'service_users';

-- Check RLS policies on profiles
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Count records in each table
SELECT 'service_users' as table_name, COUNT(*) FROM service_users
UNION ALL
SELECT 'carers', COUNT(*) FROM carers
UNION ALL
SELECT 'profiles', COUNT(*) FROM profiles;
```

---

## Recommended Fixes (for the developer)

### If `carers` table doesn't exist:
Option A: Create a `carers` table similar to other apps in the project.
Option B: Change the dropdowns to query from `profiles` using a service role client (bypasses RLS) instead of the anon client.

### If `carers` table exists but has different column names:
Update the service method to match the actual column names:
```dart
// If the table uses 'full_name' instead of 'name':
Future<List<Map<String, dynamic>>> getCarers() async {
  final data = await _client.from('carers').select('id, full_name, role').order('full_name');
  return (data as List).cast<Map<String, dynamic>>();
}
// And update the UI to use u['full_name'] instead of u['name']
```

### If RLS is blocking `profiles` for "Assign To":
Create a server-side RPC function that returns staff data using `SECURITY DEFINER`:
```sql
CREATE OR REPLACE FUNCTION get_staff_for_assignment()
RETURNS TABLE(id UUID, full_name TEXT, email TEXT)
SECURITY DEFINER
AS $$
  SELECT id, full_name, email FROM profiles ORDER BY full_name;
$$ LANGUAGE sql;
```
Then call it from the service:
```dart
Future<List<Map<String, dynamic>>> getStaff() async {
  final data = await _client.rpc('get_staff_for_assignment');
  return (data as List).cast<Map<String, dynamic>>();
}