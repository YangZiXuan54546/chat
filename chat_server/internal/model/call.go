package model

import (
	"time"
)

type Call struct {
	ID        string    `json:"id"`
	CallerID  string    `json:"callerId"`
	CalleeID  string    `json:"calleeId"`
	Type      string    `json:"type"` // audio, video
	Status    string    `json:"status"` // ringing, accepted, rejected, ended, missed
	Caller    *User     `json:"caller,omitempty"`
	Callee    *User     `json:"callee,omitempty"`
	CreatedAt time.Time `json:"createdAt"`
	StartedAt time.Time `json:"startedAt,omitempty"`
	EndedAt   time.Time `json:"endedAt,omitempty"`
	Duration  int       `json:"duration,omitempty"` // in seconds
}

type CallOfferRequest struct {
	CalleeID string                 `json:"calleeId" binding:"required"`
	Type     string                 `json:"type" binding:"required"`
	Offer    map[string]interface{} `json:"offer"`
}

type CallAnswerRequest struct {
	CallID string                 `json:"callId" binding:"required"`
	Answer map[string]interface{} `json:"answer"`
}

type CallICERequest struct {
	CallID    string                 `json:"callId" binding:"required"`
	Candidate map[string]interface{} `json:"candidate"`
}

type EndCallRequest struct {
	CallID string `json:"callId" binding:"required"`
}
