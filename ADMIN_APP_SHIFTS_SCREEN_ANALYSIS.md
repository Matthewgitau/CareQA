# Admin-App Shifts Screen: How It Reads & Interacts with `public.shifts`

## Overview

This report provides an in-depth analysis of how the admin-app's shift screen (`admin-app/lib/ui/shift/shift_list_screen.dart`) reads from and interacts with the `public.shifts` table in Supabase. It covers the data flow, query patterns, role-based access control, and the underlying service layer.

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    admin-app (Flutter)                          │
│                                                                 │
│  ┌──────────────────────┐    ┌──────────────────────────────┐  │
│  │  shift_list_screen   │───▶│  shift_service.dart          │  │
│  │  (UI Layer)          │    │  (Service Layer)             │  │
│  └──────────────────────┘    └──────────────┬───────────────┘  │
│                                             │                  │
│                                    ┌────────▼────────┐         │
│                                    │  SupabaseClient │         │
│                                    └────────┬────────┘         │
└─────────────────────────────────────────────┼──────────────────┘
                                              │
                                    ┌─────────▼─────────┐
                                    │  public.shifts    │
                                    │  (PostgreSQL)     │
                                    └───────────────────┘
```

---

## 2. The `Shift` Model (Admin-App)

**File:** `admin-app/lib/services/shift_service.dart` (lines 4-91)

The admin-app defines its own local `Shift` model that maps directly to the `public.shifts` table columns:

| Dart Field | DB Column | Type | Notes |
|---|---|---|---|
| `id` | `id` | `String` | UUID primary key |
| `clientOrganisationId` | `client_organisation_id` | `String` | FK to `organisations` (care home) |
| `serviceUserId` | `service_user_id` | `String` | FK to `service_users` |
| `serviceUserName` | `service_users.name` | `String?` | **Joined** from related table |
| `carerId` | `carer_id` | `String?` | FK to `carers` (nullable - unassigned) |
| `carerName` | `carers.name` | `String?` | **Joined** from related table |
| `scheduledDate` | `scheduled_date` | `DateTime` | Date of the shift |
| `startTime` | `start_time` | `String` | HH:MM:SS format |
| `endTime` | `end_time` | `String` | HH:MM:SS format |
| `status` | `status` | `String` | scheduled/booked/confirmed/cancelled/completed |
| `location` | `location` | `String?` | Shift location |
| `staffRequired` | `staff_required` | `int?` | Number of staff needed |
| `staffType` | `staff_type` | `String?` | carer/senior_carer/team_leader |
| `notes` | `notes` | `String?` | Free-text notes |
| `organisationId` | `organisation_id` | `String?` | FK to `organisations` (agency) |
| `agencyClientId` | `agency_client_id` | `String?` | For agency billing |
| `agencyBillingRate` | `agency_billing_rate` | `double?` | Billing rate |
| `broadcastType` | `broadcast_type` | `String?` | single/multiple/all |

### Key Serialization Details:

**`fromJson()`** (lines 45-64):
- Extracts joined names from nested objects: `json['service_users']?['name']` and `json['carers']?['name']`
- Uses `_extractName()` helper (lines 66-71) to safely handle joined data
- Falls back to defaults for missing fields (e.g., `'08:00'` for start time)

**`toJson()`** (lines 73-90):
- Converts `scheduledDate` to `YYYY-MM-DD` format using `.split('T')[0]`
- Includes all new broadcast-related fields

---

## 3. The `ShiftService` Class

**File:** `admin-app/lib/services/shift_service.dart` (lines 140-353)

### 3.1 User Context Resolution

**Method:** `_getUserContext()` (lines 143-165)

This method queries the `profiles` table to determine the current user's role and organisation:

```dart
final response = await _client
    .from('profiles')
    .select('role, organisation_id, client_organisation_id')
    .eq('id', user.id)
    .maybeSingle();
```

**Returns:** A record with:
- `role` - `admin`, `client`, or `carer`
- `organisationId` - The agency's organisation ID (for admins)
- `clientOrganisationId` - The care home's organisation ID (for clients)

### 3.2 Role-Based Shift Fetching

**Method:** `getShiftsForDate(DateTime date)` (lines 167-211)

This is the **primary read method** for the shifts screen. It builds a Supabase query with role-based filtering:

```dart
var query = _client
    .from('shifts')
    .select('*, service_users(name), carers(name)')
    .eq('scheduled_date', date.toIso8601String().split('T').first);
