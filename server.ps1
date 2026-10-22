# Lightweight Local Web Server for QuizGenius AI
$port = 8080
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

# Test if port is available
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host " QuizGenius AI Local Web Server is Running!     " -ForegroundColor Green
    Write-Host " URL: http://localhost:$port/                   " -ForegroundColor Yellow
    Write-Host " Root Directory: $root                          " -ForegroundColor Gray
    Write-Host " Press Ctrl+C in terminal to stop the server.   " -ForegroundColor Gray
    Write-Host "=================================================" -ForegroundColor Cyan
} catch {
    Write-Host "Port $port might be in use, trying 8085..." -ForegroundColor Yellow
    $port = 8085
    $listener = New-Object System.Net.HttpListener
    $prefix = "http://localhost:$port/"
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    Write-Host "Server started at http://localhost:$port/" -ForegroundColor Green
}

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $rawUrl = $request.Url.LocalPath
        if ($rawUrl -eq "/" -or $rawUrl -eq "") {
            $rawUrl = "/quizgenius_ai_app.html"
        }

        # Normalize relative path
        $cleanPath = $rawUrl.TrimStart("/\").Replace("/", "\")
        $targetFile = Join-Path $root $cleanPath

        if (-not (Test-Path $targetFile)) {
            $targetFile = Join-Path $root "quizgenius_ai_app.html"
        }

        if (Test-Path $targetFile) {
            $ext = [System.IO.Path]::GetExtension($targetFile).ToLower()
            $mime = $mimeTypes[$ext]
            if (-not $mime) { $mime = "text/html; charset=utf-8" }

            $bytes = [System.IO.File]::ReadAllBytes($targetFile)
            $response.ContentType = $mime
            $response.ContentLength64 = $bytes.Length
            $response.AddHeader("Access-Control-Allow-Origin", "*")
            $response.AddHeader("Cache-Control", "no-cache")
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("File Not Found")
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
        $response.OutputStream.Close()
    } catch {
        # Keep server loop running smoothly
    }
}
