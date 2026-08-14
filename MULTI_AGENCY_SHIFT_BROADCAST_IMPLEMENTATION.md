# Multi-Agency Shift Broadcasting Implementation

## Overview
This document summarizes the implementation of multi-agency shift broadcasting functionality for the CareQA system. This feature allows clients to broadcast shift requests to multiple agencies simultaneously through a Preferred Supplier List (PSL) mechanism.

---

## Phase 1: Core Infrastructure

### 1. Database Migration

**File:** `supabase/migrations/118_create_psl_table.sql`

**Purpose:** Creates the Preferred Supplier List (PSL) table that manages which agencies a client can broadcast shifts to.

**Table Structure:**
```sql
CREATE TABLE client_organisation_psl (
    id UUID PRIMARY KEY,
    client_org_id UUID REFERENCES organisations(id),  -- The care home
    organisation_id UUID REFERENCES organisations(id),  -- The agency
    status TEXT DEFAULT 'active',  -- active, suspended, removed
    notes TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    UNIQUE(client_org_id, organisation_id)
);
```

**Key Features:**
- Enforces one-to-many relationship between clients and agencies
- Status tracking for PSL entries
- RLS policies for client and agency access
- Automatic updated_at timestamp via trigger

---

### 2. Core Model Updates

**File:** `packages/core/lib/models/shift.dart`

**Changes Made:**

#### Added Fields:
- `clientOrganisationId` - The care home's organisation ID
- `serviceUserName` - Joined name from service_users table
- `carerName` - Joined name from carers table
- `scheduledDate` - Date of the shift (separate from start/end time)
- `location` - Shift location
- `staffRequired` - Number of staff needed
- `staffType` - Type of staff required
- `organisationId` - The agency assigned to this shift
- `agencyClientId` - For agency billing/revenue tracking
- `agencyBillingRate` - Billing rate for agency shifts
- `broadcastType` - Enum: single, multiple, all

#### Added Enum:
```dart
enum BroadcastType {
  single('single'),    // One specific agency
  multiple('multiple'), // Multiple selected agencies
  all('all');          // All agencies in PSL
}
```

#### Updated Constructor:
- Made `status` optional with default `ShiftStatus.scheduled`
- Added all new fields with appropriate defaults
- Maintained backward compatibility

**Note:** The core model uses `DateTime` for `startTime` and `endTime`, while the client-app model uses `TimeOfDay`. This requires conversion when mapping between models.

---

### 3. Client-App Model Updates

**File:** `client-app/lib/models/shift.dart`

**Changes Made:**

#### Added Fields:
- `serviceUserName` - Display name for service user
- `carerName` - Display name for assigned carer
- `organisationId` - Agency organisation ID
- `agencyClientId` - For agency billing
- `agencyBillingRate` - Billing rate
- `broadcastType` - Broadcast type enum

#### Added Enum:
```dart
enum BroadcastType {
  single('single'),
  multiple('multiple'),
  all('all');
}
```

#### Updated JSON Serialization:
- `fromJson()` now extracts joined names from `service_users.name` and `carers.name`
- `toJson()` includes `broadcast_type` field
- Maintains backward compatibility with existing data

---

### 4. Client-App Shift Service Updates

**File:** `client-app/lib/services/shift_service.dart`

**New Methods:**

#### `createShift()` - Updated
**Purpose:** Creates a single shift for a specific agency.

**New Parameters:**
- `organisationId` (required) - The agency to assign
- `notes` (optional) - Shift notes
- `broadcastType` (optional) - Defaults to `BroadcastType.single`

**Implementation:**
```dart
Future<Shift> createShift({
  required String clientOrganisationId,
  required String organisationId,  // NEW
  required DateTime scheduledDate,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  String? location,
  int? staffRequired,
  String? staffType,
  String? notes,  // NEW
  BroadcastType broadcastType = BroadcastType.single,  // NEW
}) async {
  final shiftId = _uuid.v4();
  
  final shiftData = {
    'id': shiftId,
    'client_organisation_id': clientOrganisationId,
    'organisation_id': organisationId,  // NEW
    'scheduled_date': ...,
    'start_time': ...,
    'end_time': ...,
    'status': 'scheduled',
    'location': location,
    'staff_required': staffRequired ?? 1,
    'staff_type': staffType,
    'notes': notes,  // NEW
    'broadcast_type': broadcastType.name,  // NEW
  };
  
  // Insert and return
}
```

#### `broadcastShift()` - New
**Purpose:** Creates multiple shifts for a list of agencies.

**Implementation:**
- Loops through `organisationIds`
- Calls `createShift()` for each agency
- Sets `broadcastType` to `BroadcastType.multiple`
- Returns list of created shifts

#### `broadcastToAll()` - New
**Purpose:** Creates shifts for all active agencies in the client's PSL.

**Implementation:**
- Queries `client_organisation_psl` table
- Filters by `client_org_id` and `status = 'active'`
- Extracts all `organisation_id` values
- Calls `broadcastShift()` with the list
- Throws exception if no agencies in PSL

