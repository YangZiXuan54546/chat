package ws

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512 * 1024
)

type Client struct {
	Hub      *Hub
	Conn     *websocket.Conn
	Send     chan []byte
	UserID   string
	Username string
}

type Hub struct {
	clients    map[string]*Client
	userIDs    map[*Client]string
	broadcast  chan []byte
	register   chan *Client
	unregister chan *Client
	mutex      sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[string]*Client),
		userIDs:    make(map[*Client]string),
		broadcast:  make(chan []byte),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

func (h *Hub) Register(client *Client) {
	h.register <- client
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mutex.Lock()
			h.clients[client.UserID] = client
			h.userIDs[client] = client.UserID
			h.mutex.Unlock()
			log.Printf("Client connected: %s", client.UserID)

		case client := <-h.unregister:
			h.mutex.Lock()
			if _, ok := h.clients[client.UserID]; ok {
				delete(h.clients, client.UserID)
				delete(h.userIDs, client)
				close(client.Send)
			}
			h.mutex.Unlock()
			log.Printf("Client disconnected: %s", client.UserID)

		case message := <-h.broadcast:
			h.mutex.RLock()
			for _, client := range h.clients {
				select {
				case client.Send <- message:
				default:
					close(client.Send)
					delete(h.clients, client.UserID)
					delete(h.userIDs, client)
				}
			}
			h.mutex.RUnlock()
		}
	}
}

func (h *Hub) SendToUser(userID string, message []byte) {
	h.mutex.RLock()
	defer h.mutex.RUnlock()

	if client, ok := h.clients[userID]; ok {
		select {
		case client.Send <- message:
		default:
			close(client.Send)
			delete(h.clients, userID)
		}
	}
}

func (h *Hub) SendToUsers(userIDs []string, message []byte) {
	h.mutex.RLock()
	defer h.mutex.RUnlock()

	for _, userID := range userIDs {
		if client, ok := h.clients[userID]; ok {
			select {
			case client.Send <- message:
			default:
				close(client.Send)
				delete(h.clients, userID)
			}
		}
	}
}

func (h *Hub) IsUserOnline(userID string) bool {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	_, ok := h.clients[userID]
	return ok
}

func (h *Hub) Broadcast(message []byte) {
	h.broadcast <- message
}

func (h *Hub) GetOnlineUsers() []string {
	h.mutex.RLock()
	defer h.mutex.RUnlock()

	users := make([]string, 0, len(h.clients))
	for userID := range h.clients {
		users = append(users, userID)
	}
	return users
}

func (c *Client) ReadPump() {
	defer func() {
		c.Hub.unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(maxMessageSize)
	c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}

		// Parse and handle the message
		var msg map[string]interface{}
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("error parsing message: %v", err)
			continue
		}

		c.Hub.handleMessage(c, msg)
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (h *Hub) handleMessage(c *Client, msg map[string]interface{}) {
	event, ok := msg["event"].(string)
	if !ok {
		return
	}

	data, _ := json.Marshal(msg["data"])

	switch event {
	case "message":
		h.handleChatMessage(c, data)
	case "typing":
		h.handleTyping(c, data)
	case "read":
		h.handleReadReceipt(c, data)
	case "recall":
		h.handleRecall(c, data)
	case "call_offer":
		h.handleCallOffer(c, data)
	case "call_answer":
		h.handleCallAnswer(c, data)
	case "call_ice":
		h.handleCallICE(c, data)
	case "call_end":
		h.handleCallEnd(c, data)
	case "online":
		h.broadcastOnlineStatus(c)
	case "offline":
		h.broadcastOfflineStatus(c)
	}
}

func (h *Hub) handleChatMessage(c *Client, data []byte) {
	var msg struct {
		ReceiverID string `json:"receiverId"`
		GroupID    string `json:"groupId"`
	}
	if err := json.Unmarshal(data, &msg); err != nil {
		return
	}

	response := map[string]interface{}{
		"event": "message",
		"data":  json.RawMessage(data),
	}
	responseBytes, _ := json.Marshal(response)

	if msg.GroupID != "" {
		// Broadcast to all group members
		h.broadcast <- responseBytes
	} else if msg.ReceiverID != "" {
		// Send to receiver
		h.SendToUser(msg.ReceiverID, responseBytes)
	}
}

