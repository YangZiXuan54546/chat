package model

import (
	"time"
)

type Chat struct {
	ID            string    `json:"id"`
	Type          string    `json:"type"` // private, group
	Participant   *User     `json:"participant,omitempty"`
	GroupName     string    `json:"groupName,omitempty"`
	GroupAvatar   string    `json:"groupAvatar,omitempty"`
	Participants  []*User   `json:"participants,omitempty"`
	LastMessage   *Message  `json:"lastMessage,omitempty"`
	UnreadCount   int       `json:"unreadCount"`
	LastMessageAt time.Time `json:"lastMessageAt,omitempty"`
	CreatedAt     time.Time `json:"createdAt"`
}

type ChatListResponse struct {
	Chats []Chat `json:"chats"`
}
