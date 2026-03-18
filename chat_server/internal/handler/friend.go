package handler

import (
	"net/http"
	"time"

	"chat_server/internal/model"
	"chat_server/internal/repository"

	"github.com/gin-gonic/gin"
)

type FriendHandler struct {
	friendRepo *repository.FriendRepository
	userRepo   *repository.UserRepository
}

func NewFriendHandler(friendRepo *repository.FriendRepository, userRepo *repository.UserRepository) *FriendHandler {
	return &FriendHandler{
		friendRepo: friendRepo,
		userRepo:   userRepo,
	}
}

func (h *FriendHandler) GetFriends(c *gin.Context) {
	userID, _ := c.Get("userID")

	friends, err := h.friendRepo.GetFriends(userID.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get friends"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"friends": friends})
}

func (h *FriendHandler) SendFriendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.SendFriendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if user exists
	user, err := h.userRepo.GetByID(req.UserID)
	if err != nil || user == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Check if already friends
	areFriends, err := h.friendRepo.AreFriends(userID.(string), req.UserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check friendship"})
		return
	}
	if areFriends {
		c.JSON(http.StatusConflict, gin.H{"error": "Already friends"})
		return
	}

	// Create friend request
	friendReq := &model.FriendRequest{
		ID:        repository.GenerateUUID(),
		FromUserID: userID.(string),
		ToUserID:   req.UserID,
		Status:    "pending",
		CreatedAt: time.Now(),
	}

	if err := h.friendRepo.CreateRequest(friendReq); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send friend request"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"request": friendReq})
}

func (h *FriendHandler) GetPendingRequests(c *gin.Context) {
	userID, _ := c.Get("userID")

	requests, err := h.friendRepo.GetPendingRequests(userID.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get pending requests"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"requests": requests})
}

func (h *FriendHandler) AcceptFriendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.FriendRequestAction
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get the request
	friendReq, err := h.friendRepo.GetRequestByID(req.RequestID)
	if err != nil || friendReq == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Request not found"})
		return
	}

	// Verify this request is for the current user
	if friendReq.ToUserID != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	// Update request status
	if err := h.friendRepo.UpdateRequestStatus(req.RequestID, "accepted"); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to accept request"})
		return
	}

	// Create friendships (bidirectional)
	friend1 := &model.Friend{
		ID:        repository.GenerateUUID(),
		UserID:    friendReq.FromUserID,
		FriendID:  friendReq.ToUserID,
		CreatedAt: time.Now(),
	}
	friend2 := &model.Friend{
		ID:        repository.GenerateUUID(),
		UserID:    friendReq.ToUserID,
		FriendID:  friendReq.FromUserID,
		CreatedAt: time.Now(),
	}

	if err := h.friendRepo.CreateFriendship(friend1); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create friendship"})
		return
	}
	if err := h.friendRepo.CreateFriendship(friend2); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create friendship"})
		return
	}

	// Get the friend user info
	friendUser, _ := h.userRepo.GetByID(friendReq.FromUserID)

	c.JSON(http.StatusOK, gin.H{
		"message": "Friend request accepted",
		"friend":  friendUser,
	})
}

func (h *FriendHandler) RejectFriendRequest(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.FriendRequestAction
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get the request
	friendReq, err := h.friendRepo.GetRequestByID(req.RequestID)
	if err != nil || friendReq == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Request not found"})
		return
	}

	// Verify this request is for the current user
	if friendReq.ToUserID != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	// Update request status
	if err := h.friendRepo.UpdateRequestStatus(req.RequestID, "rejected"); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to reject request"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Friend request rejected"})
}

func (h *FriendHandler) DeleteFriend(c *gin.Context) {
	userID, _ := c.Get("userID")
	friendID := c.Param("userId")

	// Check if they are friends
	areFriends, err := h.friendRepo.AreFriends(userID.(string), friendID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check friendship"})
		return
	}
	if !areFriends {
		c.JSON(http.StatusNotFound, gin.H{"error": "Not friends"})
		return
	}

	// Delete friendships
	if err := h.friendRepo.DeleteFriendship(userID.(string), friendID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete friend"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Friend deleted"})
}
