# Axure to GitHub Pages 自动化部署脚本
# ====================================
# 使用方法：
#   1. 把本脚本放到 Axure 项目目录下（即仓库根目录）
#   2. 在 Axure 中导出 HTML 到仓库下的 "export" 文件夹
#   3. 运行: .\deploy-axure.ps1
# ====================================

# ─── 配置区 ────────────────────────────────────────────
$AXURE_EXPORT_PATH = ".\export"          # Axure 导出的 HTML 目录
$REPO_URL = "https://github.com/zhaolaoshi815/TW-IoT_MobilePhone.git"  # GitHub 仓库地址
$BRANCH = "gh-pages"                     # 部署分支
$COMMIT_MESSAGE = "部署 Axure 原型 - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
# ─────────────────────────────────────────────────────

Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Axure → GitHub Pages 自动部署工具  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 第一步：检查 Axure 导出目录
if (-not (Test-Path $AXURE_EXPORT_PATH)) {
    Write-Host "⚠ 未找到导出目录：$AXURE_EXPORT_PATH" -ForegroundColor Yellow
    Write-Host "  请先在 Axure 中：Publish → Generate HTML Files" -ForegroundColor Yellow
    Write-Host "  将文件导出到 $AXURE_EXPORT_PATH" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ 找到 Axure 导出目录" -ForegroundColor Green

# 第二步：检查 Git
$gitVersion = git --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 未安装 Git，请先安装：https://git-scm.com/" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Git 已安装" -ForegroundColor Green

# 第三步：准备部署目录
$DEPLOY_DIR = "$env:TEMP\axure-deploy-$([System.IO.Path]::GetRandomFileName())"
Write-Host "📦 正在准备部署文件..." -ForegroundColor Yellow

# 尝试克隆 gh-pages 分支
git clone --depth 1 --branch $BRANCH $REPO_URL $DEPLOY_DIR 2>$null
if ($LASTEXITCODE -ne 0) {
    # 分支不存在，创建新的
    New-Item -ItemType Directory -Path $DEPLOY_DIR -Force | Out-Null
    Push-Location $DEPLOY_DIR
    git init
    git checkout -b $BRANCH
    Pop-Location
    Write-Host "  创建新分支 $BRANCH" -ForegroundColor Green
} else {
    Write-Host "  已克隆现有 $BRANCH 分支" -ForegroundColor Green
}

# 清空旧文件（保留 .git）
Push-Location $DEPLOY_DIR
Get-ChildItem -Exclude ".git" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Pop-Location

# 复制 Axure 导出文件
Copy-Item -Path "$AXURE_EXPORT_PATH\*" -Destination $DEPLOY_DIR -Recurse -Force
Write-Host "✅ 已复制 Axure 文件" -ForegroundColor Green

# 创建 .nojekyll 文件
"" | Set-Content -Path "$DEPLOY_DIR\.nojekyll"

# 提交并推送
Push-Location $DEPLOY_DIR
git add -A
$commitOutput = git commit -m $COMMIT_MESSAGE 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "📤 正在推送到 GitHub..." -ForegroundColor Yellow
    git push origin $BRANCH
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 部署成功！" -ForegroundColor Green
    } else {
        Write-Host "❌ 推送失败，请检查网络和权限" -ForegroundColor Red
    }
} else {
    Write-Host "ℹ 没有新变化需要提交" -ForegroundColor Gray
}
Pop-Location

# 清理临时目录
Remove-Item -Path $DEPLOY_DIR -Recurse -Force -ErrorAction SilentlyContinue

# 输出访问链接
$repoName = "TW-IoT_MobilePhone"
Write-Host ""
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🌐 访问地址:" -ForegroundColor Cyan
Write-Host "  https://zhaolaoshi815.github.io/$repoName/" -ForegroundColor White
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 提示：下次只需重新导出 Axure HTML 并再次运行本脚本即可更新" -ForegroundColor Cyan
