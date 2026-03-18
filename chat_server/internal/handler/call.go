package handler

import (
	"net/http"
	"time"

	"chat_server/internal/model"
	"chat_server/internal/repository"

	"github.com/gin-gonic/gin"
)

type CallHandler struct {
	callRepo *repository.CallRepository
	userRepo *repository.UserRepository
}

func NewCallHandler(callRepo *repository.CallRepository, userRepo *repository.UserRepository) *CallHandler {
	return &CallHandler{
		callRepo: callRepo,
		userRepo: userRepo,
	}
}

func (h *CallHandler) MakeCall(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.CallOfferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Create call record
	call := &model.Call{
		ID:        repository.GenerateUUID(),
		CallerID:  userID.(string),
		CalleeID:  req.CalleeID,
		Type:      req.Type,
		Status:    "ringing",
		CreatedAt: time.Now(),
	}

	if err := h.callRepo.Create(call); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create call"})
		return
	}

	// Get caller info
	caller, _ := h.userRepo.GetByID(userID.(string))
	call.Caller = caller

	// Get callee info
	callee, _ := h.userRepo.GetByID(req.CalleeID)
	call.Callee = callee

	c.JSON(http.StatusCreated, gin.H{"call": call})
}

func (h *CallHandler) AnswerCall(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.CallAnswerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get call
	call, err := h.callRepo.GetByID(req.CallID)
	if err != nil || call == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Call not found"})
		return
	}

	// Update call status
	now := time.Now()
	if err := h.callRepo.UpdateStatus(req.CallID, "accepted", &now, nil, 0); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update call"})
		return
	}

	call.Status = "accepted"
	call.StartedAt = now

	c.JSON(http.StatusOK, gin.H{"call": call})
}

func (h *CallHandler) EndCall(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.EndCallRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get call
	call, err := h.callRepo.GetByID(req.CallID)
	if err != nil || call == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Call not found"})
		return
	}

	// Calculate duration if call was accepted
	now := time.Now()
	var duration int
	if !call.StartedAt.IsZero() {
		duration = int(now.Sub(call.StartedAt).Seconds())
	}

	// Update call status
	if err := h.callRepo.UpdateStatus(req.CallID, "ended", nil, &now, duration); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update call"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Call ended"})
}

func (h *CallHandler) RejectCall(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.EndCallRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get call
	call, err := h.callRepo.GetByID(req.CallID)
	if err != nil || call == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Call not found"})
		return
	}

	// Verify this is the callee
	if call.CalleeID != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	// Update call status
	now := time.Now()
	if err := h.callRepo.UpdateStatus(req.CallID, "rejected", nil, &now, 0); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to reject call"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Call rejected"})
}