---

### 5. Book Shift Screen Updates

**File:** `client-app/lib/ui/shifts/book_shift_screen.dart`

**UI Changes:**

#### Added Broadcast Type Selection:
```dart
RadioListTile<BroadcastType>(
  title: Text('Single Agency'),
  subtitle: Text('Select one agency from your list'),
  value: BroadcastType.single,
  ...
)

RadioListTile<BroadcastType>(
  title: Text('Multiple Agencies'),
  subtitle: Text('Select multiple agencies'),
  value: BroadcastType.multiple,
  ...
)

RadioListTile<BroadcastType>(
  title: Text('All Agencies'),
  subtitle: Text('Broadcast to all active agencies in your list'),
  value: BroadcastType.all,
  ...
)
```

#### Added Agency Selection:
- Loads agencies from `client_organisation_psl` table
- Displays as filter chips for single/multiple selection
- Enforces single selection for `BroadcastType.single`
- Allows multiple selection for `BroadcastType.multiple`
- Hidden for `BroadcastType.all` (automatic)

#### Updated Submit Logic:
```dart
Future<void> _submit() async {
  // Validate form
  // Validate agency selection
  
  if (_broadcastType == BroadcastType.single) {
    await service.createShift(
      clientOrganisationId: clientOrgId,
      organisationId: _selectedAgencyIds.first,
      ...
      broadcastType: BroadcastType.single,
    );
  } else if (_broadcastType == BroadcastType.multiple) {
    await service.broadcastShift(
      clientOrganisationId: clientOrgId,
      organisationIds: _selectedAgencyIds,
      ...
    );
  } else if (_broadcastType == BroadcastType.all) {
    await service.broadcastToAll(
      clientOrganisationId: clientOrgId,
      ...
    );
  }
}
```

---

## Phase 2: Admin-App Updates (Pending)

### Required Changes:

#### 1. Update Admin Shift Service
**File:** `admin-app/lib/services/shift_service.dart`

**Changes Needed:**
- Add `organisationId` field to Shift model
- Add `broadcastType` field to Shift model
- Update `getShiftsForDate()` to filter by `organisation_id` (agency view)
- Add method to get shifts by agency
- Update queries to include new fields

#### 2. Update Admin Shift List Screen
**File:** `admin-app/lib/ui/shift/shift_list_screen.dart`

**Changes Needed:**
- Display `broadcastType` in shift cards
- Add filtering by broadcast type
- Show which shifts are broadcast vs direct
- Add agency filtering view

#### 3. Update Admin Shift Model
**File:** `admin-app/lib/services/shift_service.dart` (local model)

**Changes Needed:**
- Add `organisationId` field
- Add `broadcastType` field
- Add `agencyClientId` field
- Add `agencyBillingRate` field
- Update `fromJson()` to handle new fields

---

## Database Schema Summary

### Current `shifts` Table:
```sql
CREATE TABLE shifts (
  id UUID PRIMARY KEY,
  service_user_id UUID REFERENCES service_users(id),
  carer_id UUID REFERENCES carers(id),
  scheduled_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'scheduled',
  organisation_id UUID REFERENCES organisations(id),  -- NEW
  agency_client_id UUID,  -- NEW
  agency_billing_rate DECIMAL(10,2),  -- NEW
  broadcast_type TEXT DEFAULT 'single',  -- NEW
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
);
```

### New `client_organisation_psl` Table:
```sql
CREATE TABLE client_organisation_psl (
  id UUID PRIMARY KEY,
  client_org_id UUID REFERENCES organisations(id),
  organisation_id UUID REFERENCES organisations(id),
  status TEXT DEFAULT 'active',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(client_org_id, organisation_id)
);
```

---

## Data Flow Diagrams

### Single Agency Broadcast:
```
Client selects "Single Agency"
    ↓
Selects one agency from PSL
    ↓
Clicks "Book Shift"
    ↓
createShift() called with organisationId
    ↓
INSERT INTO shifts with:
  - client_organisation_id = care home
  - organisation_id = selected agency
  - broadcast_type = 'single'
    ↓
Shift created and returned
```

### Multiple Agency Broadcast:
```
Client selects "Multiple Agencies"
    ↓
Selects multiple agencies from PSL
    ↓
Clicks "Book Shift"
    ↓
broadcastShift() called with organisationIds[]
    ↓
For each agency:
  INSERT INTO shifts with:
    - client_organisation_id = care home
    - organisation_id = agency
    - broadcast_type = 'multiple'
    ↓
  Create shift record
    ↓
Return list of created shifts
```

### All Agencies Broadcast:
```
Client selects "All Agencies"
    ↓
Clicks "Book Shift"
    ↓
broadcastToAll() called
    ↓
Query client_organisation_psl:
  SELECT organisation_id
  WHERE client_org_id = ? AND status = 'active'
    ↓
Get list of all active agencies
    ↓
Calls broadcastShift() with all agency IDs
    ↓
For each agency:
  INSERT INTO shifts (same as multiple)
    ↓
Return list of created shifts
```

