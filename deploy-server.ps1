# ============================================================
# deploy-server.ps1 — 构建并部署到学校服务器
# GitHub Pages 不受影响：它只用 _config.yml 自动构建
# ============================================================
$ErrorActionPreference = "Stop"

# ===== SFTP 上传配置 =====
$ServerUser = "wenb"                                 # ← 填你的 SFTP 用户名
$ServerHost = "www.lamda.nju.edu.cn"
$ServerPath = "/D:/personal_web/wenb/"
# 密码不写在这里，运行时 scp 会提示你输入（更安全）
# ============================================================

# 1. 首次使用先构建 Docker 镜像（约几分钟，只做一次）
if (-not (docker images -q jekyll-site)) {
    Write-Host "首次运行，正在构建 Docker 镜像..." -ForegroundColor Cyan
    docker build -t jekyll-site .
}

# 2. 用 Docker 构建「服务器版本」到 _site/
Write-Host "正在构建网站（服务器版本）..." -ForegroundColor Cyan
docker run --rm -v "${PWD}:/usr/src/app" jekyll-site bundle exec jekyll build --config _config.yml,_config_server.yml

if (-not $?) { Write-Host "构建失败" -ForegroundColor Red; exit 1 }
Write-Host "构建完成 → _site/ 目录" -ForegroundColor Green

# 3. 上传
if ($ServerUser -and $ServerHost -and $ServerPath) {
    Write-Host "正在上传到服务器..." -ForegroundColor Cyan
    scp -r _site/* "${ServerUser}@${ServerHost}:${ServerPath}"
    Write-Host "部署完成！" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "未配置 SSH，请手动上传：" -ForegroundColor Yellow
    Write-Host "  用 FileZilla 等 FTP 工具，把 _site 文件夹【里面的所有内容】"
    Write-Host "  （注意：是 _site 里面的文件，不是 _site 文件夹本身）"
    Write-Host "  上传到服务器上你的子路径目录。"
}
