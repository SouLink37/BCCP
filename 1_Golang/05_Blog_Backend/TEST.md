# 博客后端 API 测试文档

## 📝 目录
- [环境准备](#环境准备)
- [快速测试表](#快速测试表)
- [详细测试步骤](#详细测试步骤)
- [测试检查清单](#测试检查清单)
- [常见问题排查](#常见问题排查)
- [测试工具](#测试工具)

---

## 🔧 环境准备

### 前置要求
1. **MySQL 数据库已启动**
   ```bash
   mysql -u root -p -e "SELECT 1;"
   ```

2. **Go 环境配置**
   ```bash
   go version  # 确保 Go 版本 >= 1.18
   ```

3. **依赖安装**
   ```bash
   cd /home/soulink/workspace/BCCP/1_Golang/05_Blog_Backend
   go mod download
   ```

### 配置文件

创建 `.env` 文件在项目根目录：

```env
DB_USER=root
DB_PASSWORD=
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=blog_backend
SERVER_PORT=:8080
```

### 启动应用

```bash
cd /home/soulink/workspace/BCCP/1_Golang/05_Blog_Backend
go run main.go
```

**预期输出：**
```
2026/01/03 12:23:41 Config load successfully:
DBHost: 127.0.0.1
DBPort: 3306
DBName: blog_backend
ServerPort: :8080
2026/01/03 12:23:41 Database connect successfully.
2026/01/03 12:23:41 Database initialized.
[GIN-debug] Listening and serving HTTP on :8080
```

---

## 📋 快速测试表

| 序号 | 功能 | 方法 | URL | 认证 | 关键点 |
|------|------|------|-----|------|--------|
| 1 | 健康检查 | GET | `/health` | ❌ | 验证服务运行 |
| 2 | 用户注册 | POST | `/api/auth/register` | ❌ | 返回 token，密码加密 |
| 3 | 用户登录 | POST | `/api/auth/login` | ❌ | 返回 token，保存用于后续请求 |
| 4 | 获取所有文章 | GET | `/api/posts` | ❌ | 初始为空数组 |
| 5 | 创建文章 | POST | `/api/posts` | ✅ | user_id 自动关联 |
| 6 | 获取单篇文章 | GET | `/api/posts/{id}` | ❌ | 包含评论列表 |
| 7 | 更新文章 | PUT | `/api/posts/{id}` | ✅ | 仅文章作者可操作 |
| 8 | 删除文章 | DELETE | `/api/posts/{id}` | ✅ | 仅文章作者可操作 |
| 9 | 创建评论 | POST | `/api/posts/{id}/comments` | ✅ | user_id 和 post_id 自动关联 |
| 10 | 获取评论列表 | GET | `/api/posts/{id}/comments` | ❌ | 返回该文章的所有评论 |

---

## 📘 详细测试步骤

### 步骤 1️⃣：健康检查

```
请求方法: GET
URL: http://localhost:8080/health
```

**响应结果 (200 OK):**
```json
{
    "message": "Blog API is running",
    "status": "ok"
}
```

---

### 步骤 2️⃣：用户注册

```
请求方法: POST
URL: http://localhost:8080/api/auth/register
Content-Type: application/json
```

**请求体：**
```json
{
  "username": "user1",
  "email": "user@example.com",
  "password": "12345678"
}
```

**响应结果 (200 OK):**
```json
{
    "code": 200,
    "message": "Registration successful",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySUQiOjEsIlVzZXJuYW1lIjoidXNlcjEiLCJleHAiOjE3Njc1MDM4NjYsImlhdCI6MTc2NzQxNzQ2Nn0.oEGFSSDKnw6P8M5AyXgWbUX6jHFRvPRrPm4LPUQzU_I",
        "user": {
            "id": 1,
            "username": "user1",
            "email": "user@example.com",
            "post_count": 0
        }
    }
}
```

**✅ 验证点：**
- 用户成功创建
- 返回有效的 JWT token
- 密码被加密存储（响应中不显示原始密码）

**❌ 错误情况：**
- 用户名重复 → 409 Conflict
- 邮箱重复 → 409 Conflict
- 缺少必填字段 → 400 Bad Request

---

### 步骤 3️⃣：用户登录

```
请求方法: POST
URL: http://localhost:8080/api/auth/login
Content-Type: application/json
```

**请求体：**
```json
{
  "username": "user1",
  "password": "12345678"
}
```

**响应结果 (200 OK):**
```json
{
    "code": 200,
    "message": "Login successful",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySUQiOjEsIlVzZXJuYW1lIjoidXNlcjEiLCJleHAiOjE3Njc1MDM4ODYsImlhdCI6MTc2NzQxNzQ4Nn0.J5C7sqBoOJHtyrbUbXVW1etMsdUeoFUNRbWi57-2868",
        "user": {
            "id": 1,
            "username": "user1",
            "email": "user@example.com",
            "post_count": 0
        }
    }
}
```

**⚠️ 重要：保存返回的 token，后续需要认证的请求都需要用到！**

```
保存的 token：
Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySUQiOjEsIlVzZXJuYW1lIjoidXNlcjEiLCJleHAiOjE3Njc1MDM4ODYsImlhdCI6MTc2NzQxNzQ4Nn0.J5C7sqBoOJHtyrbUbXVW1etMsdUeoFUNRbWi57-2868
```

**❌ 错误情况：**
- 用户名不存在 → 401 Unauthorized
- 密码错误 → 401 Unauthorized

---

### 步骤 4️⃣：获取所有文章

```
请求方法: GET
URL: http://localhost:8080/api/posts
```

**响应结果 (200 OK):**
```json
{
  "code": 200,
  "message": "Get all posts successfully",
  "data": []
}
```

**📝 注意：** 初始时返回空数组，因为还没有创建文章

---

### 步骤 5️⃣：创建文章

```
请求方法: POST
URL: http://localhost:8080/api/posts
Content-Type: application/json
Authorization: Bearer [你的token]
```

**请求体：**
```json
{
  "title": "我的第一篇文章",
  "content": "这是文章的内容，可以包含很多信息。"
}
```

**响应结果 (200 OK):**
```json
{
    "code": 200,
    "message": "Post created successfully",
    "data": {
        "id": 1,
        "title": "我的第一篇文章",
        "content": "这是文章的内容，可以包含很多信息。",
        "user_id": 1,
        "created_at": "2026-01-03T13:22:58.941+08:00",
        "updated_at": "2026-01-03T13:22:58.941+08:00"
    }
}
```

**✅ 验证点：**
- user_id 正确关联到当前登录用户 ✓
- 时间戳自动生成 ✓
- 返回完整的文章数据 ✓

**❌ 错误情况：**
- 无 Authorization header → 401
- 无效的 token → 401
- Token 格式错误（不以 Bearer 开头） → 401
- 缺少必填字段 → 400

---

### 步骤 6️⃣：获取单篇文章

```
请求方法: GET
URL: http://localhost:8080/api/posts/1
```

**响应结果 (200 OK):**
```json
{
    "code": 200,
    "message": "Post fetched successfully",
    "data": {
        "id": 1,
        "title": "我的第一篇文章",
        "content": "这是文章的内容，可以包含很多信息。",
        "user_id": 1,
        "created_at": "2026-01-03T13:22:58.941+08:00",
        "updated_at": "2026-01-03T13:22:58.941+08:00"
    }
}
```

**✅ 验证点：**
- 返回文章完整信息 ✓
- comments 字段初始为空数组 ✓

**❌ 错误情况：**
- 文章不存在（ID=999） → 404 Not Found

---

### 步骤 7️⃣：创建评论

```
请求方法: POST
URL: http://localhost:8080/api/posts/1/comments
Content-Type: application/json
Authorization: Bearer [你的token]
```

**请求体：**
```json
{
  "content": "这是一条很不错的评论！"
}
```

**响应结果 (200 OK):**
```json
{
    "code": 200,
    "message": "Comment created successfully",
    "data": {
        "id": 1,
        "content": "这是一条很不错的评论！",
        "commenter_id": 1,
        "post_id": 1,
        "created_at": "2026-01-03T13:30:38.394+08:00"
    }
}
```

**✅ 验证点：**
- user_id 正确关联到当前登录用户 ✓
- post_id 正确关联到指定文章 ✓

---

### 步骤 8️⃣：获取评论列表

```
请求方法: GET
URL: http://localhost:8080/api/posts/1/comments
```

**响应结果 (200 OK):**
```json
{
    "code": 200,
    "message": "Comments fetched successfully",
    "data": [
        {
            "id": 1,
            "content": "这是一条很不错的评论！",
            "commenter_id": 1,
            "post_id": 1,
            "created_at": "2026-01-03T13:30:38.394+08:00"
        },
        {
            "id": 2,
            "content": "这是一条很不错的评论2！",
            "commenter_id": 1,
            "post_id": 1,
            "created_at": "2026-01-03T13:32:21.428+08:00"
        }
    ]
}
```

---

### 步骤 9️⃣：获取文章详情（验证评论）

```
请求方法: GET
URL: http://localhost:8080/api/posts/1
```

**响应结果 (200 OK):**
```json
{
    "code": 200,
    "message": "Post fetched successfully",
    "data": {
        "id": 1,
        "title": "我的第一篇文章",
        "content": "这是文章的内容，可以包含很多信息。",
        "user_id": 1,
        "user": {
            "id": 1,
            "username": "user1",
            "email": "user@example.com",
            "post_count": 1
        },
        "comments": [
            {
                "id": 1,
                "content": "这是一条很不错的评论！",
                "commenter_id": 1,
                "post_id": 1,
                "created_at": "2026-01-03T13:30:38.394+08:00"
            },
            {
                "id": 2,
                "content": "这是一条很不错的评论2！",
                "commenter_id": 1,
                "post_id": 1,
                "created_at": "2026-01-03T13:32:21.428+08:00"
            }
        ],
        "created_at": "2026-01-03T13:22:58.941+08:00",
        "updated_at": "2026-01-03T13:22:58.941+08:00"
    }
}
```

**✅ 验证点：**
- 文章详情包含该文章的所有评论 ✓

---

### 步骤 🔟：更新文章

```
请求方法: PUT
URL: http://localhost:8080/api/posts/1
Content-Type: application/json
Authorization: Bearer [你的token]
```

**请求体：**
```json
{
  "title": "我的第一篇文章 - 已更新",
  "content": "这是更新后的文章内容。"
}
```

**响应结果 (200 OK):**
```json
{
    "code": 200,
    "message": "Post updated successfully",
    "data": {
        "id": 1,
        "title": "我的第一篇文章 - 已更新",
        "content": "这是更新后的文章内容。",
        "user_id": 1,
        "user": {
            "id": 1,
            "username": "user1",
            "email": "user@example.com",
            "post_count": 1
        },
        "created_at": "2026-01-03T13:22:58.941+08:00",
        "updated_at": "2026-01-03T14:01:22.903+08:00"
    }
}
```

**❌ 错误情况：**
- 无有效 token → 401
- 非文章作者操作 → 403 Forbidden
- 文章不存在 → 404

---

### 步骤 1️⃣1️⃣：删除文章

```
请求方法: DELETE
URL: http://localhost:8080/api/posts/1
Authorization: Bearer [你的token]
```

**响应结果 (200 OK):**
```json
{
  "code": 200,
  "message": "Post deleted successfully"
}
```

**验证删除成功，再次获取该文章：**

```
请求方法: GET
URL: http://localhost:8080/api/posts/1
```

**响应结果 (404):**
```json
{
  "code": 404,
  "message": "Post not found"
}
```

