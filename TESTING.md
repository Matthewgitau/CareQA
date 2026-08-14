# CareQA Testing Guide

## 📱 Physical Device Testing Guide

This guide provides comprehensive instructions for testing CareQA on physical Android devices.

## 📋 Prerequisites

### Development Environment
- [x] Flutter installed and configured
- [x] Android Studio with Android SDK
- [x] Two Android phones with Developer Mode enabled
- [x] USB cables for both phones
- [x] Stable internet connection

### Supabase Setup
- [x] Supabase project created
- [x] Database migrations run (001-027)
- [x] RLS policies configured
- [x] Environment variables set

## 🚀 Quick Start

### 1. Build APKs
```bash
# Run the build script
./build_all_apks.sh
```

### 2. Install Test Users
```sql
-- Run this in Supabase SQL Editor
-- See create_test_users.sql for complete script
```

### 3. Install APKs on Devices
```bash
# Copy APKs to devices
admin-app/build/app/outputs/flutter-apk/app-release.apk
staff-app/build/app/outputs/flutter-apk/app-release.apk
```

### 4. Run Testing Workflow
```bash
# Follow the complete testing guide
./test_core_workflow.sh
```

## 📲 App Installation

### Admin App Installation
1. Copy `admin-app/build/app/outputs/flutter-apk/app-release.apk` to Phone 1
2. On Phone 1, enable "Install from unknown sources" in Settings
3. Install the APK file
4. Launch the app

### Staff App Installation
1. Copy `staff-app/build/app/outputs/flutter-apk/app-release.apk` to Phone 2
2. On Phone 2, enable "Install from unknown sources" in Settings
3. Install the APK file
4. Launch the app

## 🔐 Test Credentials

### Admin User
- **Email**: `admin@careqa.com`
- **Password**: `password123`
- **Role**: Admin

### Carer User
- **Email**: `carer@careqa.com`
- **Password**: `password123`
- **Role**: Carer

## 🧪 Testing Scenarios

### Scenario 1: Complete Workflow Test
**Objective**: Test the full end-to-end workflow

**Steps**:
1. Admin creates service user and carer
2. Admin schedules a shift
3. Carer logs in and views shift
4. Carer checks in, completes chart, checks out
5. Admin verifies data synchronization

**Expected Results**:
- ✅ All data syncs between apps in real-time
- ✅ Charts are properly stored and accessible
- ✅ Shift status updates correctly
- ✅ No data loss or corruption

### Scenario 2: Network Connectivity Test
**Objective**: Test app behavior with poor network

**Steps**:
1. Enable airplane mode on one device
2. Perform operations offline
3. Re-enable network
4. Verify data sync

**Expected Results**:
- ✅ App handles offline scenarios gracefully
- ✅ Data syncs when network is restored
- ✅ No data loss during network interruptions

### Scenario 3: Multiple Device Test
**Objective**: Test concurrent access

**Steps**:
1. Multiple users log in simultaneously
2. Perform operations concurrently
3. Verify data consistency

**Expected Results**:
- ✅ No conflicts between concurrent users
- ✅ Data remains consistent across devices
- ✅ Proper conflict resolution

### Scenario 4: Form Completion Test
**Objective**: Test all form categories

**Steps**:
1. Complete each form category
2. Verify data validation
3. Test PDF generation (placeholder)
4. Check data persistence

**Expected Results**:
- ✅ All 27 form categories work correctly
- ✅ Data validation prevents invalid entries
- ✅ PDF generation process starts
- ✅ Data persists across app restarts

## 🔧 Troubleshooting

### Build Issues
**Problem**: Flutter build fails
**Solutions**:
- Check Flutter installation: `flutter doctor`
- Ensure Android SDK is properly configured
- Run `flutter clean` and try again
- Verify environment variables are set

**Problem**: APK installation fails
**Solutions**:
- Enable "Install from unknown sources" in device settings
- Check APK file integrity
- Ensure sufficient storage space
- Try manual installation via ADB

### Authentication Issues
**Problem**: Login fails
**Solutions**:
- Verify Supabase credentials in .env files
- Check internet connection
- Verify test users exist in database
- Check Supabase auth settings

**Problem**: Session expires
**Solutions**:
- Check Supabase JWT settings
- Verify network connectivity
- Re-login if needed

### Data Sync Issues
**Problem**: Data doesn't sync between devices
**Solutions**:
- Check internet connection on both devices
- Verify Supabase project URL and keys
- Check Supabase dashboard for errors
- Review app logs for sync errors

**Problem**: Data appears corrupted
**Solutions**:
- Check database schema
- Verify RLS policies
- Review data validation rules
- Check for constraint violations

