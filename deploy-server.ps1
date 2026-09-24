# ============================================================
# deploy-server.ps1 — 构建并部署到学校服务器
# GitHub Pages 不受影响：它只用 _config.yml 自动构建
# ============================================================
$ErrorActionPreference = "Stop"

# ===== SFTP 上传配置 =====
$ServerUser = "wenb"
$ServerHost = "www.lamda.nju.edu.cn"
$ServerPath = "/D:/personal_web/wenb/"
# 密码不写在这里，运行时 scp 会提示你输入（更安全）
# ============================================================

# 1. 首次使用先构建 Docker 镜像（约几分钟，只做一次）
if (-not (docker images -q jekyll-site)) {
    Write-Host "首次运行，正在构建 Docker 镜像..." -ForegroundColor Cyan
    docker build -t jekyll-site .
    if ($LASTEXITCODE -ne 0) { Write-Host "Docker 镜像构建失败" -ForegroundColor Red; exit 1 }
}

# 2. 用 Docker 构建「服务器版本」到 _site/
Write-Host "正在构建网站（服务器版本）..." -ForegroundColor Cyan
docker run --rm -v "${PWD}:/usr/src/app" jekyll-site bundle exec jekyll build --config _config.yml,_config_server.yml

# 3. 严格校验构建结果：exit code + 关键文件都存在才继续
if ($LASTEXITCODE -ne 0) { Write-Host "构建失败，已中止（服务器内容未改动）" -ForegroundColor Red; exit 1 }
foreach ($f in @("_site\index.html", "_site\assets\css\main.css")) {
    if (-not (Test-Path $f)) { Write-Host "构建产物不完整：缺少 $f，已中止（服务器内容未改动）" -ForegroundColor Red; exit 1 }
}
Write-Host "构建完成并通过校验 → _site/ 目录" -ForegroundColor Green

# 4. 上传：逐文件明确上传（先建目录再传文件，避开 sftp put -r 通配符的平铺 bug）
#    服务器上 /D:/personal_web/wenb/ 里应直接看到 index.html、assets/ 等
Write-Host "正在生成上传清单..." -ForegroundColor Cyan
$siteRoot = (Resolve-Path "_site").Path
$allDirs  = Get-ChildItem -Recurse -Directory "_site"
$allFiles = Get-ChildItem -Recurse -File "_site"

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("lcd _site")
$lines.Add("cd $ServerPath")
foreach ($d in $allDirs) {
    $rel = $d.FullName.Substring($siteRoot.Length + 1).Replace('\','/')
    $lines.Add("-mkdir `"$rel`"")   # - 前缀：目录已存在则忽略错误
}
foreach ($f in $allFiles) {
    $rel = $f.FullName.Substring($siteRoot.Length + 1).Replace('\','/')
    $lines.Add("put `"$rel`" `"$rel`"")
}
$lines.Add("exit")
$sftpCmds = $lines -join "`n"
Write-Host ("共 {0} 个文件、{1} 个目录待上传" -f $allFiles.Count, $allDirs.Count) -ForegroundColor Cyan

Write-Host "正在上传到服务器（会提示输入密码）..." -ForegroundColor Cyan

$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$output = ($sftpCmds | sftp "${ServerUser}@${ServerHost}" 2>&1 | Out-String)
$ErrorActionPreference = $prevEAP

# "Couldn't create directory" 是目录已存在的正常提示，不算错误（put 是否成功由下面的计数校验）
$realErrors = $output -split "`r?`n" | Where-Object {
    $_ -match "Permission denied|Connection closed|No such file|Couldn't" -and
    $_ -notmatch "Couldn't create directory"
}
if ($realErrors) {
    Write-Host $output
    Write-Host "上传失败，请把上面的输出发给我排查" -ForegroundColor Red
    Write-Host "常见原因：密码错误 / 无写入权限 / 路径不存在" -ForegroundColor Yellow
    exit 1
}
$uploaded = ([regex]::Matches($output, "Uploading")).Count
if ($uploaded -lt $allFiles.Count) {
    Write-Host $output
    Write-Host ("只上传了 {0}/{1} 个文件，请把输出发给我排查" -f $uploaded, $allFiles.Count) -ForegroundColor Red
    exit 1
}
Write-Host ("已上传 {0}/{1} 个文件" -f $uploaded, $allFiles.Count) -ForegroundColor Green

Write-Host ""
Write-Host "部署完成！请打开 https://www.lamda.nju.edu.cn/wenb/ 验证" -ForegroundColor Green
Write-Host "再随便点开一篇文章，确认样式和图片正常加载" -ForegroundColor Green
