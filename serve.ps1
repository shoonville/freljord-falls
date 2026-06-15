$port = 8077
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root on http://localhost:$port/"
$types = @{ ".html"="text/html"; ".js"="text/javascript"; ".css"="text/css"; ".glb"="model/gltf-binary"; ".json"="application/json"; ".png"="image/png"; ".jpg"="image/jpeg" }
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $rel = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrEmpty($rel)) { $rel = "index.html" }
    $path = Join-Path $root $rel
    if (Test-Path $path -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($path).ToLower()
      $ct = $types[$ext]; if (-not $ct) { $ct = "application/octet-stream" }
      $bytes = [System.IO.File]::ReadAllBytes($path)
      $ctx.Response.ContentType = $ct
      $ctx.Response.Headers.Add("Access-Control-Allow-Origin","*")
      $ctx.Response.Headers.Add("Cache-Control","no-store, no-cache, must-revalidate")
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
    $ctx.Response.OutputStream.Close()
  } catch { Write-Host "ERR $_" }
}
