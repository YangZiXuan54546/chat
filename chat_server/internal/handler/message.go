package handler

import (
	"net/http"
	"strconv"
	"time"

	"chat_server/internal/model"
	"chat_server/internal/repository"

	"github.com/gin-gonic/gin"
)

type MessageHandler struct {
	messageRepo *repository.MessageRepository
	userRepo    *repository.UserRepository
}

func NewMessageHandler(messageRepo *repository.MessageRepository, userRepo *repository.UserRepository) *MessageHandler {
	return &MessageHandler{
		messageRepo: messageRepo,
		userRepo:    userRepo,
	}
}

func (h *MessageHandler) GetPrivateMessages(c *gin.Context) {
	userID, _ := c.Get("userID")
	otherUserID := c.Query("userId")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset := (page - 1) * limit

	messages, err := h.messageRepo.GetPrivateMessages(userID.(string), otherUserID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get messages"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"messages": messages,
		"page":     page,
		"limit":    limit,
	})
}

func (h *MessageHandler) GetGroupMessages(c *gin.Context) {
	groupID := c.Param("groupId")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset := (page - 1) * limit

	messages, err := h.messageRepo.GetGroupMessages(groupID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get messages"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"messages": messages,
		"page":     page,
		"limit":    limit,
	})
}

func (h *MessageHandler) SendMessage(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Type == "" {
		req.Type = "text"
	}

	message := &model.Message{
		ID:         repository.GenerateUUID(),
		SenderID:   userID.(string),
		ReceiverID: req.ReceiverID,
		GroupID:    req.GroupID,
		Content:    req.Content,
		Type:       req.Type,
		Status:     "sent",
		ReplyToID:  req.ReplyToID,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}

	if err := h.messageRepo.Create(message); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": message})
}

func (h *MessageHandler) RecallMessage(c *gin.Context) {
	userID, _ := c.Get("userID")
	messageID := c.Param("messageId")

	// Get the message
	message, err := h.messageRepo.GetByID(messageID)
	if err != nil || message == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Message not found"})
		return
	}

	// Check if user is the sender
	if message.SenderID != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	// Recall the message
	if err := h.messageRepo.Recall(messageID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to recall message"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Message recalled"})
}

func (h *MessageHandler) MarkAsRead(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req struct {
		MessageID string `json:"messageId"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update message status
	if err := h.messageRepo.UpdateStatus(req.MessageID, "read"); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark as read"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Marked as read"})
}
