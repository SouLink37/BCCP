# JWT 实现指南

## 📋 行动大纲

```
1. 定义 Claims 结构体（包含用户ID和时间信息）
2. 实现 GenerateToken(userID uint) → Token 字符串
3. 实现 ValidateToken(tokenString string) → Claims 信息
```

---

## 1️⃣ Claims 结构体

### 用途
存储 JWT Token 中的数据

### 字段
```
UserID       uint   // 用户ID
ExpiresAt    time.Time  // 过期时间
IssuedAt     time.Time  // 签发时间
```

### 为什么需要
JWT 标准格式要求包含这些信息

### 完整定义
```go
type Claims struct {
    UserID uint
    jwt.RegisteredClaims
}
```

---

## 2️⃣ GenerateToken 函数

### 签名
```go
func GenerateToken(userID uint) (string, error)
```

### 输入
- `userID` - 用户ID（如 1）

### 输出
- `string` - JWT Token（很长的字符串）
- `error` - 错误信息

### 内部实现步骤

1. **创建 Claims 对象**
   - 设置 UserID = userID
   - 设置 ExpiresAt = 现在 + 24小时
   - 设置 IssuedAt = 现在

2. **调用 jwt 库的 NewWithClaims()**
   - 参数1：jwt.SigningMethodHS256（签名算法）
   - 参数2：claims（创建的 Claims 对象）
   - 返回：Token 对象

3. **调用 Token 对象的 SignedString()**
   - 参数：密钥（[]byte 格式）
   - 返回：签名后的 Token 字符串 或 错误

4. **返回 Token 字符串和错误**

### 使用的 jwt 库函数

```go
jwt.NewWithClaims(method, claims)  // 创建 Token 对象
token.SignedString(key)             // 签名并生成字符串
jwt.RegisteredClaims                // JWT 标准声明
jwt.NewNumericDate(time)            // 时间转换
```

### 时间设置
```
ExpiresAt = jwt.NewNumericDate(time.Now().Add(24 * time.Hour))
IssuedAt = jwt.NewNumericDate(time.Now())
```

---

## 3️⃣ ValidateToken 函数

### 签名
```go
func ValidateToken(tokenString string) (*Claims, error)
```

### 输入
- `tokenString` - JWT Token 字符串

### 输出
- `*Claims` - Token 中的信息（如果有效）
- `error` - 错误信息（如果无效或过期）

### 内部实现步骤

1. **调用 jwt 库的 ParseWithClaims()**
   - 参数1：tokenString（要验证的 Token）
   - 参数2：&Claims{}（用来存放解析结果）
   - 参数3：回调函数（返回密钥，用来验证签名）
   - 返回：Token 对象 和 错误

2. **从 Token 对象中提取 Claims**
   - 类型断言：`token.Claims.(*Claims)`

3. **验证 Token 是否有效**
   - 检查类型转换是否成功
   - 检查 token.Valid 是否为 true

4. **返回 Claims 或错误**

### 使用的 jwt 库函数

```go
jwt.ParseWithClaims(tokenString, claims, keyFunc)
// 参数3 keyFunc 是一个回调函数
// 格式：func(token *jwt.Token) (interface{}, error) { return 密钥, nil }

token.Claims.(*Claims)  // 类型断言，提取 Claims
token.Valid             // 检查 Token 是否有效
```

---

## 🔑 密钥管理

### 定义全局密钥
```go
var jwtSecret = []byte("your-secret-key")
// 必须和配置中的 Secret 一致
```

### 在两个函数中使用同一个密钥
- **GenerateToken**：用它来签名 Token
- **ValidateToken**：用它来验证签名是否正确

### 密钥约束
- 必须是 []byte 类型
- 长度建议 32 字节以上（更安全）
- 同一应用的密钥必须一致

---

## 📊 函数流程图

### GenerateToken 流程
```
GenerateToken(userID=1)
    ↓
创建 Claims {
    UserID: 1, 
    ExpiresAt: 明天此时, 
    IssuedAt: 现在
}
    ↓
jwt.NewWithClaims(HS256, claims)
返回：Token 对象
    ↓
token.SignedString(密钥)
返回：签名后的 Token 字符串
    ↓
返回 Token 字符串："eyJhbGci..."
```

### ValidateToken 流程
```
ValidateToken("eyJhbGci...")
    ↓
jwt.ParseWithClaims(
    token, 
    &Claims{}, 
    返回密钥的回调函数
)
    ↓
验证步骤：
1. 检查签名是否正确
2. 检查是否过期
3. 验证结构
    ↓
如果有效：返回 Claims {UserID: 1, ...}
如果无效：返回错误 (nil, error)
```

---

## 🎯 需要导入的包

```go
import (
    "errors"
    "github.com/golang-jwt/jwt/v5"
    "time"
)
```

---

## 💡 关键点

### HS256 是什么
- HS256 = HMAC SHA-256
- 使用密钥对数据进行签名
- 同一密钥可以验证签名

### 回调函数
```go
// ValidateToken 中的回调函数
func(token *jwt.Token) (interface{}, error) {
    // 检查签名方法
    if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
        return nil, errors.New("unexpected signing method")
    }
    // 返回密钥用来验证
    return jwtSecret, nil
}
```

### 类型转换
```go
// 从 token.Claims 转成我们的 Claims 结构体
claims, ok := token.Claims.(*Claims)
if !ok {
    return nil, errors.New("invalid token claims")
}
```

---

## ⚡ 快速参考表

| 组件 | 输入 | 输出 | 目的 |
|------|------|------|------|
| **GenerateToken** | userID (uint) | Token 字符串 | 登录后生成 Token 返回给客户端 |
| **ValidateToken** | Token 字符串 | Claims 对象 | 验证请求中的 Token 是否有效 |
| **Claims** | - | - | 存储 Token 中的数据（UserID、时间等） |

---

## 🔄 实际应用

### 登录时调用 GenerateToken
```
用户输入用户名密码
    ↓
验证成功
    ↓
GenerateToken(user.ID)
返回 Token 字符串
    ↓
返回给客户端
客户端存储 Token
```

### 创建文章时调用 ValidateToken
```
客户端请求：POST /api/posts
Header: Authorization: Bearer [Token]
    ↓
中间件提取 Token
    ↓
ValidateToken(token)
    ↓
Token 有效 → 获取 UserID → 继续处理
Token 无效 → 返回 401 错误
```

---

## ⚠️ 常见错误

### 1. 密钥不一致
```go
// 错误：生成和验证用不同的密钥
// GenerateToken 中
var secret1 = []byte("key1")

// ValidateToken 中
var secret2 = []byte("key2")
// 结果：验证会失败
```

### 2. 忘记时间转换
```go
// 错误
ExpiresAt: time.Now().Add(24 * time.Hour)  // ❌

// 正确
ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour))  // ✅
```

### 3. 类型断言错误
```go
// 错误
claims := token.Claims.(Claims)  // ❌ 应该是指针

// 正确
claims := token.Claims.(*Claims)  // ✅
```

---

## 📝 总结

**三个核心要素：**
1. **Claims** - 定义数据结构
2. **GenerateToken** - 创建和签名 Token
3. **ValidateToken** - 验证 Token 有效性

**密钥是关键：** 同一应用中必须使用同一个密钥