```

**The `.select()` clause** requests:
- All columns from `shifts` (`*`)
- The `name` column from the related `service_users` table (via FK `service_user_id`)
- The `name` column from the related `carers` table (via FK `carer_id`)

**Role-based filtering:**

| Role | Filter Applied | SQL Equivalent |
|---|---|---|
| `admin` | `.eq('organisation_id', orgId)` | `WHERE organisation_id = '<agency_id>'` |
| `client` | `.eq('client_organisation_id', clientOrgId)` | `WHERE client_organisation_id = '<care_home_id>'` |
| `carer` | `.eq('carer_id', carerId)` | `WHERE carer_id = '<user_id>'` |
| other | Returns empty list | — |

**Ordering:** `.order('start_time', ascending: true)` - sorts by shift start time.

### 3.3 PSL-Based Shift Fetching

**Method:** `getShiftsFromPSL(DateTime date)` (lines 213-248)

This method enables admin users to see shifts from care homes that have the agency in their Preferred Supplier List:

**Step 1:** Query the PSL table to find care homes:
```dart
final pslResponse = await _client
    .from('client_organisation_psl')
    .select('client_org_id')
    .eq('organisation_id', orgId)
    .eq('status', 'active');
```

**Step 2:** Extract care home IDs:
```dart
final clientOrgIds = (pslResponse as List)
    .map((e) => e['client_org_id'] as String)
    .toList();
```

**Step 3:** Fetch shifts for all those care homes:
```dart
final response = await _client
    .from('shifts')
    .select('*, service_users(name), carers(name)')
    .eq('scheduled_date', date.toIso8601String().split('T').first)
    .inFilter('client_organisation_id', clientOrgIds)
    .order('start_time', ascending: true);
```

**SQL Equivalent:**
```sql
SELECT shifts.*, service_users.name, carers.name
FROM shifts
LEFT JOIN service_users ON service_users.id = shifts.service_user_id
LEFT JOIN carers ON carers.id = shifts.carer_id
WHERE scheduled_date = '2026-08-10'
  AND client_organisation_id IN ('<care_home_1>', '<care_home_2>', ...)
ORDER BY start_time ASC;
```

---

## 4. The Shift List Screen (UI Layer)

**File:** `admin-app/lib/ui/shift/shift_list_screen.dart`

### 4.1 State Management

```dart
int _viewMode = 0;          // 0 = Client Shifts, 1 = Route Schedule
DateTime _selectedDate = DateTime.now();
List<Shift> _shifts = [];
List<RouteSchedule> _routes = [];
bool _loading = true;
String? _error;
String? _userRole;
String? _broadcastFilter;
```

### 4.2 Data Loading Flow

**Method:** `_load()` (lines 51-120)

```
_load() called
    │
    ├── setState(_loading = true)
    │
    ├── _getUserRole() → queries profiles table
    │
    ├── if (_viewMode == 0)  // Client Shifts
    │   │
    │   ├── if (_userRole == 'admin')
    │   │   ├── getShiftsForDate() → direct shifts (organisation_id = agency)
    │   │   ├── getShiftsFromPSL() → PSL shifts (from care homes in PSL)
    │   │   ├── Combine & deduplicate by shift ID
    │   │   ├── Sort by start time
    │   │   └── Apply broadcast filter (if set)
    │   │
    │   └── else  // client or carer
    │       ├── getShiftsForDate() → standard role-based filtering
    │       └── Apply broadcast filter (if set)
    │
    └── else  // Route Schedule
        └── getRoutesForDate() → queries routes table
```

### 4.3 Combining Direct + PSL Shifts (Admin)

```dart
final shiftMap = <String, Shift>{};
for (final shift in directShifts) {
  shiftMap[shift.id] = shift;
}
for (final shift in pslShifts) {
  if (!shiftMap.containsKey(shift.id)) {
    shiftMap[shift.id] = shift;
  }
}
```

This uses a `Map<String, Shift>` keyed by shift ID to **deduplicate** shifts that might appear in both result sets.

### 4.4 Broadcast Type Filter

```dart
if (_broadcastFilter != null) {
  allShifts = allShifts.where((s) => s.broadcastType == _broadcastFilter).toList();
}
```

The filter dropdown (visible only to admins) offers:
- **All Broadcasts** (null)
- **Single Agency** (`'single'`)
- **Multiple Agencies** (`'multiple'`)
- **All Agencies** (`'all'`)

### 4.5 Shift Card Rendering

**Method:** `_buildShiftCard()` (lines 200-260)

Each shift is rendered as a `Card` with a `ListTile` showing:
- **Title:** `HH:MM - HH:MM` (formatted start/end times)
- **Subtitle:** Service user name, location, staff type/required, carer name, broadcast type
- **Trailing:** Status chip + visibility badge (for admins)

**Visibility Badge** (`_buildBroadcastBadge()`):
- **Blue "Direct"** - `organisationId != null` (shift assigned directly to this agency)
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'scheduled' 
    CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Added Columns (from subsequent migrations)

**From 028_add_organisation_id.sql:**
```sql
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS organisation_id UUID;
ALTER TABLE shifts ADD CONSTRAINT fk_shifts_organisation 
  FOREIGN KEY (organisation_id) REFERENCES organisations(id) ON DELETE SET NULL;
