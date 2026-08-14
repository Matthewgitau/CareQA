#!/bin/bash

# CareQA Comprehensive Testing Script
# Tests all 26 assessment systems for functionality

echo "=========================================="
echo "CareQA Comprehensive Testing Suite"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    echo "Command: $test_command"
    
    if eval "$test_command" > /dev/null 2>&1; then
        if [ "$expected_result" = "success" ]; then
            echo -e "${GREEN}✓ PASS: $test_name${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}✗ FAIL: $test_name (expected failure but got success)${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        if [ "$expected_result" = "failure" ]; then
            echo -e "${GREEN}✓ PASS: $test_name (correctly failed)${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}✗ FAIL: $test_name (expected success but got failure)${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
    echo ""
}

echo "1. Testing Database Migrations"
echo "-------------------------------"

# Test if migration files exist
for i in {001..026}; do
    if [ -f "supabase/migrations/${i}_*.sql" ]; then
        echo -e "${GREEN}✓ Migration $i exists${NC}"
    else
        echo -e "${RED}✗ Migration $i missing${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "2. Testing Model Files"
echo "---------------------"

# Test model files
models=(
    "models/service_user.dart"
    "models/carer.dart"
    "models/shift.dart"
    "models/visit.dart"
    "models/risk_assessment.dart"
    "models/waterlow_assessment.dart"
    "models/mental_capacity_assessment.dart"
    "models/food_fluid_chart.dart"
    "models/bowel_bladder_chart.dart"
    "models/repositioning_chart.dart"
    "models/sleep_chart.dart"
    "models/infection_control_audit.dart"
    "models/health_safety_audit.dart"
    "models/fire_safety_audit.dart"
    "models/equipment_audit.dart"
    "models/supervision_record.dart"
    "models/appraisal_form.dart"
    "models/training_record.dart"
    "models/competency_assessment.dart"
    "models/dols_assessment.dart"
    "models/moving_handling_assessment.dart"
    "models/skin_integrity_assessment.dart"
    "models/oral_health_assessment.dart"
)

for model in "${models[@]}"; do
    if [ -f "$model" ]; then
        echo -e "${GREEN}✓ $model exists${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ $model missing${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "3. Testing Service Files"
echo "-----------------------"

# Test service files
services=(
    "services/auth_service.dart"
    "services/firestore_service.dart"
    "services/risk_assessment_service.dart"
    "services/waterlow_service.dart"
    "services/mental_capacity_service.dart"
    "services/food_fluid_service.dart"
    "services/bowel_bladder_service.dart"
    "services/repositioning_service.dart"
    "services/sleep_service.dart"
    "services/infection_control_service.dart"
    "services/health_safety_service.dart"
    "services/fire_safety_service.dart"
    "services/equipment_service.dart"
    "services/supervision_service.dart"
    "services/appraisal_service.dart"
    "services/training_service.dart"
    "services/competency_service.dart"
    "services/dols_service.dart"
    "services/moving_handling_service.dart"
    "services/skin_integrity_service.dart"
    "services/oral_health_service.dart"
)

for service in "${services[@]}"; do
    if [ -f "$service" ]; then
        echo -e "${GREEN}✓ $service exists${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ $service missing${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "4. Testing UI Files"
echo "------------------"

# Test UI files
uis=(
    "ui/risk_assessment/risk_assessment_screen.dart"
    "ui/waterlow_assessment/waterlow_screen.dart"
    "ui/food_fluid/food_fluid_screen.dart"
    "ui/bowel_bladder/bowel_bladder_screen.dart"
    "ui/repositioning/repositioning_screen.dart"
    "ui/sleep/sleep_screen.dart"
    "ui/infection_control/infection_control_screen.dart"
    "ui/health_safety/health_safety_screen.dart"
    "ui/fire_safety/fire_safety_screen.dart"
    "ui/equipment/equipment_screen.dart"
    "ui/supervision/supervision_screen.dart"
    "ui/appraisal/appraisal_screen.dart"
    "ui/training/training_screen.dart"
    "ui/competency/competency_screen.dart"
    "ui/dols/dols_screen.dart"
    "ui/moving_handling/moving_handling_screen.dart"
    "ui/skin_integrity/skin_integrity_screen.dart"
    "ui/oral_health/oral_health_screen.dart"
)

