# 改了主页之后怎么部署

## 每次改完内容，按顺序做三件事

### 1. 启动 Docker Desktop

双击桌面 Docker Desktop 图标，等约 1 分钟。

确认启动成功：终端运行 `docker info`，能输出一堆信息 = OK。

### 2. 传学校服务器

在 VS Code 打开本仓库，`` Ctrl+` `` 打开终端（提示符要是 `PS ...>`，如果是 cmd 先输 `powershell` 回车）：

```
.\deploy-server.ps1
```

中途提示 `password:` 输服务器密码（不显示字符，正常）。

看到绿色「部署完成」后，打开 https://www.lamda.nju.edu.cn/wenb/ 检查。

### 3. 同步 GitHub

```
git add .
git commit -m "update"
git push
```

push 前确保 Clash Verge 已打开。

---

## 主页文件在哪

- 首页内容（自我介绍、研究方向、论文列表）：[_pages/about.md](_pages/about.md)
- 个人信息（名字、邮箱、头像、侧边栏）：[_config.yml](_config.yml) 里的 `author` 部分
- 头像图片：替换 [images/profile.png](images/profile.png)

改完保存，再走上面的三步即可。

## 常见报错

| 报错 | 处理 |
|---|---|
| Cannot connect to the Docker daemon | Docker 没启动/没启动完，回第 1 步 |
| git push 报 Failed to connect to 127.0.0.1 | Clash Verge 没开，打开后重新 push |
| sftp Permission denied | 密码输错了，重跑脚本重输 |
