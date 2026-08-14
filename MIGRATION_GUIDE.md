# CareQA Supabase Migration Guide

## Overview

This document provides a comprehensive guide for migrating from Firebase to Supabase for the CareQA Flutter application. The migration includes database schema changes, API updates, and new compliance features.

## Migration Status: ✅ Phase 2A Complete

### What's Been Migrated

#### ✅ Database Schema
- **Complete Supabase database schema** with proper relationships
- **Row Level Security (RLS)** policies for data protection
- **Generated columns** for compliance calculations
- **Indexes** for optimal performance
- **Triggers** for automatic timestamp updates

#### ✅ Core Tables
- `profiles` - Extends Supabase Auth with user roles
- `carers` - Enhanced with compliance fields (DBS, documents, training)
- `service_users` - Complete care plan management
- `shifts` - Scheduling with status tracking
- `visits` - Check-in/out with compliance percentage
- `documents` - Document management with expiry tracking
- `notifications` - Real-time notifications system
- `settings` - Configurable business rules

#### ✅ Flutter Application Updates
- **Supabase dependencies** added to both admin and staff apps
- **Updated data models** for Supabase compatibility
- **New authentication service** using Supabase Auth
- **Enhanced firestore service** with Supabase API
- **Profile management** for user roles and permissions

### Key Features Added

#### 🔐 Enhanced Security
- **Row Level Security** - Users can only access their data
- **Role-based access** - Admin vs Carer permissions
- **Secure document storage** - File URLs with access control

#### 📋 Compliance Management
- **DBS tracking** - Expiry dates and certificate URLs
- **Document management** - ID, training, right-to-work documents
- **Auto-flagging** - Short visits automatically flagged
- **Compliance percentages** - Calculated visit duration compliance

#### 📊 Advanced Features
- **Real-time updates** - Live data synchronization
- **Notifications system** - Configurable alerts and reminders
- **Settings management** - Business rule configuration
- **Structured visit notes** - Mood scores, incidents, medications

## Setup Instructions

### 1. Supabase Project Setup

1. **Create Supabase Project**
   ```bash
   # Go to https://supabase.com
   # Create new project
   # Note your Project URL and API keys
   ```

2. **Run Database Migration**
   ```sql
   -- Copy and run the SQL from supabase/migrations/001_initial_schema.sql
   -- This creates all tables, policies, and indexes
   ```

3. **Configure Environment Variables**
   ```bash
   # Copy supabase/supabase.env to .env
   # Fill in your actual Supabase credentials
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

### 2. Flutter Application Setup

1. **Install Dependencies**
   ```bash
   cd admin-app
   flutter pub get
   
   cd ../staff-app
   flutter pub get
   ```

2. **Update Supabase Configuration**
   ```dart
   // In lib/supabase_config.dart
   static const String supabaseUrl = 'https://your-project-ref.supabase.co';
   static const String supabaseAnonKey = 'your-anon-key-here';
   ```

3. **Initialize Supabase**
   ```dart
   // In main.dart files
   await SupabaseConfig.initialize();
   ```

### 3. Storage Configuration

1. **Create Storage Buckets**
   - `documents` - For compliance documents
   - `profile-photos` - For user profile images

2. **Set Storage Policies**
   ```sql
   -- Allow authenticated users to upload documents
   CREATE POLICY "Users can upload documents"
     ON storage.objects FOR INSERT
     WITH CHECK (bucket_id = 'documents' AND auth.role() = 'authenticated');
   ```

## API Changes

### Authentication
```dart
// Old Firebase
FirebaseAuth.instance.signInWithEmailAndPassword(email, password);

// New Supabase
Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);
```

### Database Operations
```dart
// Old Firebase
FirebaseFirestore.instance.collection('carers').add(carerData);

// New Supabase
Supabase.instance.client.from('carers').insert(carerData);
```

### Real-time Updates
```dart
// Old Firebase
FirebaseFirestore.instance.collection('visits').snapshots();

// New Supabase
Supabase.instance.client.from('visits').stream(primaryKey: ['id']);
```

## New Features

### Compliance Dashboard
- **Document expiry tracking** - Automatic warnings
- **Visit compliance** - Percentage calculations
- **Flagged visits** - Manual and automatic flagging
- **Training records** - JSON-based training management

### Enhanced Visit Management
- **Structured notes** - Mood scores, incident tracking
- **Duration calculations** - Automatic minute calculations
- **Compliance percentages** - Real-time compliance tracking
- **Flag reasons** - Detailed flagging with reasons

### Notifications System
- **Configurable alerts** - DBS expiry, document expiry
- **Real-time updates** - Live notification delivery
- **Read/unread tracking** - User notification management
- **Data payloads** - Rich notification data

## Next Steps (Phase 2B)

### Business Logic Implementation
- **Compliance rules** - Auto-flagging logic
- **Document validation** - Pre-shift document checks
- **Notification triggers** - Automated expiry warnings
- **Settings enforcement** - Business rule application

### Advanced Features
- **Geofencing** - Location-based check-in/out
- **QR code scanning** - Service user verification
- **Photo capture** - Visit documentation
- **Advanced reporting** - Compliance dashboards

### Integration Features
- **Email notifications** - SMTP integration
- **Push notifications** - Mobile push alerts
- **Audit logging** - Complete audit trails
- **Export functionality** - Data export capabilities

## Troubleshooting

### Common Issues

1. **RLS Policies Blocking Access**
   ```sql
   -- Check if policies are too restrictive
   SELECT * FROM pg_policies WHERE tablename = 'carers';
   ```

2. **Supabase Client Not Initialized**
   ```dart
   // Ensure Supabase is initialized before use
   await SupabaseConfig.initialize();
   ```

3. **Storage Permissions**
   ```sql
   -- Check storage policies
   SELECT * FROM storage.policies;
   ```

### Debug Commands

```bash
# Check Supabase status
supabase status

# View logs
supabase logs

# Test database connection
supabase db shell
```

## Support

For migration support:
- Check the [Supabase Documentation](https://supabase.com/docs)
- Review the [Flutter Supabase Plugin](https://pub.dev/packages/supabase_flutter)
- Create issues in the project repository

## Migration Checklist

- [x] Database schema created
- [x] RLS policies configured
- [x] Flutter dependencies updated
- [x] Authentication migrated
- [x] Data models updated
- [x] Services migrated
- [ ] Business logic implemented
- [ ] Compliance rules added
- [ ] Notifications configured
- [ ] Testing completed
- [ ] Production deployment

---

**Migration Status**: Phase 2A - Database and Basic API Migration ✅
**Next Phase**: Phase 2B - Business Logic and Advanced Features