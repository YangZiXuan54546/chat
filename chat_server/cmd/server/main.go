package main

import (
	"database/sql"
	"log"
	"os"

	"chat_server/internal/handler"
	"chat_server/pkg/ws"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
)

func main() {
	// Initialize database connection
	db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Test database connection
	if err := db.Ping(); err != nil {
		log.Println("Warning: Database connection failed:", err)
		// Continue anyway - for development without database
	}

	// Initialize WebSocket hub
	hub := ws.NewHub()
	go hub.Run()

	// Initialize handlers
	authHandler := handler.NewAuthHandler(nil) // User repo will be nil for demo
	wsHandler := handler.NewWebSocketHandler(hub)
	friendHandler := handler.NewFriendHandler(nil, nil)
	messageHandler := handler.NewMessageHandler(nil, nil)
	groupHandler := handler.NewGroupHandler(nil, nil)
	callHandler := handler.NewCallHandler(nil, nil)

	// Initialize Gin router
	r := gin.Default()

	// Middleware
	r.Use(handler.CORSMiddleware())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API v1 routes
	v1 := r.Group("/api/v1")
	{
		// Auth routes (public)
		auth := v1.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.Refresh)
		}

		// Protected routes
		protected := v1.Group("")
		protected.Use(handler.AuthMiddleware())
		{
			// Auth
			protected.POST("/auth/logout", authHandler.Logout)
			protected.GET("/users/profile", authHandler.GetProfile)
			protected.PUT("/users/profile", authHandler.UpdateProfile)
			protected.GET("/users/search", authHandler.SearchUsers)

			// Friends
			friends := protected.Group("/friends")
			{
				friends.GET("", friendHandler.GetFriends)
				friends.POST("/request", friendHandler.SendFriendRequest)
				friends.POST("/accept", friendHandler.AcceptFriendRequest)
				friends.POST("/reject", friendHandler.RejectFriendRequest)
				friends.DELETE("/:userId", friendHandler.DeleteFriend)
			}

			// Messages
			messages := protected.Group("/messages")
			{
				messages.GET("/private", messageHandler.GetPrivateMessages)
				messages.GET("/group/:groupId", messageHandler.GetGroupMessages)
				messages.POST("", messageHandler.SendMessage)
				messages.DELETE("/:messageId", messageHandler.RecallMessage)
				messages.POST("/read", messageHandler.MarkAsRead)
			}

			// Groups
			groups := protected.Group("/groups")
			{
				groups.POST("", groupHandler.CreateGroup)
				groups.GET("", groupHandler.GetGroups)
				groups.GET("/:groupId", groupHandler.GetGroup)
				groups.POST("/join", groupHandler.JoinGroup)
				groups.POST("/leave/:groupId", groupHandler.LeaveGroup)
				groups.GET("/:groupId/members", groupHandler.GetMembers)
				groups.POST("/:groupId/members", groupHandler.AddMembers)
				groups.DELETE("/:groupId/members/:memberId", groupHandler.RemoveMember)
			}

			// Calls
			calls := protected.Group("/call")
			{
				calls.POST("/offer", callHandler.MakeCall)
				calls.POST("/answer", callHandler.AnswerCall)
				calls.POST("/end", callHandler.EndCall)
				calls.POST("/reject", callHandler.RejectCall)
			}
		}
	}

	// WebSocket endpoint
	r.GET("/ws", wsHandler.HandleWebSocket)

	// Get port from environment or default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
