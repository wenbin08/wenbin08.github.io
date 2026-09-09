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

# 4. 上传：_site/. 表示「目录内的全部内容」，会原样铺到 $ServerPath 下
#    服务器上 /D:/personal_web/wenb/ 里应直接看到 index.html、assets/ 等
Write-Host "正在上传到服务器（会提示输入密码）..." -ForegroundColor Cyan
scp -r "_site/." "${ServerUser}@${ServerHost}:${ServerPath}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "上传失败，请把上面的报错发给我排查" -ForegroundColor Red
    Write-Host "常见原因：密码错误 / 无写入权限 / 路径不存在" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "部署完成！请打开 https://www.lamda.nju.edu.cn/wenb/ 验证" -ForegroundColor Green
Write-Host "再随便点开一篇文章，确认样式和图片正常加载" -ForegroundColor Green
