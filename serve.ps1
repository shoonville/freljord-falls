$port = 8077
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root on http://localhost:$port/"

# Serve each request on its own thread. The .glb models are several MB each, so on a single
# thread a slow-to-drain client (the WebGL page is busy) would head-of-line-block every other
# request and the page could hang forever on "LOADING ICE...". A small runspace pool lets the
# models download in parallel and keeps one stuck transfer from stalling the rest.
$pool = [runspacefactory]::CreateRunspacePool(1, 8)
$pool.Open()

$handler = {
  param($ctx, $root)
  $types = @{ ".html"="text/html"; ".js"="text/javascript"; ".css"="text/css"; ".glb"="model/gltf-binary"; ".json"="application/json"; ".png"="image/png"; ".jpg"="image/jpeg" }
  try {
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
  } catch { }
}

$active = New-Object System.Collections.ArrayList
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()           # blocks until the next request arrives (fast)
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool
    [void]$ps.AddScript($handler).AddArgument($ctx).AddArgument($root)
    $h = $ps.BeginInvoke()
    [void]$active.Add(@{ ps = $ps; handle = $h })
    # reap finished requests so PowerShell instances don't pile up over a long session
    for ($i = $active.Count - 1; $i -ge 0; $i--) {
      if ($active[$i].handle.IsCompleted) {
        try { $active[$i].ps.EndInvoke($active[$i].handle) } catch {}
        $active[$i].ps.Dispose()
        $active.RemoveAt($i)
      }
    }
  } catch { Write-Host "ERR $_" }
}