CREATE INDEX idx_shifts_organisation_id ON shifts(organisation_id);
```

**From 106_profit_tracking_consolidated.sql:**
```sql
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS agency_client_id UUID;
ALTER TABLE shifts ADD COLUMN IF NOT EXISTS agency_billing_rate DECIMAL(10,2);
```

**From 117_create_shift_broadcasts.sql:**
```sql
ALTER TABLE public.shifts 
  ADD COLUMN IF NOT EXISTS broadcast_type TEXT DEFAULT 'single'
    CHECK (broadcast_type IN ('single', 'multiple', 'all'));
```

#### Complete Current Schema
```sql
CREATE TABLE shifts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
  carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
  scheduled_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'scheduled' 
    CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  organisation_id UUID REFERENCES organisations(id) ON DELETE SET NULL,
  agency_client_id UUID,
  agency_billing_rate DECIMAL(10,2),
  broadcast_type TEXT DEFAULT 'single'
    CHECK (broadcast_type IN ('single', 'multiple', 'all')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Indexes
```sql
CREATE INDEX idx_shifts_carer_date ON shifts(carer_id, scheduled_date);
CREATE INDEX idx_shifts_organisation_id ON shifts(organisation_id);
```

### Triggers
```sql
CREATE TRIGGER update_shifts_updated_at 
  BEFORE UPDATE ON shifts 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 4. Table Relationships

### Foreign Key Relationships

```
shifts.service_user_id → service_users(id) [CASCADE DELETE]
shifts.carer_id → carers(id) [SET NULL]
shifts.organisation_id → organisations(id) [SET NULL]
shifts.agency_client_id → [No FK constraint found]
```

### Related Tables

#### service_users
```sql
CREATE TABLE service_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  address TEXT,
  notes TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relation TEXT,
  care_plan JSONB DEFAULT '{
    "medications": [],
    "allergies": [],
    "mobility": "",
    "dietary": [],
    "personal_care": []
  }',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### carers
```sql
CREATE TABLE carers (
  id UUID PRIMARY KEY REFERENCES profiles(id),
  employee_number TEXT UNIQUE,
  dbs_number TEXT,
  dbs_expiry_date DATE,
  dbs_certificate_url TEXT,
  id_document_url TEXT,
  id_expiry_date DATE,
  right_to_work_expiry DATE,
  training_records JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### visits (Child Table)
```sql
CREATE TABLE visits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shift_id UUID REFERENCES shifts(id) ON DELETE CASCADE,
  carer_id UUID REFERENCES carers(id) ON DELETE SET NULL,
  check_in_time TIMESTAMP WITH TIME ZONE,
  check_out_time TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER,
  notes TEXT,
  flagged BOOLEAN DEFAULT FALSE,
  flag_reason TEXT,
  compliance_percentage NUMERIC(5,2),
  structured_notes JSONB DEFAULT '{
    "mood_score": null,
    "medication_given": false,
    "family_present": false,
    "incident_occurred": false,
    "incident_type": null
  }',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Important:** Visits are CASCADE deleted when a shift is deleted.

---

## 5. Security & Access Control

### Row Level Security (RLS) Policies

#### Policy 1: Carers can view assigned shifts
```sql
CREATE POLICY "Carers can view assigned shifts" ON shifts
  FOR SELECT
  USING (
    carer_id = auth.uid() OR 
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );
```

**Impact:** 
- Carers can only see shifts assigned to them
- Admins can see all shifts
- This policy was updated in migration 028 to include organisation filtering

#### Policy 2: Admins can manage all shifts
```sql
CREATE POLICY "Admins can manage all shifts" ON shifts
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

**Impact:**
- Admins have full CRUD access to all shifts
- Carers have no write access through this policy

#### Updated Policy (Migration 028)
```sql
CREATE POLICY "Carers can view assigned shifts" ON shifts
  FOR SELECT
  USING (
    carer_id = auth.uid() OR 
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin') OR
    organisation_id IS NULL
  );
