# Local preview of the website at http://localhost:8766 (GitHub Pages serves the same files for real).
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8766/")
$listener.Start()
Write-Host "Serving $root at http://localhost:8766/"
$types = @{ ".html" = "text/html; charset=utf-8"; ".css" = "text/css"; ".svg" = "image/svg+xml"; ".png" = "image/png"; ".jpg" = "image/jpeg" }
while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
    if ($path -eq "") { $path = "index.html" }
    $file = Join-Path $root $path
    if (-not (Test-Path $file -PathType Leaf)) { $file = Join-Path $root "404.html"; $ctx.Response.StatusCode = 404 }
    $bytes = [IO.File]::ReadAllBytes($file)
    $ext = [IO.Path]::GetExtension($file)
    $ctx.Response.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" }
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.Close()
}
