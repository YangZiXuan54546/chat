package handler

import (
	"net/http"
	"time"

	"chat_server/internal/model"
	"chat_server/internal/repository"

	"github.com/gin-gonic/gin"
)

type GroupHandler struct {
	groupRepo *repository.GroupRepository
	userRepo  *repository.UserRepository
}

func NewGroupHandler(groupRepo *repository.GroupRepository, userRepo *repository.UserRepository) *GroupHandler {
	return &GroupHandler{
		groupRepo: groupRepo,
		userRepo:  userRepo,
	}
}

func (h *GroupHandler) CreateGroup(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.CreateGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	group := &model.Group{
		ID:          repository.GenerateUUID(),
		Name:        req.Name,
		Description: req.Description,
		OwnerID:     userID.(string),
		CreatedAt:   time.Now(),
	}

	if err := h.groupRepo.Create(group); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create group"})
		return
	}

	// Add owner as a member
	ownerMember := &model.GroupMember{
		ID:       repository.GenerateUUID(),
		GroupID:  group.ID,
		UserID:   userID.(string),
		Role:     "owner",
		JoinedAt: time.Now(),
	}
	if err := h.groupRepo.AddMember(ownerMember); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add owner as member"})
		return
	}

	// Add other members if provided
	for _, memberID := range req.Members {
		member := &model.GroupMember{
			ID:       repository.GenerateUUID(),
			GroupID:  group.ID,
			UserID:   memberID,
			Role:     "member",
			JoinedAt: time.Now(),
		}
		if err := h.groupRepo.AddMember(member); err != nil {
			// Continue even if one fails
		}
	}

	// Get members
	members, _ := h.groupRepo.GetMembers(group.ID)
	group.Members = make([]*model.User, 0)
	for _, m := range members {
		if m.User != nil {
			group.Members = append(group.Members, m.User)
		}
	}

	c.JSON(http.StatusCreated, gin.H{"group": group})
}

func (h *GroupHandler) GetGroups(c *gin.Context) {
	userID, _ := c.Get("userID")

	groups, err := h.groupRepo.GetUserGroups(userID.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get groups"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"groups": groups})
}

func (h *GroupHandler) GetGroup(c *gin.Context) {
	groupID := c.Param("groupId")

	group, err := h.groupRepo.GetByID(groupID)
	if err != nil || group == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Group not found"})
		return
	}

	members, _ := h.groupRepo.GetMembers(groupID)
	group.Members = make([]*model.User, 0)
	for _, m := range members {
		if m.User != nil {
			group.Members = append(group.Members, m.User)
		}
	}

	c.JSON(http.StatusOK, gin.H{"group": group})
}

func (h *GroupHandler) JoinGroup(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req model.JoinGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if group exists
	group, err := h.groupRepo.GetByID(req.GroupID)
	if err != nil || group == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Group not found"})
		return
	}

	// Check if already a member
	isMember, err := h.groupRepo.IsMember(req.GroupID, userID.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check membership"})
		return
	}
	if isMember {
		c.JSON(http.StatusConflict, gin.H{"error": "Already a member"})
		return
	}

	// Add as member
	member := &model.GroupMember{
		ID:       repository.GenerateUUID(),
		GroupID:  req.GroupID,
		UserID:   userID.(string),
		Role:     "member",
		JoinedAt: time.Now(),
	}
	if err := h.groupRepo.AddMember(member); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to join group"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Joined group",
		"group":   group,
	})
}

func (h *GroupHandler) LeaveGroup(c *gin.Context) {
	userID, _ := c.Get("userID")
	groupID := c.Param("groupId")

	// Check if group exists
	group, err := h.groupRepo.GetByID(groupID)
	if err != nil || group == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Group not found"})
		return
	}

	// Check if user is the owner
	if group.OwnerID == userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Owner cannot leave group. Transfer ownership or delete the group."})
		return
	}

	// Remove member
	if err := h.groupRepo.RemoveMember(groupID, userID.(string)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to leave group"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Left group"})
}

func (h *GroupHandler) GetMembers(c *gin.Context) {
	groupID := c.Param("groupId")

	members, err := h.groupRepo.GetMembers(groupID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get members"})
		return
	}

	users := make([]*model.User, 0)
	for _, m := range members {
		if m.User != nil {
			users = append(users, m.User)
		}
	}

	c.JSON(http.StatusOK, gin.H{"members": users})
}

func (h *GroupHandler) AddMembers(c *gin.Context) {
	userID, _ := c.Get("userID")
	groupID := c.Param("groupId")

	var req model.AddMembersRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if current user is owner or admin
	group, err := h.groupRepo.GetByID(groupID)
	if err != nil || group == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Group not found"})
		return
	}

	isMember, _ := h.groupRepo.IsMember(groupID, userID.(string))
	if !isMember && group.OwnerID != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	// Add each member
	for _, memberID := range req.MemberIDs {
		member := &model.GroupMember{
			ID:       repository.GenerateUUID(),
			GroupID:  groupID,
			UserID:   memberID,
			Role:     "member",
			JoinedAt: time.Now(),
		}
		h.groupRepo.AddMember(member)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Members added"})
}

func (h *GroupHandler) RemoveMember(c *gin.Context) {
	userID, _ := c.Get("userID")
	groupID := c.Param("groupId")
	memberID := c.Param("memberId")

	// Check if current user is owner or admin
	group, err := h.groupRepo.GetByID(groupID)
	if err != nil || group == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Group not found"})
		return
	}

	// Only owner can remove members (or they can remove themselves)
	if group.OwnerID != userID.(string) && memberID != userID.(string) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	if err := h.groupRepo.RemoveMember(groupID, memberID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove member"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Member removed"})
}