```

**Note:** The `organisation_id IS NULL` clause was added as a temporary measure during multi-tenancy migration.

### Multi-Tenancy Isolation

The application uses `client_organisation_id` for filtering (not `organisation_id`):

```dart
.eq('client_organisation_id', clientOrgId)
```

**Critical Finding:** The database schema has `organisation_id` but the application queries use `client_organisation_id`. This suggests:
1. The column name in the database might be different from what the app expects
2. OR there's a view or column alias being used
3. OR the schema and application are out of sync

**Recommendation:** Verify the actual column name in the shifts table matches what the application expects.

---

## 6. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ UI Layer: ShiftListScreen                                   │
│ - User selects date or switches view mode                   │
│ - Calls _load() method                                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Service Layer: ShiftService                                 │
│ - _getClientOrgId() resolves organisation                   │
│ - Constructs Supabase query                                 │
│ - Calls getShiftsForDate() or getRoutesForDate()            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Supabase Client                                             │
│ - FROM: public.shifts                                       │
│ - SELECT: *, service_users(name), carers(name)              │
│ - FILTER: client_organisation_id = ?, scheduled_date = ?   │
│ - ORDER: start_time ASC                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ PostgreSQL Database                                         │
│ - Executes query with RLS policies                          │
│ - Performs JOINs on service_users and carers                │
│ - Returns filtered results                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Response Processing                                         │
│ - JSON deserialized to Shift objects                        │
│ - Joined names extracted via _extractName()                 │
│ - List returned to UI                                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ UI Rendering                                                │
│ - _buildShiftList() creates ListView                        │
│ - _buildShiftCard() renders each shift                      │
│ - Status color coding applied                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Key Findings & Issues

### Finding 1: Column Name Mismatch
**Issue:** The application uses `client_organisation_id` but the database schema shows `organisation_id`.

**Evidence:**
- Service code: `.eq('client_organisation_id', clientOrgId)`
- Database schema: `organisation_id UUID`

**Impact:** Queries may fail or return no results if the column doesn't exist.

**Recommendation:** 
- Verify actual column name in database
- Update either the schema or application code to match
- Consider using a database view for compatibility

### Finding 2: Missing Fields in Model
**Issue:** The Shift model includes fields not in the original schema.

**Evidence:**
- Model has: `clientOrganisationId`, `location`, `staffRequired`, `staffType`, `notes`
- Original schema only has: core fields without these extensions

**Impact:** These fields may be NULL or cause errors if not properly migrated.

**Recommendation:** Ensure all migrations have been applied to the database.

### Finding 3: Broadcast Type Not Utilized
**Issue:** The `broadcast_type` column exists but is not used in the shift list screen.

**Evidence:**
- Migration 117 adds `broadcast_type` column
- Shift model doesn't include this field
- UI doesn't display or filter by broadcast type

**Impact:** Multi-agency broadcasting feature is partially implemented but not exposed in admin UI.

**Recommendation:** Consider adding broadcast type filtering or display in admin interface.

### Finding 4: No Pagination
**Issue:** Queries fetch all records without pagination.

**Evidence:**
- `getShiftsForDate()` fetches all shifts for a day
- `getShiftsForMonth()` fetches all shifts for a month
- No LIMIT or OFFSET clauses

**Impact:** Performance degradation with large datasets (e.g., 100+ shifts in a month).

**Recommendation:** Implement pagination or date-range limiting for month views.

### Finding 5: Organisation Resolution Complexity
**Issue:** Three-tier fallback for organisation ID adds complexity.

**Evidence:**
```dart
// 1. userMetadata
// 2. profiles.client_organisation_id
// 3. profiles.organisation_id
```

**Impact:** 
- Potential for inconsistent organisation resolution
- Admin users may get wrong organisation context
- Hard to debug which path is taken

**Recommendation:** Standardize organisation storage and add logging for debugging.

---

## 8. Performance Considerations

### Indexes Present
```sql
idx_shifts_carer_date ON shifts(carer_id, scheduled_date)
idx_shifts_organisation_id ON shifts(organisation_id)
```

### Query Performance
- **Date filtering** on `scheduled_date` is efficient (DATE type)
- **Organisation filtering** uses index on `organisation_id`
- **Carer filtering** uses composite index `(carer_id, scheduled_date)`
- **Ordering** on `start_time` is efficient (TIME type)

### Potential Bottlenecks
1. **JOIN operations** on every query (service_users, carers)
2. **No pagination** for month views
3. **Multiple date range queries** could be heavy

### Recommendations
1. Add covering indexes for common query patterns
2. Implement pagination for month views
3. Consider caching frequent queries (e.g., today's shifts)

---

## 9. Data Integrity & Constraints

### Database Constraints
```sql
-- Primary Key
id UUID PRIMARY KEY

