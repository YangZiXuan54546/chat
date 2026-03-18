package model

import (
	"time"
)

type Message struct {
	ID         string    `json:"id"`
	SenderID   string    `json:"senderId"`
	ReceiverID string    `json:"receiverId,omitempty"`
	GroupID    string    `json:"groupId,omitempty"`
	Content    string    `json:"content"`
	Type       string    `json:"type"` // text, image, file, audio, video
	Status     string    `json:"status"` // sending, sent, delivered, read, failed
	ReplyToID  string    `json:"replyToId,omitempty"`
	IsRecalled bool      `json:"isRecalled"`
	CreatedAt  time.Time `json:"createdAt"`
	UpdatedAt  time.Time `json:"updatedAt,omitempty"`
}

type SendMessageRequest struct {
	ReceiverID string `json:"receiverId,omitempty"`
	GroupID    string `json:"groupId,omitempty"`
	Content    string `json:"content" binding:"required"`
	Type       string `json:"type"`
	ReplyToID  string `json:"replyToId,omitempty"`
}

type RecallMessageRequest struct {
	MessageID string `json:"messageId" binding:"required"`
}
