# 工具函数与用户认证指南

## 🎯 目标

本文档详细说明 `utils` 文件夹中的三个工具文件如何工作，以及它们在用户认证与授权中的作用。

---

## 📁 Utils 文件结构

```
utils/
├── password.go   # 密码加密和验证工具
├── jwt.go        # JWT Token 生成和验证工具
└── response.go   # 统一格式的 JSON 响应工具
```

---

## 🔐 1. password.go - 密码工具

### 概述

处理密码的加密和验证，确保用户密码的安全性。

### 密码处理流程

```
明文密码（不安全）
    ↓
bcrypt 加密（单向）
    ↓
哈希值（安全，无法反推）
    ↓
存储到数据库
```

### HashPassword 函数

**功能：** 将明文密码加密成哈希值

**输入：**
```go
"123456"  // 用户输入的明文密码
```

**输出：**
```
$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36aiYjFm
```

**工作原理：**
1. 接收明文密码字符串
2. 使用 bcrypt 算法加密
3. 返回加密后的哈希值和可能的错误

**返回值：**
```go
hashedPassword, err := utils.HashPassword("123456")
// hashedPassword: 加密后的哈希值
// err: 加密过程中的错误（如果有）
```

**为什么需要？**
- ❌ 数据库中不能存明文密码（太危险）
- ✅ bcrypt 是单向加密（无法从哈希值反推出密码）
- ✅ 即使数据库被黑客拿到，密码仍然是安全的

**什么时候用？**
- 用户注册时
- 用户修改密码时

**代码示例：**
```go
// 用户注册时
hashedPassword, err := utils.HashPassword(req.Password)
if err != nil {
    utils.Error(c, http.StatusInternalServerError, "password hashing failed")
    return
}

user := models.User{
    Username: req.Username,
    Email:    req.Email,
    Password: hashedPassword,  // 存储哈希值，不是明文
}
h.DB.Create(&user)
```

---

### CheckPassword 函数

**功能：** 验证用户输入的密码是否与数据库中的哈希值匹配

**输入：**
```go
hashedPassword: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36aiYjFm"  // 数据库中的哈希值
password:       "123456"                                                      // 用户输入的密码
```

**输出：**
```go
true   // 密码正确
false  // 密码错误
```

**工作原理：**
1. 接收数据库中的哈希值和用户输入的明文密码
2. 使用 bcrypt 的比对算法验证
3. 返回是否匹配的布尔值

**为什么需要？**
- ❌ 不能直接比对 `输入密码 == 数据库密码`（因为数据库存的是哈希值）
- ✅ 需要用 bcrypt 的专用比对算法来验证
- ✅ 防止密码泄露

**什么时候用？**
- 用户登录时

**代码示例：**
```go
// 用户登录时
var user models.User
h.DB.Where("username = ?", req.Username).First(&user)

// 验证密码
if !utils.CheckPassword(user.Password, req.Password) {
    utils.Error(c, http.StatusUnauthorized, "invalid username or password")
    return
}

// 密码正确，继续处理（生成 Token 等）
```

---

## 🔑 2. jwt.go - JWT Token 工具

### 概述

处理 JWT Token 的生成和验证，实现用户身份认证。

### 什么是 JWT？

**JWT = JSON Web Token**

JWT 是一种用户身份凭证，用来证明"你是谁"和"你有什么权限"。

### JWT 工作流程

```
1. 用户登录
   用户名 + 密码 → 验证成功
   
2. 服务器生成 Token
   包含：用户ID、签发时间、过期时间、签名
   
3. 返回给客户端
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   
4. 客户端存储 Token
   保存在浏览器或 App 的本地存储中
   
5. 后续请求都带上 Token
   Header: Authorization: Bearer [Token]
   
6. 服务器验证 Token
   ✅ Token 有效且未过期 → 允许操作
   ❌ Token 无效或过期 → 拒绝请求，返回 401
```

### JWT 的三个部分

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U
^                                       ^                                    ^
1. Header（头部）                     2. Payload（负载）                   3. Signature（签名）
说明这是 JWT                         包含用户信息和声明              用密钥生成的签名（防止篡改）
使用 HS256 算法                      如：{"UserID": 1}
```

---

### Claims 结构体

**功能：** 定义 JWT Token 中包含的信息

**字段：**
```go
type Claims struct {
    UserID uint              // 用户ID
    RegisteredClaims        // JWT 标准声明
        ExpiresAt           // 过期时间
        IssuedAt            // 签发时间
        ...
}
```

**包含的信息：**
- `UserID` - 用户的唯一标识
- `ExpiresAt` - Token 何时过期（通常 24 小时后）
- `IssuedAt` - Token 何时签发（现在）

---

### GenerateToken 函数

**功能：** 生成一个 JWT Token

**输入：**
```go
userID: 1  // 用户ID
```

**输出：**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0...
```

