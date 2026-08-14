# CareQA Amendments Tracker

## Batch 1 - Database Schema & Form Fixes

### Critical Issues (P0)
| # | Screen | Issue | Status | Assigned To |
|---|--------|-------|--------|-------------|
| 1 | Falls Risk Assessment | Form not working | ✅ Fixed | - |
| 2 | Add New User Page | Dummy page | ✅ Fixed | - |
| 3 | Shifts Screen | Plus button shows "coming soon" | ✅ Fixed | - |
| 4 | Visits Screen | Spinning wheel, no buttons | ✅ Fixed | - |
| 5 | Drivers App | Coming Soon (not linked) | ✅ Fixed | - |
| 6 | Waterlow Assessments | Dummy page, add button broken | ✅ Fixed | - |
| 7 | Medication Risk Assessment | Add button doesn't show service user picker | ✅ Fixed | - |
| 8 | Risk Assessment Screen | Missing links to all risk assessments | ✅ Fixed | - |
| 9 | RESPECT Form | Upload not working | ✅ Fixed | - |
| 10 | Fire Hazard Assessment | Form error: initialValue vs controller | ✅ Fixed | - |

### Database Table Issues
| # | Screen | Error | Missing Table | Status |
|---|--------|-------|---------------|--------|
| 11 | COSHH Assessments | Table not found | coshh_risk_assessments | ✅ Verified - Table exists (migration 031) |
| 12 | Incontinence Assessment | UI overflow | N/A (UI fix) | ✅ Fixed - Used CheckboxListTile |
| 13 | Supplier Register | Table not found | suppliers | ✅ Verified - Table exists (migration 051) |
| 14 | Catheter Care | Wrong table reference | N/A (fix reference) | ✅ Verified - Service uses correct table |
| 15 | Epilepsy Risk | Wrong table reference | N/A (fix reference) | ✅ Verified - Service uses correct table |
| 16 | Diabetes Risk | Wrong table reference | N/A (fix reference) | ✅ Verified - Service uses correct table |
| 17 | Self Harm | Wrong table reference | N/A (fix reference) | ✅ Verified - Service uses correct table |
| 18 | Activity Risk | DateTime encoding error | N/A (fix JSON) | ✅ Fixed - Changed toIso8601String() |
| 19 | Bed Railing | Wrong table reference | N/A (fix reference) | ✅ Verified - Service uses correct table |
| 20 | Challenging Behaviour | Wrong table reference | N/A (fix reference) | ✅ Verified - Service uses correct table |

## Batch 2 - Pending (to be added)

## Fix Log
| Date | Fix | Files Modified |
|------|-----|----------------|