-- Foreign Keys
service_user_id → service_users(id) ON DELETE CASCADE
carer_id → carers(id) ON DELETE SET NULL
organisation_id → organisations(id) ON DELETE SET NULL

-- Check Constraints
status CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled'))
broadcast_type CHECK (broadcast_type IN ('single', 'multiple', 'all'))
```

### Application-Level Validation
- **None detected** - The application relies on database constraints
- No input validation before queries
- No business rule enforcement in service layer

### Recommendations
1. Add input validation in service layer
2. Implement business rule checks (e.g., end_time > start_time)
3. Add audit logging for shift modifications

---

## 10. Summary of Database Interactions

### Read Operations
| Method | Table | Joins | Filters | Purpose |
|--------|-------|-------|---------|---------|
| `getShiftsForDate()` | shifts | service_users, carers | org_id, date | Daily shift list |
| `getShiftsForMonth()` | shifts | none | org_id, date range | Monthly overview |

### Write Operations
| Method | Operation | Updated Fields | Conditions |
|--------|-----------|----------------|------------|
| `updateShift()` | UPDATE | All mutable fields | shift.id |
| `assignCarerToShift()` | UPDATE | carer_id, status | shift.id |
| `unassignCarerFromShift()` | UPDATE | carer_id, status | shift.id |

### No Delete Operations
The service layer does not implement shift deletion. This is likely handled elsewhere or not exposed in the admin UI.

---

## 11. Recommendations

### Critical (Fix Immediately)
1. **Resolve column name mismatch:** Verify `client_organisation_id` vs `organisation_id`
2. **Apply all migrations:** Ensure database schema matches application expectations
3. **Add error handling:** Implement proper error messages for database constraint violations

### High Priority
1. **Implement pagination:** For month views to prevent performance issues
2. **Add input validation:** Validate dates, times, and status values before queries
3. **Standardise organisation resolution:** Choose one method and document it

### Medium Priority
1. **Expose broadcast_type:** Add filtering/display for multi-agency shifts
2. **Add caching:** Cache frequently accessed shift data
3. **Implement audit logging:** Track shift modifications for compliance

### Low Priority
1. **Add query logging:** For debugging and performance monitoring
2. **Create database views:** Simplify complex queries
3. **Add database functions:** Encapsulate common query patterns

---

## 12. Conclusion

The admin-app's shifts screen interacts with the `public.shifts` table through a well-structured service layer that:

1. **Reads data efficiently** using filtered, indexed queries with JOINs for related data
2. **Enforces multi-tenancy** through organisation-based filtering
3. **Provides CRUD operations** for shift management (except delete)
4. **Respects RLS policies** for security and data isolation

However, there are **critical schema mismatches** between the application code and database that need immediate attention. The application expects `client_organisation_id` but the database has `organisation_id`, which will cause query failures.

The implementation is generally solid but would benefit from pagination, input validation, and better error handling for production use.

---

## Appendix A: Complete Query Examples

### Query 1: Get Shifts for Date
```sql
SELECT 
  shifts.*,
  service_users.name AS service_users_name,
  carers.name AS carers_name
FROM public.shifts
LEFT JOIN public.service_users ON shifts.service_user_id = service_users.id
LEFT JOIN public.carers ON shifts.carer_id = carers.id
WHERE 
  shifts.client_organisation_id = '<org_id>'
  AND shifts.scheduled_date = '2026-09-08'
ORDER BY shifts.start_time ASC;
```

### Query 2: Get Shifts for Month
```sql
SELECT *
FROM public.shifts
WHERE 
  client_organisation_id = '<org_id>'
  AND scheduled_date >= '2026-09-01'
  AND scheduled_date <= '2026-09-30'
ORDER BY scheduled_date ASC, start_time ASC;
```

### Query 3: Update Shift
```sql
UPDATE public.shifts
SET 
  start_time = '09:00',
  end_time = '17:00',
  status = 'confirmed',
  location = 'Client Home',
  updated_at = NOW()
WHERE id = '<shift_id>';
```

---

## Appendix B: Migration History

| Migration | Changes to shifts Table |
|-----------|------------------------|
| 001_initial_schema.sql | Created table with core columns |
| 028_add_organisation_id.sql | Added `organisation_id` column and FK |
| 106_profit_tracking_consolidated.sql | Added `agency_client_id`, `agency_billing_rate` |
| 117_create_shift_broadcasts.sql | Added `broadcast_type` column |

---

*Report generated: 2026-09-08*
*Files analyzed: shift_list_screen.dart, shift_service.dart, migration files*
*Database: Supabase/PostgreSQL*