**工作原理：**
1. 创建 Claims 结构体，包含用户ID和时间信息
2. 使用 HS256 算法和密钥生成签名
3. 返回完整的 Token 字符串

**返回值：**
```go
token, err := utils.GenerateToken(user.ID)
// token: 生成的 JWT Token 字符串
// err:   生成过程中的错误（如果有）
```

**Token 中包含的信息：**
```
{
    "user_id": 1,
    "exp": 1703126400,      // Unix 时间戳，24小时后
    "iat": 1703040000,      // Unix 时间戳，现在
    "alg": "HS256"          // 使用的算法
}
```

**什么时候用？**
- 用户登录成功后
- 返回给客户端，前端存储并在后续请求中使用

**代码示例：**
```go
// 用户登录成功后
token, err := utils.GenerateToken(user.ID)
if err != nil {
    utils.Error(c, http.StatusInternalServerError, "token generation failed")
    return
}

// 返回 Token 给客户端
utils.Success(c, http.StatusOK, "login successful", gin.H{
    "token": token,
    "user": gin.H{
        "id":       user.ID,
        "username": user.Username,
    },
})
```

---

### ValidateToken 函数

**功能：** 验证收到的 Token 是否有效

**输入：**
```go
"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."  // 客户端发来的 Token
```

**输出：**
```go
&Claims{UserID: 1, ...}  // Token 中的信息
nil                       // 如果有效
```

或者：
```go
nil                       // 如果无效
errors.New("invalid token")  // 错误信息
```

**验证内容：**
1. ✅ 签名是否正确（Token 是否被篡改）
2. ✅ Token 是否过期

**工作原理：**
1. 接收 Token 字符串
2. 使用密钥验证签名
3. 检查过期时间
4. 如果都没问题，返回 Claims（包含用户ID）
5. 如果有问题，返回错误

**什么时候用？**
- 处理受保护的接口（如创建文章、删除评论）时
- 中间件中验证用户身份

**代码示例：**
```go
// 中间件中验证 Token
func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 获取 Authorization header
        authHeader := c.GetHeader("Authorization")
        
        // 提取 Token（去掉 "Bearer " 前缀）
        tokenString := strings.TrimPrefix(authHeader, "Bearer ")
        
        // 验证 Token
        claims, err := utils.ValidateToken(tokenString)
        if err != nil {
            // Token 无效或过期
            c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
            c.Abort()
            return
        }
        
        // Token 有效，将用户ID存入上下文
        c.Set("userID", claims.UserID)
        c.Next()  // 继续处理请求
    }
}
```

---

## 📤 3. response.go - 响应工具

### 概述

让所有 API 响应格式统一，便于客户端处理。

### 为什么需要统一格式？

**不统一的情况（混乱）：**
```json
// 接口1 的响应
{"user_id": 1, "name": "Alice"}

// 接口2 的响应
{"success": true, "data": {...}}

// 接口3 的响应
{"error": "not found"}
```

**统一的情况（清晰）：**
```json
// 所有接口都是这个格式
{
    "code": 200,
    "message": "operation successful",
    "data": {...}
}
```

### Response 结构体

**结构：**
```go
type Response struct {
    Code    int         // HTTP 状态码或自定义业务码
    Message string      // 响应消息
    Data    interface{} // 响应数据（可以是任何类型）
}
```

**字段说明：**
- `Code` - 状态码（200 成功、404 未找到、401 未授权等）
- `Message` - 人类可读的消息（如"创建成功"、"用户不存在"）
- `Data` - 实际数据（如用户信息、文章列表等）

---

### Success 函数

**功能：** 返回成功响应

**输入：**
```go
c          // Gin 上下文
code       // HTTP 状态码（如 200、201）
message    // 成功消息（如"创建成功"）
data       // 返回的数据（如用户对象、文章列表等）
```

**输出：**
```json
{
    "code": 200,
    "message": "创建成功",
    "data": {
        "id": 1,
        "username": "alice"
    }
}
```

**什么时候用？**
- 接口成功时

**代码示例：**
```go
// 用户注册成功
utils.Success(c, http.StatusCreated, "registration successful", gin.H{
    "id":       user.ID,
    "username": user.Username,
})

// 获取文章成功
utils.Success(c, http.StatusOK, "success", posts)

// 创建文章成功
utils.Success(c, http.StatusCreated, "post created successfully", post)
```

---

### Error 函数

**功能：** 返回错误响应

**输入：**
```go
c       // Gin 上下文
code    // HTTP 错误码（如 404、401、500）
message // 错误消息（如"用户不存在"、"未授权"）
```

**输出：**
```json
{
    "code": 404,
    "message": "user not found"
}
```

**常见的 HTTP 状态码：**
- `400 Bad Request` - 请求格式错误
- `401 Unauthorized` - 未授权（需要登录）
- `403 Forbidden` - 禁止访问（权限不足）
- `404 Not Found` - 资源不存在
- `409 Conflict` - 冲突（如用户名已存在）
- `500 Internal Server Error` - 服务器错误

