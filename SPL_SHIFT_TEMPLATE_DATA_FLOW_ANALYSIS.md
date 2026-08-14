# SPL Service, Shift Template & "Shift Type" Dropdown — Data Flow Analysis

## 1. SPL Service (`spl_service.dart`)

**File:** `client-app/lib/services/spl_service.dart`

### What is SPL?
**SPL = Service Provider List** — a list of agencies a care home (client organisation) can use to book shifts.

---

### 1.1 The Table it Reads/Writes To

| Item | Value |
|---|---|
| **Table name** | `client_organisation_spl` |
| **Schema** | `public` (default Supabase schema) |
| **Purpose** | Junction table linking a client organisation to a service provider (agency) |

### 1.2 All Methods & Their Database Operations

---

#### Method: `getServiceProviders(String clientOrgId)`
**Type:** READ (SELECT)

```dart
final response = await _client
    .from('client_organisation_spl')
    .select('''
      id,
      contract_rate,
      is_preferred,
      status,
      organisations:service_provider_id (
        id,
        name,
        contact_email,
        contact_phone
      )
    ''')
    .eq('client_org_id', clientOrgId)
    .eq('status', 'active');
```

**What it does:**
- Queries the `client_organisation_spl` table
- Filters by `client_org_id = <clientOrgId>` AND `status = 'active'`
- **Joins** the `organisations` table via the `service_provider_id` foreign key
- The join is aliased as `organisations` and returns `id, name, contact_email, contact_phone` from the agency's organisation record

**SQL Equivalent:**
```sql
SELECT 
  spl.id,
  spl.contract_rate,
  spl.is_preferred,
  spl.status,
  org.id,
  org.name,
  org.contact_email,
  org.contact_phone
FROM client_organisation_spl spl
LEFT JOIN organisations org ON org.id = spl.service_provider_id
WHERE spl.client_org_id = '<clientOrgId>'
  AND spl.status = 'active';
```

---

#### Method: `searchOrganisations(String query)`
**Type:** READ (SELECT)

```dart
var req = _client.from('organisations').select('id, name, contact_email, contact_phone');

if (query.isNotEmpty) {
  req = req.ilike('name', '%$query%'); // Case-insensitive search
}

final response = await req.limit(20);
```

**What it does:**
- Queries the **`organisations`** table (NOT the SPL table)
- Performs a case-insensitive search on the `name` column using `ilike`
- Limits to 20 results for performance
- Used in the "Add Service Provider" dialog to search for agencies

**SQL Equivalent:**
```sql
SELECT id, name, contact_email, contact_phone
FROM organisations
WHERE name ILIKE '%<query>%'
LIMIT 20;
```

---

#### Method: `addServiceProvider(...)` — **WRITES DATA**
**Type:** WRITE (UPSERT — INSERT or UPDATE)

```dart
await _client.from('client_organisation_spl').upsert({
  'client_org_id': clientOrgId,
  'service_provider_id': serviceProviderId,
  'contract_rate': contractRate,
  'is_preferred': isPreferred,
  'status': 'active',
}, onConflict: 'client_org_id, service_provider_id'); // Prevents duplicates
```

**What it does:**
- **Writes/upserts** a new row into the **`client_organisation_spl`** table
- The `onConflict: 'client_org_id, service_provider_id'` parameter means:
  - If a row with the same `(client_org_id, service_provider_id)` combo exists → **UPDATE** it
  - If no matching row exists → **INSERT** a new row
- This prevents duplicate SPL entries

**Data written (columns):**
| Column | Value |
|---|---|
| `client_org_id` | The care home's organisation UUID |
| `service_provider_id` | The agency's organisation UUID |
| `contract_rate` | Hourly rate (£, nullable) |
| `is_preferred` | Boolean flag (true = preferred provider) |
| `status` | Hardcoded to `'active'` |

---

#### Method: `removeServiceProvider(String splId)`
**Type:** WRITE (UPDATE — soft delete)

```dart
await _client
    .from('client_organisation_spl')
    .update({'status': 'terminated'})
    .eq('id', splId);
```

**What it does:**
- **Updates** an existing row in `client_organisation_spl`
- Sets `status = 'terminated'` (soft-delete — the row is NOT physically deleted)
- Targets the row by its `id` (the UUID of the SPL entry, not the organisation ID)

---

### 1.3 SPL Table Schema (Inferred from Usage)

```sql
CREATE TABLE client_organisation_spl (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_org_id UUID NOT NULL REFERENCES organisations(id),
  service_provider_id UUID NOT NULL REFERENCES organisations(id),
  contract_rate NUMERIC(10,2),          -- £ per hour
  is_preferred BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'active',          -- active | terminated
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(client_org_id, service_provider_id)
);
```

