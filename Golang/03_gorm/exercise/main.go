package main

import (
	"database/sql"
	"fmt"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// ==================== 模型定义 ====================

// BaseModel 通用字段，可被其他模型嵌入
type BaseModel struct {
	ID        uint `gorm:"primaryKey"`
	CreatedAt time.Time
	UpdatedAt time.Time
}

// User 用户模型
type User struct {
	BaseModel            // 嵌入通用字段
	Name         string  `gorm:"size:100;not null"`    // 限制长度100，不能为空
	Email        *string `gorm:"size:200;uniqueIndex"` // 唯一索引，允许为空
	Age          uint8   `gorm:"default:18"`           // 默认值18
	Birthday     *time.Time
	MemberNumber sql.NullString `gorm:"size:50"`
	ActivatedAt  sql.NullTime
}

// Product 商品模型 - 演示关联关系
type Product struct {
	BaseModel
	Code   string  `gorm:"size:50;uniqueIndex"`
	Name   string  `gorm:"size:200;not null"`
	Price  float64 `gorm:"type:decimal(10,2)"`
	Stock  int     `gorm:"default:0"`
	UserID uint    // 外键
	User   User    `gorm:"foreignKey:UserID"` // 属于某个用户
}

// ==================== 数据库连接 ====================

func connectDB() *gorm.DB {
	dsn := "root:12345678@tcp(127.0.0.1:3306)/gorm_exercise?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("连接数据库失败: " + err.Error())
	}
	fmt.Println("✅ 数据库连接成功")
	return db
}

// ==================== CRUD 操作示例 ====================

// CreateDemo 创建数据示例
func CreateDemo(db *gorm.DB) {
	fmt.Println("\n========== 创建数据 ==========")

	// 1. 创建单条记录
	email := "zhangsan@example.com"
	user := User{
		Name:  "张三",
		Email: &email,
		Age:   25,
	}
	result := db.Create(&user)
	fmt.Printf("创建用户: %s, ID: %d, 影响行数: %d\n", user.Name, user.ID, result.RowsAffected)

	// 2. 批量创建
	users := []User{
		{Name: "李四", Age: 30},
		{Name: "王五", Age: 28},
		{Name: "赵六", Age: 35},
	}
	db.Create(&users)
	fmt.Printf("批量创建 %d 个用户\n", len(users))

	// 3. 创建商品（带关联）
	product := Product{
		Code:   "P001",
		Name:   "iPhone 15",
		Price:  6999.00,
		Stock:  100,
		UserID: user.ID, // 关联到张三
	}
	db.Create(&product)
	fmt.Printf("创建商品: %s, 价格: %.2f\n", product.Name, product.Price)
}

// QueryDemo 查询数据示例
func QueryDemo(db *gorm.DB) {
	fmt.Println("\n========== 查询数据 ==========")

	// 1. 查询单条 - First (按主键排序取第一条)
	var user User
	db.First(&user)
	fmt.Printf("First: ID=%d, Name=%s, Age=%d\n", user.ID, user.Name, user.Age)

	// 2. 根据主键查询
	var user2 User
	db.First(&user2, 2) // 查询 ID=2 的记录
	fmt.Printf("根据ID查询: ID=%d, Name=%s\n", user2.ID, user2.Name)

	// 3. 条件查询 - Where
	var user3 User
	db.Where("name = ?", "王五").First(&user3)
	fmt.Printf("Where查询: Name=%s, Age=%d\n", user3.Name, user3.Age)

	// 4. 查询多条 - Find
	var users []User
	db.Where("age > ?", 25).Find(&users)
	fmt.Printf("年龄>25的用户: %d 人\n", len(users))
	for _, u := range users {
		fmt.Printf("  - %s (年龄: %d)\n", u.Name, u.Age)
	}

	// 5. 选择特定字段
	var names []string
	db.Model(&User{}).Pluck("name", &names)
	fmt.Printf("所有用户名: %v\n", names)

	// 6. 统计数量
	var count int64
	db.Model(&User{}).Count(&count)
	fmt.Printf("用户总数: %d\n", count)

	// 7. 预加载关联数据
	var product Product
	db.Preload("User").First(&product)
	fmt.Printf("商品: %s, 所属用户: %s\n", product.Name, product.User.Name)
}