**什么时候用？**
- 接口失败时

**代码示例：**
```go
// 用户不存在
utils.Error(c, http.StatusUnauthorized, "invalid username or password")

// 用户未授权
utils.Error(c, http.StatusUnauthorized, "missing token")

// 文章不存在
utils.Error(c, http.StatusNotFound, "post not found")

// 权限不足
utils.Error(c, http.StatusForbidden, "only author can update this post")

// 用户名已存在
utils.Error(c, http.StatusConflict, "username already exists")
```

---

## 🔄 实际应用场景

### 场景 1: 用户注册

```
客户端请求
    ↓
POST /api/auth/register
Body: {
    "username": "alice",
    "email": "alice@example.com",
    "password": "123456"
}
    ↓
服务器处理
    1. 验证字段是否为空 (password.go 中的 HashPassword)
    2. 检查用户名是否已存在
    3. 使用 password.HashPassword("123456") 加密密码
    4. 保存到数据库
    ↓
返回响应 (response.go 中的 Success)
{
    "code": 201,
    "message": "registration successful",
    "data": {
        "id": 1,
        "username": "alice"
    }
}
```

---

### 场景 2: 用户登录

```
客户端请求
    ↓
POST /api/auth/login
Body: {
    "username": "alice",
    "password": "123456"
}
    ↓
服务器处理
    1. 查找用户 "alice"
    2. 使用 password.CheckPassword() 验证密码
    3. 如果密码正确，使用 jwt.GenerateToken() 生成 Token
    ↓
返回响应 (response.go 中的 Success)
{
    "code": 200,
    "message": "login successful",
    "data": {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "user": {
            "id": 1,
            "username": "alice"
        }
    }
}
```

---

### 场景 3: 创建文章（需要认证）

```
客户端请求
    ↓
POST /api/posts
Header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Body: {
    "title": "My Blog",
    "content": "Hello World"
}
    ↓
中间件检查 (middleware/auth.go)
    1. 提取 Token 字符串
    2. 使用 jwt.ValidateToken() 验证 Token
    3. 如果 Token 无效，返回 response.Error() - 401 错误
    4. 如果 Token 有效，获取 UserID，继续处理
    ↓
服务器处理
    1. 创建文章对象
    2. 设置 UserID（从 Token 中获取）
    3. 保存到数据库
    ↓
返回响应 (response.go 中的 Success)
{
    "code": 201,
    "message": "post created successfully",
    "data": {
        "id": 1,
        "title": "My Blog",
        "content": "Hello World",
        "user_id": 1,
        "created_at": "2025-12-28T10:00:00Z"
    }
}
```

---

### 场景 4: 无效的 Token

```
客户端请求
    ↓
POST /api/posts
Header: Authorization: Bearer invalid_token_here
Body: {...}
    ↓
中间件检查 (middleware/auth.go)
    1. 提取 Token 字符串："invalid_token_here"
    2. 使用 jwt.ValidateToken() 验证
    3. Token 无效 → 返回错误
    ↓
返回响应 (response.go 中的 Error)
{
    "code": 401,
    "message": "invalid token"
}
```

---

## 📊 三个工具的关系图

```
用户认证流程
    ↓
[password.go]
    ├─ HashPassword() - 注册时加密密码
    └─ CheckPassword() - 登录时验证密码
    ↓
[jwt.go]
    ├─ GenerateToken() - 登录成功后生成 Token
    └─ ValidateToken() - 处理受保护接口时验证 Token
    ↓
[response.go]
    ├─ Success() - 成功时返回统一格式
    └─ Error() - 失败时返回统一格式
```

---

## ✅ 总结

| 工具文件 | 主要函数 | 用途 | 调用时机 |
|---------|---------|------|---------|
| **password.go** | HashPassword | 密码加密 | 用户注册、修改密码 |
|  | CheckPassword | 密码验证 | 用户登录 |
| **jwt.go** | GenerateToken | 生成认证令牌 | 登录成功后 |
|  | ValidateToken | 验证令牌 | 访问受保护接口时 |
| **response.go** | Success | 返回成功响应 | 接口成功时 |
|  | Error | 返回错误响应 | 接口失败时 |

---

## 🎯 核心概念

1. **密码安全（password.go）**
   - 永远不要存明文密码
   - 使用 bcrypt 单向加密
   - 存储和验证都使用哈希值

2. **用户认证（jwt.go）**
   - JWT Token 是用户身份凭证
   - 登录成功后生成 Token
   - 后续请求都需要验证 Token

3. **响应统一（response.go）**
   - 所有接口返回同一格式
   - 便于客户端处理
   - 提高 API 的可维护性

这三个工具文件共同构成了一个**完整的用户认证与授权系统**！

