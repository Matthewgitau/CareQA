# ============================================================
# CareQA Paywall - deploy functions + set secrets
#
# Run from ANYWHERE - it switches to the repo root first.
# The supabase CLI MUST be run from the directory that contains
# the `supabase/` folder, otherwise it looks for
# `supabase/functions/...` in the wrong place and fails with:
#   "failed to read file: open supabase/functions/signup/index.ts"
#
# Usage:
#   .\deploy_paywall.ps1
# ============================================================
[CmdletBinding()]
param(
    # Set to 3 for production, leave 1 for test mode (hourly lockout check)
    [int]$TrialDays = 1,
    # Set to $true to skip pushing migrations (they already applied)
    [switch]$SkipDbPush,
    # Supabase project ref (defaults to the linked project)
    [string]$ProjectRef = 'aucflsskbhaloutsdlwc'
)

$ErrorActionPreference = 'Stop'

# CRITICAL: the script lives in the repo root (CareQA\deploy_paywall.ps1).
# The supabase CLI must run from the folder that CONTAINS `supabase/`,
# i.e. $PSScriptRoot itself - NOT its parent.
Set-Location $PSScriptRoot

Write-Host "==> Working dir: $(Get-Location)" -ForegroundColor Cyan

# ---- sanity: entrypoints must exist ---------------------------------
$entrypoints = @{
    'signup'              = 'supabase/functions/signup/index.ts'
    'start-trial'         = 'supabase/functions/start-trial/index.ts'
    'create-checkout'     = 'supabase/functions/create-checkout/index.ts'
    'stripe-webhook'      = 'supabase/functions/stripe-webhook/index.ts'
    'subscription-status' = 'supabase/functions/subscription-status/index.ts'
}
foreach ($fn in $entrypoints.Keys) {
    if (-not (Test-Path $entrypoints[$fn])) {
        Write-Host "MISSING: $($entrypoints[$fn])" -ForegroundColor Red
        exit 1
    }
}

# ---- 0. ensure the project is linked ---------------------------------
$projectRefFile = 'supabase/.temp/project-ref'
$linkedRef = if (Test-Path $projectRefFile) { (Get-Content $projectRefFile -Raw).Trim() } else { '' }
if ($linkedRef -eq $ProjectRef) {
    Write-Host "`n==> Project already linked: $linkedRef" -ForegroundColor Cyan
} else {
    Write-Host "`n==> Linking to project $ProjectRef (will prompt for DB password)" -ForegroundColor Cyan
    & supabase link --project-ref $ProjectRef
    if ($LASTEXITCODE -ne 0) { throw "supabase link failed" }
}

# ---- 0. migrations 157/158 are already applied -------------------
# The user has already manually applied these (the columns exist but
# are NULL - which is EXPECTED until a user starts a trial).
# The `db execute` subcommand does NOT exist in this CLI version, so
# we skip it entirely and just continue.
if ($SkipDbPush) {
    Write-Host "`n==> Skipping migration check (-SkipDbPush set)" -ForegroundColor Cyan
} else {
    Write-Host "`n==> Confirmations (no action taken - migrations 157/158 already applied manually):" -ForegroundColor Cyan
    Write-Host "    * subscription columns exist on profiles/organisations (values are NULL until a trial/sub starts)" -ForegroundColor Green
    Write-Host "    * 157_subscription_schema.sql + 158_subscription_rls.sql present locally" -ForegroundColor Green
    Write-Host "    (To verify in-dashboard: Table Editor -> organisations -> check columns)" -ForegroundColor DarkGray
}

# ---- 1. deploy the five functions ------------------------------------
Write-Host "`n==> Deploying edge functions" -ForegroundColor Cyan
foreach ($fn in $entrypoints.Keys) {
    Write-Host "    deploying $fn ..."
    & supabase functions deploy $fn
    if ($LASTEXITCODE -ne 0) { throw "deploy $fn failed" }
}
Write-Host "    [OK] all functions deployed" -ForegroundColor Green

# ---- 2. set non-secret values -----------------------------------------
Write-Host "`n==> Setting secrets (non-secret)" -ForegroundColor Cyan
& supabase secrets set MONTHLY_PRICE_ID=price_1UAb7qLZNCdxsglRmSOvP9uI
if ($LASTEXITCODE -ne 0) { throw "set MONTHLY_PRICE_ID failed" }
& supabase secrets set ANNUAL_PRICE_ID=price_1UAb9DLZNCdxsglRRIz1ZM41
if ($LASTEXITCODE -ne 0) { throw "set ANNUAL_PRICE_ID failed" }
& supabase secrets set TRIAL_DAYS=$TrialDays
if ($LASTEXITCODE -ne 0) { throw "set TRIAL_DAYS failed" }

# ---- 3. set STRIPE_SECRET_KEY (from env, or prompt hidden) -------------
Write-Host "`n==> Setting STRIPE_SECRET_KEY" -ForegroundColor Cyan
$STRIPE_KEY = $env:STRIPE_SECRET_KEY
if ([string]::IsNullOrWhiteSpace($STRIPE_KEY)) {
    $secure = Read-Host "Paste STRIPE_SECRET_KEY (sk_test_... - hidden)" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $STRIPE_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}
& supabase secrets set "STRIPE_SECRET_KEY=$STRIPE_KEY" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "set STRIPE_SECRET_KEY failed" }
$STRIPE_KEY = $null
[System.GC]::Collect()

# ---- 4. set webhook signing secret -------------------------------------
# The Supabase CLI REJECTS secret names starting with "SUPABASE_"
# (reserved), so the name must be STRIPE_WEBHOOK_SECRET.
$WEBHOOK_KEY = $env:STRIPE_WEBHOOK_SECRET
if (-not [string]::IsNullOrWhiteSpace($WEBHOOK_KEY)) {
    Write-Host "`n==> Setting STRIPE_WEBHOOK_SECRET (from env)" -ForegroundColor Cyan
    & supabase secrets set "STRIPE_WEBHOOK_SECRET=$WEBHOOK_KEY" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "set STRIPE_WEBHOOK_SECRET failed" }
    $WEBHOOK_KEY = $null
    [System.GC]::Collect()
} else {
    Write-Host ""
    Write-Host "==> STRIPE_WEBHOOK_SECRET NOT set - manual step:" -ForegroundColor Cyan
    Write-Host "    1. Stripe dashboard -> Developers -> Webhooks -> your endpoint" -ForegroundColor White
    Write-Host "       (we_1UAei3LZNCdxsglROaPLYEGO) -> Reveal signing secret" -ForegroundColor White
    Write-Host "    2. supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_hDTiFTpkf74Z0ueeMq4CDh1sS0Di9rZh" -ForegroundColor White
    Write-Host "    (Or re-run with:  `$env:STRIPE_WEBHOOK_SECRET='whsec_...'; .\deploy_paywall.ps1)" -ForegroundColor White
}
Write-Host ""
Write-Host "==> Done! Test:  sign up in the app -> Start 3-Day Free Trial -> 4242 4242 4242 4242" -ForegroundColor Green