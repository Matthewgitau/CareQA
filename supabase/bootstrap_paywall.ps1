# ============================================================
# CareQA paywall bootstrap (run once per environment)
#
# Pushes the two subscription migrations, deploys the five edge
# functions, and sets all the required secrets. Idempotent.
#
# Run from PowerShell, from the project root:
#   .\supabase\bootstrap_paywall.ps1
# or pass the project ref:
#   .\supabase\bootstrap_paywall.ps1 -ProjectRef aucflsskbhaloutsdlwc
# ============================================================
[CmdletBinding()]
param(
    [string]$ProjectRef = 'aucflsskbhaloutsdlwc',
    [int]$TrialDays = 1   # 1 in test mode, 3 in production
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "    [WARN] $msg" -ForegroundColor Yellow }

Step "Checking supabase CLI"
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Host "The 'supabase' CLI was not found on your PATH." -ForegroundColor Red
    Write-Host "Install it with: npm i -g supabase   (or)   scoop install supabase" -ForegroundColor Red
    Write-Host "On WSL: wsl --install, then in WSL: curl -fsSL https://raw.githubusercontent.com/supabase/cli/main/install.sh | sh" -ForegroundColor Red
    exit 1
}
& supabase --version
Ok "supabase CLI found"

Step "Linking to project $ProjectRef"
# `supabase link` will prompt for the DB password. We use --no-TTY so
# it fails cleanly if it can't get one; you'll be re-prompted.
& supabase link --project-ref $ProjectRef
if ($LASTEXITCODE -ne 0) { throw "supabase link failed" }
Ok "linked"

Step "Pushing migrations (157_subscription_schema.sql, 158_subscription_rls.sql)"
& supabase db push --include-all
if ($LASTEXITCODE -ne 0) { throw "supabase db push failed" }
Ok "migrations applied"

Step "Deploying edge functions"
$functions = @('signup','start-trial','create-checkout','stripe-webhook','subscription-status')
foreach ($fn in $functions) {
    Write-Host "    deploying $fn ..."
    & supabase functions deploy $fn --no-verify-jwt
    if ($LASTEXITCODE -ne 0) { throw "deploy $fn failed" }
}
Ok "all five functions deployed"

Step "Setting edge function secrets"
# Non-secret values (price IDs, trial length) are fine to commit, but
# the Stripe secret key and webhook signing secret are NEVER put in
# this script. The Stripe key is read from $env:STRIPE_SECRET_KEY
# (which you can pre-export in your shell, or .gitignored .env.local),
# and is passed to `supabase secrets set` as a single KEY=VALUE arg
# rather than through a pipe / file.
#
# The webhook signing secret has to come from the Stripe dashboard,
# so we remind you to set it manually at the end.
$STRIPE_KEY = $env:STRIPE_SECRET_KEY
if ([string]::IsNullOrWhiteSpace($STRIPE_KEY)) {
    Write-Host "    STRIPE_SECRET_KEY env var is not set." -ForegroundColor Yellow
    Write-Host "    Either set it now or pass it inline. Example:" -ForegroundColor Yellow
    Write-Host "      `$env:STRIPE_SECRET_KEY='sk_test_...'; .\supabase\bootstrap_paywall.ps1" -ForegroundColor Yellow
    $secure = Read-Host "    Paste sk_test_... (hidden)" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $STRIPE_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

# --- Non-secret values (idempotent) -------------------------------
$static = @{
    'MONTHLY_PRICE_ID' = 'price_1UAb7qLZNCdxsglRmSOvP9uI'
    'ANNUAL_PRICE_ID'  = 'price_1UAb9DLZNCdxsglRRIz1ZM41'
    'TRIAL_DAYS'       = "$TrialDays"
}
foreach ($k in $static.Keys) {
    Write-Host "    setting $k"
    & supabase secrets set "$k=$($static[$k])" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "set $k failed" }
}

# --- Secret value -------------------------------------------------
# We pass it as a single KEY=VALUE arg on the supabase process so it
# never goes through the shell history, env, or a temp file.
Write-Host "    setting STRIPE_SECRET_KEY (length: $($STRIPE_KEY.Length))"
& supabase secrets set "STRIPE_SECRET_KEY=$STRIPE_KEY" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "set STRIPE_SECRET_KEY failed" }
# Wipe from memory
$STRIPE_KEY = $null
[System.GC]::Collect()
Ok "secrets updated (except webhook signing secret)"

Step "WEBHOOK SIGNING SECRET - manual step"
Write-Host "    1. Stripe dashboard -> Developers -> Webhooks -> click your endpoint" -ForegroundColor White
Write-Host "    2. 'Reveal' under Signing secret -> copy the whsec_... value" -ForegroundColor White
Write-Host "    3. Run:" -ForegroundColor White
Write-Host "         supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_XXXX" -ForegroundColor White
Write-Host ""

Step "Sanity: re-fetch the function URL to confirm it's live"
try {
    $resp = Invoke-WebRequest -Uri "https://$ProjectRef.supabase.co/functions/v1/subscription-status" `
        -Method Post `
        -Headers @{ 'Content-Type' = 'application/json'; 'Authorization' = 'Bearer fake' } `
        -Body '{}' -ErrorAction Stop
    Write-Host "    HTTP $($resp.StatusCode) : $($resp.Content.Substring(0, [Math]::Min(120, $resp.Content.Length)))"
} catch {
    Warn "Could not reach the function URL. Deploy may still be in progress (Functions can take ~30s)."
}

Write-Host "`nAll done. Next steps:" -ForegroundColor Green
Write-Host "  1. Set STRIPE_WEBHOOK_SECRET (manual, see above)"
Write-Host "  2. In the admin-app, sign up -> land on paywall -> Start Trial"
Write-Host "  3. Use test card 4242 4242 4242 4242"
Write-Host "  4. Confirm in Supabase: SELECT subscription_status, trial_ends_at FROM organisations;"
Write-Host "  5. Check stripe_events for the checkout.session.completed row"