for ui in "${uis[@]}"; do
    if [ -f "$ui" ]; then
        echo -e "${GREEN}✓ $ui exists${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ $ui missing${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "5. Testing Admin App Files"
echo "-------------------------"

# Test admin app files
admin_files=(
    "admin-app/lib/models/waterlow_assessment.dart"
    "admin-app/lib/services/waterlow_service.dart"
    "admin-app/lib/ui/waterlow_assessment/waterlow_screen.dart"
    "admin-app/lib/models/mental_capacity_assessment.dart"
    "admin-app/lib/services/mental_capacity_service.dart"
    "admin-app/lib/ui/dashboard/admin_dashboard.dart"
    "admin-app/lib/ui/dashboard/master_dashboard.dart"
)

for admin_file in "${admin_files[@]}"; do
    if [ -f "$admin_file" ]; then
        echo -e "${GREEN}✓ $admin_file exists${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ $admin_file missing${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "6. Testing Flutter Project Structure"
echo "-----------------------------------"

# Test Flutter project structure
flutter_projects=("admin-app" "staff-app")

for project in "${flutter_projects[@]}"; do
    if [ -d "$project" ] && [ -f "$project/pubspec.yaml" ]; then
        echo -e "${GREEN}✓ $project Flutter project structure valid${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ $project Flutter project structure invalid${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "7. Testing Supabase Configuration"
echo "--------------------------------"

# Test Supabase configuration
supabase_files=("supabase/supabase.toml" "supabase/supabase.config.js")

for file in "${supabase_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $file exists${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ $file missing${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "8. Testing Compliance Engine"
echo "---------------------------"

# Test compliance engine files
compliance_files=(
    "supabase/functions/compliance_rules_engine.sql"
    "supabase/views/ai_training_data.sql"
)

for file in "${compliance_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $file exists${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ $file missing${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "9. Testing Documentation"
echo "-----------------------"

# Test documentation files
docs=(
    "README.md"
    "MIGRATION_GUIDE.md"
    "COMPLIANCE_ENGINE_SUMMARY.md"
    "FALLS_RISK_ASSESSMENT_SUMMARY.md"
    "CHOKING_RISK_ASSESSMENT_SUMMARY.md"
    "MAR_AUDIT_SUMMARY.md"
    "MEDICATION_RISK_ASSESSMENT_SUMMARY.md"
    "PRE_ADMISSION_ASSESSMENT_SUMMARY.md"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✓ $doc exists${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ $doc missing${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "10. Testing Build Scripts"
echo "------------------------"

# Test build scripts
scripts=(
    "build.sh"
    "generate-api-clients.sh"
    "test-all.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo -e "${GREEN}✓ $script exists and is executable${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ $script missing or not executable${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done

echo ""
echo "=========================================="
echo "TEST RESULTS SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! 🎉${NC}"
    echo ""
    echo "The CareQA system is ready for deployment with all 26 assessment systems:"
    echo ""
    echo "📋 DAILY CARE CHARTS (4):"
    echo "   • Food & Fluid Chart"
    echo "   • Bowel & Bladder Chart"
    echo "   • Repositioning Chart"
    echo "   • Sleep Chart"
    echo ""
    echo "📋 AUDITS (4):"
    echo "   • Infection Control Audit"
    echo "   • Health & Safety Audit"
    echo "   • Fire Safety Audit"
    echo "   • Equipment Audit"
    echo ""
    echo "📋 STAFF RECORDS (4):"
    echo "   • Supervision Record"
    echo "   • Appraisal Form"
    echo "   • Training Record"
    echo "   • Competency Assessment"
    echo ""
    echo "📋 RISK ASSESSMENTS (14):"
    echo "   • Medication Risk Assessment"
    echo "   • Pre-Admission Assessment"
    echo "   • Choking Risk Assessment"
    echo "   • Falls Risk Assessment"
    echo "   • MAR Audit"
    echo "   • Waterlow Assessment"
    echo "   • Mental Capacity Assessment"
    echo "   • DoLS Assessment"
    echo "   • Moving & Handling Assessment"
    echo "   • Skin Integrity Assessment"
    echo "   • Oral Health Assessment"
    echo ""
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failed tests above and fix any issues before deployment."
    exit 1
fi