---

## Testing Checklist

### Database Migration:
- [ ] Run migration 118 in Supabase SQL Editor
- [ ] Verify `client_organisation_psl` table created
- [ ] Verify indexes created
- [ ] Verify RLS policies enabled
- [ ] Verify trigger created for updated_at

### Core Package:
- [x] Update Shift model with new fields
- [x] Add BroadcastType enum
- [ ] Run build_runner to generate shift.g.dart
- [ ] Verify generated code includes new fields
- [ ] Update core.dart exports if needed

### Client-App:
- [x] Update client Shift model
- [x] Add BroadcastType enum
- [x] Update shift_service.dart with new methods
- [x] Update book_shift_screen.dart with broadcast UI
- [ ] Test single agency booking
- [ ] Test multiple agency booking
- [ ] Test all agencies booking
- [ ] Verify organisation_id set correctly
- [ ] Verify broadcast_type set correctly
- [ ] Verify carer_id is NOT set (admin assigns later)

### Admin-App (Pending):
- [ ] Update admin Shift model
- [ ] Update admin shift_service.dart
- [ ] Update shift_list_screen.dart
- [ ] Test viewing broadcast shifts
- [ ] Test filtering by broadcast type
- [ ] Test assigning carers to broadcast shifts

---

## Known Issues & TODOs

### Issue 1: build_runner Timeout
**Problem:** `flutter pub run build_runner build` timed out after 30 seconds.

**Solution:** The command is running in the background. Check the log file or run manually:
```bash
cd packages/core
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue 2: Model Mismatch
**Problem:** Core model uses `DateTime` for times, client-app uses `TimeOfDay`.

**Solution:** Currently handled by separate models. Consider creating extension methods for conversion:
```dart
extension TimeOfDayExtension on TimeOfDay {
  String toTimeString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }
}
```

### Issue 3: Missing Admin Updates
**Problem:** Admin-app hasn't been updated to handle new fields.

**Solution:** Implement Phase 2 changes listed above.

### TODO: PSL Management UI
**Missing:** No UI for managing the PSL (adding/removing agencies).

**Required:** Create screen for clients to:
- View current PSL
- Add agencies to PSL
- Remove agencies from PSL
- Suspend/reactivate agencies

### TODO: Agency Notification
**Missing:** No notification system for agencies when shifts are broadcast.

**Required:** Implement notification system:
- Create notification when shift is broadcast
- Include shift details in notification
- Allow agency to accept/decline
- Update shift status based on response

---

## Migration Guide

### For Existing Shifts:
All existing shifts will have:
- `organisation_id` = NULL
- `broadcast_type` = 'single' (default)
- `agency_client_id` = NULL
- `agency_billing_rate` = NULL

### For New Shifts:
All new shifts created through the client-app will have:
- `organisation_id` = selected agency
- `broadcast_type` = 'single', 'multiple', or 'all'
- `carer_id` = NULL (admin assigns later)

---

## Security Considerations

### RLS Policies:
1. **Clients** can view/manage their own PSL
2. **Agencies** can view which clients have them in PSL
3. **Shifts** respect existing RLS policies
4. **Broadcast shifts** are visible to assigned agencies via `organisation_id`

### Data Isolation:
- Clients can only see their own shifts (via `client_organisation_id`)
- Agencies can only see shifts assigned to them (via `organisation_id`)
- Admins can see all shifts

---

## Performance Considerations

### Indexes:
- `idx_client_organisation_psl_client_org` - Fast PSL lookups by client
- `idx_client_organisation_psl_organisation` - Fast PSL lookups by agency
- `idx_client_organisation_psl_status` - Fast filtering by status

### Query Optimization:
- PSL queries use indexed columns
- Broadcast queries batch insert multiple shifts
- Consider adding composite index for common queries

---

## Next Steps

1. **Complete build_runner** - Generate shift.g.dart with new fields
2. **Update admin-app** - Handle new fields in admin interface
3. **Create PSL management UI** - Allow clients to manage their agency list
4. **Implement notifications** - Notify agencies of broadcast shifts
5. **Add acceptance workflow** - Allow agencies to accept/decline shifts
6. **Testing** - Comprehensive testing of all broadcast scenarios
7. **Documentation** - Update user guides and API docs

---

## Summary

This implementation adds comprehensive multi-agency shift broadcasting functionality:

✅ **Completed:**
- Database migration for PSL table
- Core model updates with new fields
- Client-app model updates
- Shift service with broadcast methods
- Book shift screen with broadcast UI

⏳ **Pending:**
- Admin-app updates
- PSL management UI
- Notification system
- Acceptance workflow
- Testing

The foundation is in place for clients to broadcast shifts to multiple agencies, with proper data isolation, security, and scalability.