### Performance Issues
**Problem**: App is slow or unresponsive
**Solutions**:
- Check device performance
- Monitor network speed
- Review database query performance
- Check for memory leaks

**Problem**: PDF generation fails
**Solutions**:
- Note: PDF generation is currently a placeholder
- Verify PDF library integration
- Check file permissions
- Monitor memory usage

## 📊 Test Data

### Test Service User
```json
{
  "name": "Mary Jones",
  "address": "123 Care Home Lane, London",
  "date_of_birth": "1945-03-15",
  "medical_conditions": "Diabetes, Hypertension"
}
```

### Test Carer
```json
{
  "name": "John Smith",
  "employee_number": "EMP001",
  "qualifications": ["NVQ Level 3", "First Aid"]
}
```

### Test Shift
```json
{
  "service_user_id": "Mary Jones",
  "carer_id": "John Smith",
  "shift_type": "Morning",
  "date": "Today's date",
  "duration": "8 hours",
  "status": "Scheduled"
}
```

## 📈 Performance Benchmarks

### App Launch Time
- **Target**: < 3 seconds
- **Measurement**: Time from app icon tap to main screen

### Data Sync Time
- **Target**: < 2 seconds
- **Measurement**: Time from data save to availability on other device

### Form Completion Time
- **Target**: < 30 seconds for complex forms
- **Measurement**: Time from form open to successful save

### Memory Usage
- **Target**: < 100MB idle, < 200MB active
- **Measurement**: App memory footprint during typical usage

## 🔒 Security Testing

### Authentication Security
- ✅ Password strength requirements
- ✅ Session timeout handling
- ✅ Secure token storage
- ✅ Proper logout functionality

### Data Security
- ✅ RLS policy enforcement
- ✅ Data encryption in transit
- ✅ No sensitive data in logs
- ✅ Proper error handling

### Network Security
- ✅ HTTPS enforcement
- ✅ Certificate validation
- ✅ No hardcoded credentials
- ✅ Secure API endpoints

## 📱 Device Compatibility

### Supported Android Versions
- **Minimum**: Android 8.0 (API 26)
- **Recommended**: Android 10+ (API 29+)

### Screen Sizes
- **Phone**: 4.7" - 6.5"
- **Tablet**: 7" - 10.1"
- **Resolution**: 720p - 1440p

### Device Types Tested
- ✅ Samsung Galaxy series
- ✅ Google Pixel series
- ✅ OnePlus devices
- ✅ Huawei devices (with Google Play Services)

## 🚨 Common Issues & Solutions

### Issue: "App keeps stopping"
**Cause**: Missing dependencies or corrupted installation
**Solution**: Uninstall and reinstall APK, check logs for specific errors

### Issue: "No internet connection"
**Cause**: Network configuration or firewall blocking
**Solution**: Check network settings, verify Supabase URL accessibility

### Issue: "Authentication failed"
**Cause**: Incorrect credentials or expired tokens
**Solution**: Verify credentials, check Supabase auth settings

### Issue: "Data not saving"
**Cause**: Database permissions or RLS issues
**Solution**: Check RLS policies, verify user permissions

### Issue: "Slow performance"
**Cause**: Device limitations or network issues
**Solution**: Check device specs, monitor network speed, clear app cache

## 📝 Test Checklist

### Pre-Testing
- [ ] Flutter environment configured
- [ ] Android devices ready
- [ ] Supabase project set up
- [ ] Test users created
- [ ] APKs built successfully

### During Testing
- [ ] Admin app login works
- [ ] Staff app login works
- [ ] Data syncs between devices
- [ ] All form categories accessible
- [ ] PDF generation starts
- [ ] Error handling works
- [ ] Network issues handled gracefully

### Post-Testing
- [ ] All test scenarios completed
- [ ] Performance benchmarks met
- [ ] Security checks passed
- [ ] Issues documented
- [ ] Feedback collected

## 🔄 Continuous Testing

### Automated Testing
- Unit tests for all services
- Integration tests for database operations
- Widget tests for UI components
- End-to-end tests for workflows

### Manual Testing Schedule
- **Daily**: Core functionality
- **Weekly**: Full workflow testing
- **Monthly**: Performance and security review
- **Before release**: Comprehensive testing

## 📞 Support

### For Development Issues
- Check Flutter documentation
- Review Supabase documentation
- Check GitHub issues
- Contact development team

### For Testing Issues
- Verify test environment setup
- Check device compatibility
- Review test procedures
- Document and report issues

---

**Last Updated**: March 2026
**Version**: 1.0
**Status**: Ready for Production Testing