param([string]$env = "dev")

$targetFile = ".env"
$logFile = "env_oscar.log"
$pgServiceName = "postgresql-x64-13"   # adjust this to match your installed Postgres service name

Write-Host "`n🔧 Running switch to oscar with env = '$env'"

# In Oscar sandbox, we only have one .env file.
if (!(Test-Path $targetFile)) {
    Write-Error "Missing $targetFile. Aborting."
    exit 1
}

# Log the switch
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content $logFile "[$timestamp] Using environment '$env' with $targetFile"

# --- NEW: Shut down local Postgres service if running ---
Write-Host "`n🛑 Checking for local PostgreSQL service ($pgServiceName)..."
try {
    $pgService = Get-Service -Name $pgServiceName -ErrorAction SilentlyContinue
    if ($pgService -and $pgService.Status -eq "Running") {
        Write-Host "⚠️ Local PostgreSQL service is running on port 5432. Stopping it safely..."
        Stop-Service -Name $pgServiceName -Force
        Write-Host "✅ PostgreSQL service stopped. Port 5432 is now free for Docker."
        Add-Content $logFile "[$timestamp] Stopped local PostgreSQL service $pgServiceName"
    } else {
        Write-Host "ℹ️ PostgreSQL service not running or not found. No action needed."
    }
} catch {
    Write-Warning "Could not check or stop PostgreSQL service: $($_.Exception.Message)"
}

# Shut down any existing Oscar containers
Write-Host "`n🧹 Shutting down any existing Oscar containers..."
docker compose down --remove-orphans

# Rebuild containers
Write-Host "`n🚧 Rebuilding containers with fresh environment..."
docker compose build --no-cache

# Start Docker Compose
Write-Host "`n🚀 Starting Docker Compose for Oscar app ($env)..."
docker compose up