// UpdateDemo 更新数据示例
func UpdateDemo(db *gorm.DB) {
	fmt.Println("\n========== 更新数据 ==========")

	// 1. 更新单个字段
	var user User
	db.First(&user)
	db.Model(&user).Update("age", 26)
	fmt.Printf("更新 %s 的年龄为: %d\n", user.Name, 26)

	// 2. 更新多个字段 - Updates
	db.Model(&user).Updates(User{Name: "张三丰", Age: 100})
	fmt.Printf("更新后: Name=%s, Age=%d\n", user.Name, 100)

	// 3. 使用 map 更新（可以更新零值）
	db.Model(&user).Updates(map[string]interface{}{
		"age": 0, // 使用 struct 无法更新为零值
	})
	fmt.Println("使用 map 可以更新零值")

	// 4. 批量更新
	result := db.Model(&User{}).Where("age < ?", 30).Update("age", 30)
	fmt.Printf("批量更新: 影响 %d 行\n", result.RowsAffected)
}

// DeleteDemo 删除数据示例
func DeleteDemo(db *gorm.DB) {
	fmt.Println("\n========== 删除数据 ==========")

	// 1. 根据主键删除
	db.Delete(&User{}, 1)
	fmt.Println("删除 ID=1 的用户")

	// 2. 条件删除
	result := db.Where("name = ?", "赵六").Delete(&User{})
	fmt.Printf("删除赵六: 影响 %d 行\n", result.RowsAffected)

	// 3. 删除商品
	db.Where("code = ?", "P001").Delete(&Product{})
	fmt.Println("删除商品 P001")
}

// AdvancedQueryDemo 高级查询示例
func AdvancedQueryDemo(db *gorm.DB) {
	fmt.Println("\n========== 高级查询 ==========")

	// 1. 链式调用
	var users []User
	db.Where("age > ?", 20).
		Order("age desc").
		Limit(3).
		Offset(0).
		Find(&users)
	fmt.Println("链式查询 (年龄>20, 按年龄降序, 取前3条):")
	for _, u := range users {
		fmt.Printf("  - %s (年龄: %d)\n", u.Name, u.Age)
	}

	// 2. Or 条件
	var users2 []User
	db.Where("name = ?", "张三").Or("name = ?", "李四").Find(&users2)
	fmt.Printf("Or查询: 找到 %d 人\n", len(users2))

	// 3. 原生 SQL
	var result []User
	db.Raw("SELECT * FROM users WHERE age >= ?", 25).Scan(&result)
	fmt.Printf("原生SQL查询: 找到 %d 人\n", len(result))

	// 4. 分组统计
	type AgeGroup struct {
		Age   uint8
		Total int
	}
	var groups []AgeGroup
	db.Model(&User{}).Select("age, count(*) as total").Group("age").Scan(&groups)
	fmt.Println("按年龄分组统计:")
	for _, g := range groups {
		fmt.Printf("  - 年龄 %d: %d 人\n", g.Age, g.Total)
	}
}

// ==================== 主函数 ====================

func main() {
	// 连接数据库
	db := connectDB()

	// 自动迁移（创建/更新表结构）
	fmt.Println("\n========== 自动迁移 ==========")
	db.AutoMigrate(&User{}, &Product{})
	fmt.Println("✅ 表结构迁移完成")

	// 清空数据（方便重复测试）
	db.Exec("DELETE FROM products")
	db.Exec("DELETE FROM users")
	db.Exec("ALTER TABLE users AUTO_INCREMENT = 1")
	db.Exec("ALTER TABLE products AUTO_INCREMENT = 1")

	// 运行示例
	CreateDemo(db)        // 创建
	QueryDemo(db)         // 查询
	UpdateDemo(db)        // 更新
	AdvancedQueryDemo(db) // 高级查询
	DeleteDemo(db)        // 删除

	fmt.Println("\n✅ 所有示例执行完成！")
	fmt.Println("💡 提示: 在 Database Client 插件中刷新查看数据变化")
}
