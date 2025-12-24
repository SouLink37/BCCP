package main

import (
	"fmt"

	"gorm.io/gorm"
)

func problem2() {
	db := connectDB()
	db.AutoMigrate(&Accounts{}, &Transactions{})

	accounts := []Accounts{{Id: 1, Balance: 500}, {Id: 2, Balance: 0}}
	db.Create(&accounts)

	db.Transaction(func(tx *gorm.DB) error {

		account1 := Accounts{}
		account2 := Accounts{}

		if err := tx.Where("Id = ?", 1).Find(&account1).Error; err != nil {
			return fmt.Errorf("发送账户不存在： v%", err)
		}

		if account1.Balance < 100 {
			return fmt.Errorf("余额不足")
		}

		tx.Model(&account1).Update("Balance", account1.Balance-100)
		if err := tx.Where("id = ?", 2).Find(&account2).Error; err != nil {
			return fmt.Errorf("接收账户不存在: %v", err)
		}
		tx.Model(&account2).Update("Balance", account2.Balance+100)

		transaction1 := Transactions{FromAccountId: 1, ToAccountId: 2, Amount: 100}
		tx.Create(&transaction1)

		return nil
	})

}

type Accounts struct {
	Id      uint
	Balance float64
}

type Transactions struct {
	Id            uint    `gorm:"primaryKey"`
	FromAccountId int     `gorm:"column:from_account_id"`
	ToAccountId   int     `gorm:"column:to_account_id"`
	Amount        float64 `gorm:"column:amount"`
}