---

## 2. Shift Template Service (`shift_template_service.dart`)

**File:** `client-app/lib/services/shift_template_service.dart`

### 2.1 The Table it Reads/Writes To

| Item | Value |
|---|---|
| **Table name** | `shift_templates` |
| **Schema** | `public` |
| **Purpose** | Stores reusable shift templates (e.g., "Morning Carer 8-4", "Night Nurse 8-8") |

### 2.2 All Methods & Their Database Operations

---

#### Method: `getTemplates(String clientOrganisationId)`
**Type:** READ (SELECT)

```dart
final response = await _client
    .from('shift_templates')
    .select()
    .eq('client_organisation_id', clientOrganisationId)
    .eq('is_active', true)
    .order('name', ascending: true);
```

**What it does:**
- Queries **`shift_templates`** table
- Filters by `client_organisation_id` (only that care home's templates)
- Filters by `is_active = true` (only active templates — deleted ones are soft-deleted)
- Orders alphabetically by `name`

**SQL Equivalent:**
```sql
SELECT * FROM shift_templates
WHERE client_organisation_id = '<clientOrgId>'
  AND is_active = true
ORDER BY name ASC;
```

---

#### Method: `createTemplate(...)` — **WRITES DATA**
**Type:** WRITE (INSERT)

```dart
final response = await _client
    .from('shift_templates')
    .insert({
      'client_organisation_id': clientOrganisationId,
      'name': name,
      'code': code,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': true,
    })
    .select()
    .single();
```

**What it does:**
- **Inserts** a new row into the **`shift_templates`** table
- Returns the created row (`.select().single()`)

**Data written (columns):**
| Column | Value |
|---|---|
| `client_organisation_id` | Care home's organisation UUID |
| `name` | Human-readable name (e.g., "Morning Shift") |
| `code` | Short code (e.g., "MORN") |
| `start_time` | "08:00:00" format |
| `end_time` | "16:00:00" format |
| `is_active` | Hardcoded `true` |

---

#### Method: `updateTemplate(ShiftTemplate template)`
**Type:** WRITE (UPDATE)

```dart
final response = await _client
    .from('shift_templates')
    .update(template.toJson())
    .eq('id', template.id)
    .select()
    .single();
```

**What it does:**
- **Updates** an existing row in `shift_templates`
- Uses `template.toJson()` which includes: `id, name, code, start_time, end_time, client_organisation_id, is_active`

---

#### Method: `deleteTemplate(String templateId)`
**Type:** WRITE (UPDATE — soft delete)

```dart
await _client
    .from('shift_templates')
    .update({'is_active': false})
    .eq('id', templateId);
```

**What it does:**
- Soft-deletes by setting `is_active = false`
- Row is NOT physically removed from the table
- The template disappears from `getTemplates()` queries

---

#### Method: `getTemplateById(String id)`
**Type:** READ (SELECT)

```dart
final response = await _client
    .from('shift_templates')
    .select()
    .eq('id', id)
    .single();
```

---

### 2.3 Shift Templates Table Schema (Inferred)

```sql
CREATE TABLE shift_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_organisation_id UUID NOT NULL REFERENCES organisations(id),
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  start_time TIME NOT NULL,          -- 'HH:MM:SS'
  end_time TIME NOT NULL,            -- 'HH:MM:SS'
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

---

## 3. The "Shift Type" Dropdown in Book Shift Screen

**File:** `client-app/lib/ui/shifts/book_shift_screen.dart` (lines 133-159)

### 3.1 What the Dropdown Shows

```dart
DropdownButtonFormField<ShiftTemplate>(
  value: _selectedTemplate,
  decoration: const InputDecoration(
    labelText: 'Shift Type (Optional)',
    hintText: 'Select a type or choose Custom',
  ),
  items: [
    const DropdownMenuItem<ShiftTemplate>(
      value: null,
      child: Text('Custom'),
    ),
    ..._templates.map((template) {
      return DropdownMenuItem<ShiftTemplate>(
        value: template,
        child: Text('${template.code} - ${template.name} (${template.timeRange})'),
      );
    }).toList(),
  ],
  onChanged: _onTemplateSelected,
)
```

### 3.2 Where the Data Comes From

**Source table: `shift_templates` (via `ShiftTemplateService.getTemplates()`)**

### 3.3 Complete Data Flow for the Dropdown

```
BookShiftScreen.initState()
    │
    └── _loadTemplatesAndCarers()  (line 50)
        │
        ├── auth = context.read<SupabaseAuthService>()
        ├── clientOrgId = auth.clientOrganisationId   ← care home UUID
        │
        └── ShiftTemplateService().getTemplates(clientOrgId)
            │
            └── Supabase query:
                SELECT * FROM shift_templates
                WHERE client_organisation_id = '<care_home_uuid>'
                  AND is_active = true
                ORDER BY name ASC
            │
            └── Returns List<ShiftTemplate> → stored in _templates
                │
                └── Dropdown renders:
                    - "Custom" (hardcoded null option)
                    - "${template.code} - ${template.name} (${template.timeRange})"
                      e.g. "MORN - Morning Shift (08:00 - 16:00)"
```

### 3.4 How Selection Affects the Form

When a template is selected (`_onTemplateSelected`, line 82):

```dart
void _onTemplateSelected(ShiftTemplate? template) {
  setState(() {
    _selectedTemplate = template;
    if (template != null) {
      _startTime = template.startTimeOfDay;   // Auto-fills start time
      _endTime = template.endTimeOfDay;       // Auto-fills end time
    }
  });
}
```

- Selecting a template **auto-fills** the Start and End time pickers
- Selecting "Custom" (null) leaves the times as currently set

### 3.5 Key Detail: `timeRange` Formatting

```dart
String get timeRange {
  return '${startTime.substring(0, 5)} - ${endTime.substring(0, 5)}';
}
```

The dropdown label displays as:
`CODE - Name (HH:MM - HH:MM)` e.g., **`MORN - Morning Shift (08:00 - 16:00)`**

---

## 4. Summary Table

| Service | Table (Schema) | Read? | Write? | Methods |
|---|---|---|---|---|
| `SplService` | `client_organisation_spl` (public) | ✅ SELECT | ✅ UPSERT / UPDATE | `getServiceProviders`, `addServiceProvider`, `removeServiceProvider` |
| `SplService` | `organisations` (public) | ✅ SELECT | ❌ | `searchOrganisations` |
| `ShiftTemplateService` | `shift_templates` (public) | ✅ SELECT | ✅ INSERT / UPDATE | `getTemplates`, `getTemplateById`, `createTemplate`, `updateTemplate`, `deleteTemplate` |
| Book Shift UI | `shift_templates` (public) | ✅ SELECT | ❌ | via `ShiftTemplateService.getTemplates()` |

---

## 5. Key Differences Between the Two SPL Concepts

**Important note:** There are **TWO different tables** used for agency relationships in this codebase:

| Table | Used By | Status Values | Purpose |
|---|---|---|---|
| `client_organisation_spl` | `SplService` (client-app SPL management screen) | `active`, `terminated` | Managing the visible SPL list with contract rates & preferred flags |
| `client_organisation_psl` | Shift broadcast logic (earlier implementation) | `active`, `suspended`, `removed` | The broadcast/PROVIDER supplier list used by `broadcastToAll()` |

They serve similar purposes but are **separate tables**. The `book_shift_screen.dart` currently uses:
- `client_organisation_psl` for the agency selection chips (via `_loadAvailableAgencies()` line 118)
- `shift_templates` for the "Shift Type" dropdown

## 6. Data Flow Diagram (End-to-End)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        CLIENT-APP (Flutter)                            │
│                                                                        │
│  ┌───────────────────┐    ┌──────────────────────┐                    │
│  │  SPL Management   │───▶│  SplService           │                    │
│  │  Screen           │    │  ├─ getServiceProviders│──▶ client_organisation_spl (SELECT)
│  │                   │    │  ├─ searchOrganisations│──▶ organisations (SELECT)
│  │                   │    │  ├─ addServiceProvider │──▶ client_organisation_spl (UPSERT)
│  │                   │    │  └─ removeServiceProv. │──▶ client_organisation_spl (UPDATE)
│  └───────────────────┘    └──────────────────────┘                    │
│                                                                        │
│  ┌───────────────────┐    ┌──────────────────────┐                    │
│  │  Shift Templates  │───▶│  ShiftTemplateService │                    │
│  │  Screen           │    │  ├─ getTemplates      │──▶ shift_templates (SELECT)
│  │                   │    │  ├─ createTemplate    │──▶ shift_templates (INSERT)
│  │                   │    │  ├─ updateTemplate    │──▶ shift_templates (UPDATE)
│  │                   │    │  └─ deleteTemplate    │──▶ shift_templates (UPDATE soft)
│  └───────────────────┘    └──────────────────────┘                    │
│                                                                        │
│  ┌───────────────────┐    ┌──────────────────────┐                    │
│  │  Book Shift       │───▶│  ShiftTemplateService │                    │
│  │  Screen           │    │  └─ getTemplates      │──▶ shift_templates (SELECT)
│  │  ("Shift Type"    │    │                        │                    │
│  │   dropdown)       │    └──────────────────────┘                    │
│  └───────────────────┘                                                 │
└────────────────────────────────────────────────────────────────────────┘