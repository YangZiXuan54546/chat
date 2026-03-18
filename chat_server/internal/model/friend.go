package model

import (
	"time"
)

type FriendRequest struct {
	ID        string    `json:"id"`
	FromUserID string   `json:"fromUserId"`
	ToUserID   string   `json:"toUserId"`
	Status    string    `json:"status"` // pending, accepted, rejected
	FromUser  *User     `json:"fromUser,omitempty"`
	ToUser    *User     `json:"toUser,omitempty"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt,omitempty"`
}

type Friend struct {
	ID        string    `json:"id"`
	UserID    string    `json:"userId"`
	FriendID  string    `json:"friendId"`
	User      *User     `json:"user,omitempty"`
	Friend    *User     `json:"friend,omitempty"`
	CreatedAt time.Time `json:"createdAt"`
}

type FriendRequestAction struct {
	RequestID string `json:"requestId" binding:"required"`
}

type SendFriendRequest struct {
	UserID string `json:"userId" binding:"required"`
}