func (h *Hub) handleTyping(c *Client, data []byte) {
	var msg struct {
		ChatID string `json:"chatId"`
		Type   string `json:"type"`
	}
	if err := json.Unmarshal(data, &msg); err != nil {
		return
	}

	response := map[string]interface{}{
		"event": "typing",
		"data": map[string]interface{}{
			"userId":   c.UserID,
			"username": c.Username,
			"chatId":   msg.ChatID,
			"type":     msg.Type,
		},
	}
	responseBytes, _ := json.Marshal(response)

	// Send to the other user in the chat
	if msg.Type == "private" {
		// The receiver ID should be in the original data
	}
}

func (h *Hub) handleReadReceipt(c *Client, data []byte) {
	var msg struct {
		MessageID string `json:"messageId"`
	}
	if err := json.Unmarshal(data, &msg); err != nil {
		return
	}

	response := map[string]interface{}{
		"event": "read",
		"data": map[string]interface{}{
			"messageId": msg.MessageID,
			"userId":    c.UserID,
		},
	}
	responseBytes, _ := json.Marshal(response)
	h.broadcast <- responseBytes
}

func (h *Hub) handleRecall(c *Client, data []byte) {
	var msg struct {
		MessageID string `json:"messageId"`
	}
	if err := json.Unmarshal(data, &msg); err != nil {
		return
	}

	response := map[string]interface{}{
		"event": "recall",
		"data": map[string]interface{}{
			"messageId": msg.MessageID,
			"userId":    c.UserID,
		},
	}
	responseBytes, _ := json.Marshal(response)
	h.broadcast <- responseBytes
}

func (h *Hub) handleCallOffer(c *Client, data []byte) {
	var msg struct {
		CalleeID string                 `json:"calleeId"`
		Offer    map[string]interface{} `json:"offer"`
	}
	if err := json.Unmarshal(data, &msg); err != nil {
		return
	}

	response := map[string]interface{}{
		"event": "call_offer",
		"data": map[string]interface{}{
			"callerId":  c.UserID,
			"callerName": c.Username,
			"offer":     msg.Offer,
		},
	}
	responseBytes, _ := json.Marshal(response)
	h.SendToUser(msg.CalleeID, responseBytes)
}

func (h *Hub) handleCallAnswer(c *Client, data []byte) {
	var msg struct {
		CallerID string                 `json:"callerId"`
		Answer   map[string]interface{} `json:"answer"`
	}
	if err := json.Unmarshal(data, &msg); err != nil {
		return
	}

	response := map[string]interface{}{
		"event": "call_answer",
		"data": map[string]interface{}{
			"calleeId":  c.UserID,
			"calleeName": c.Username,
			"answer":    msg.Answer,
		},
	}
	responseBytes, _ := json.Marshal(response)
	h.SendToUser(msg.CallerID, responseBytes)
}

func (h *Hub) handleCallICE(c *Client, data []byte) {
	var msg struct {
		TargetUserID string                 `json:"targetUserId"`
		Candidate    map[string]interface{} `json:"candidate"`
	}
	if err := json.Unmarshal(data, &msg); err != nil {
		return
	}

	response := map[string]interface{}{
		"event": "call_ice",
		"data": map[string]interface{}{
			"fromUserId": c.UserID,
			"candidate":  msg.Candidate,
		},
	}
	responseBytes, _ := json.Marshal(response)
	h.SendToUser(msg.TargetUserID, responseBytes)
}

func (h *Hub) handleCallEnd(c *Client, data []byte) {
	var msg struct {
		TargetUserID string `json:"targetUserId"`
	}
	if err := json.Unmarshal(data, &msg); err != nil {
		return
	}

	response := map[string]interface{}{
		"event": "call_end",
		"data": map[string]interface{}{
			"fromUserId": c.UserID,
		},
	}
	responseBytes, _ := json.Marshal(response)
	h.SendToUser(msg.TargetUserID, responseBytes)
}

func (h *Hub) broadcastOnlineStatus(c *Client) {
	response := map[string]interface{}{
		"event": "online",
		"data": map[string]interface{}{
			"userId": c.UserID,
		},
	}
	responseBytes, _ := json.Marshal(response)
	h.broadcast <- responseBytes
}

func (h *Hub) broadcastOfflineStatus(c *Client) {
	response := map[string]interface{}{
		"event": "offline",
		"data": map[string]interface{}{
			"userId": c.UserID,
		},
	}
	responseBytes, _ := json.Marshal(response)
	h.broadcast <- responseBytes
}
