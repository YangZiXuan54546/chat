package model

import (
	"time"
)

type Group struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description,omitempty"`
	Avatar      string    `json:"avatar,omitempty"`
	OwnerID     string    `json:"ownerId"`
	Members     []*User   `json:"members,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt,omitempty"`
}

type GroupMember struct {
	ID        string    `json:"id"`
	GroupID   string    `json:"groupId"`
	UserID    string    `json:"userId"`
	Role      string    `json:"role"` // owner, admin, member
	User      *User     `json:"user,omitempty"`
	JoinedAt  time.Time `json:"joinedAt"`
}

type CreateGroupRequest struct {
	Name        string   `json:"name" binding:"required,min=1,max=100"`
	Description string   `json:"description,omitempty"`
	Members     []string `json:"members,omitempty"`
}

type JoinGroupRequest struct {
	GroupID string `json:"groupId" binding:"required"`
}

type AddMembersRequest struct {
	MemberIDs []string `json:"memberIds" binding:"required"`
}
