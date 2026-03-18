package repository

import (
	"database/sql"
	"fmt"
	"time"

	"chat_server/internal/model"
)

type UserRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(user *model.User) error {
	query := `
		INSERT INTO users (id, username, email, password, avatar, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err := r.db.Exec(query, user.ID, user.Username, user.Email, user.Password, user.Avatar, user.CreatedAt)
	return err
}

func (r *UserRepository) GetByID(id string) (*model.User, error) {
	query := `
		SELECT id, username, email, password, avatar, is_online, last_seen, created_at
		FROM users WHERE id = $1
	`
	user := &model.User{}
	err := r.db.QueryRow(query, id).Scan(
		&user.ID, &user.Username, &user.Email, &user.Password, &user.Avatar,
		&user.IsOnline, &user.LastSeen, &user.CreatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return user, err
}

func (r *UserRepository) GetByUsername(username string) (*model.User, error) {
	query := `
		SELECT id, username, email, password, avatar, is_online, last_seen, created_at
		FROM users WHERE username = $1
	`
	user := &model.User{}
	err := r.db.QueryRow(query, username).Scan(
		&user.ID, &user.Username, &user.Email, &user.Password, &user.Avatar,
		&user.IsOnline, &user.LastSeen, &user.CreatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return user, err
}

func (r *UserRepository) Search(query string, limit int) ([]*model.User, error) {
	sqlQuery := `
		SELECT id, username, email, avatar, is_online, last_seen, created_at
		FROM users
		WHERE username ILIKE $1
		LIMIT $2
	`
	rows, err := r.db.Query(sqlQuery, "%"+query+"%", limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []*model.User
	for rows.Next() {
		user := &model.User{}
		err := rows.Scan(&user.ID, &user.Username, &user.Email, &user.Avatar, &user.IsOnline, &user.LastSeen, &user.CreatedAt)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}
	return users, nil
}

func (r *UserRepository) UpdateOnlineStatus(userID string, isOnline bool) error {
	query := `UPDATE users SET is_online = $1, last_seen = $2 WHERE id = $3`
	_, err := r.db.Exec(query, isOnline, time.Now(), userID)
	return err
}

func (r *UserRepository) Update(user *model.User) error {
	query := `
		UPDATE users SET username = $1, email = $2, avatar = $3
		WHERE id = $4
	`
	_, err := r.db.Exec(query, user.Username, user.Email, user.Avatar, user.ID)
	return err
}

// Friend Repository
type FriendRepository struct {
	db *sql.DB
}

func NewFriendRepository(db *sql.DB) *FriendRepository {
	return &FriendRepository{db: db}
}

func (r *FriendRepository) CreateRequest(req *model.FriendRequest) error {
	query := `
		INSERT INTO friend_requests (id, from_user_id, to_user_id, status, created_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	_, err := r.db.Exec(query, req.ID, req.FromUserID, req.ToUserID, req.Status, req.CreatedAt)
	return err
}

func (r *FriendRepository) GetRequestByID(id string) (*model.FriendRequest, error) {
	query := `
		SELECT id, from_user_id, to_user_id, status, created_at, updated_at
		FROM friend_requests WHERE id = $1
	`
	req := &model.FriendRequest{}
	err := r.db.QueryRow(query, id).Scan(
		&req.ID, &req.FromUserID, &req.ToUserID, &req.Status, &req.CreatedAt, &req.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return req, err
}

func (r *FriendRepository) GetPendingRequests(userID string) ([]*model.FriendRequest, error) {
	query := `
		SELECT fr.id, fr.from_user_id, fr.to_user_id, fr.status, fr.created_at, fr.updated_at,
			   u.id, u.username, u.email, u.avatar, u.is_online, u.last_seen, u.created_at
		FROM friend_requests fr
		JOIN users u ON fr.from_user_id = u.id
		WHERE fr.to_user_id = $1 AND fr.status = 'pending'
		ORDER BY fr.created_at DESC
	`
	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var requests []*model.FriendRequest
	for rows.Next() {
		req := &model.FriendRequest{FromUser: &model.User{}}
		err := rows.Scan(
			&req.ID, &req.FromUserID, &req.ToUserID, &req.Status, &req.CreatedAt, &req.UpdatedAt,
			&req.FromUser.ID, &req.FromUser.Username, &req.FromUser.Email, &req.FromUser.Avatar,
			&req.FromUser.IsOnline, &req.FromUser.LastSeen, &req.FromUser.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		requests = append(requests, req)
	}
	return requests, nil
}

func (r *FriendRepository) UpdateRequestStatus(requestID, status string) error {
	query := `UPDATE friend_requests SET status = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.Exec(query, status, time.Now(), requestID)
	return err
}

func (r *FriendRepository) CreateFriendship(friend *model.Friend) error {
	query := `
		INSERT INTO friends (id, user_id, friend_id, created_at)
		VALUES ($1, $2, $3, $4)
	`
	_, err := r.db.Exec(query, friend.ID, friend.UserID, friend.FriendID, friend.CreatedAt)
	return err
}

func (r *FriendRepository) AreFriends(userID1, userID2 string) (bool, error) {
	query := `
		SELECT COUNT(*) FROM friends
		WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)
	`
	var count int
	err := r.db.QueryRow(query, userID1, userID2).Scan(&count)
	return count > 0, err
}

func (r *FriendRepository) GetFriends(userID string) ([]*model.User, error) {
	query := `
		SELECT u.id, u.username, u.email, u.avatar, u.is_online, u.last_seen, u.created_at
		FROM friends f
		JOIN users u ON f.friend_id = u.id
		WHERE f.user_id = $1
		UNION
		SELECT u.id, u.username, u.email, u.avatar, u.is_online, u.last_seen, u.created_at
		FROM friends f
		JOIN users u ON f.user_id = u.id
		WHERE f.friend_id = $1
		ORDER BY last_seen DESC
	`
	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var friends []*model.User
	for rows.Next() {
		user := &model.User{}
		err := rows.Scan(&user.ID, &user.Username, &user.Email, &user.Avatar, &user.IsOnline, &user.LastSeen, &user.CreatedAt)
		if err != nil {
			return nil, err
		}
		friends = append(friends, user)
	}
	return friends, nil
}

func (r *FriendRepository) DeleteFriendship(userID1, userID2 string) error {
	query := `
		DELETE FROM friends
		WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)
	`
	_, err := r.db.Exec(query, userID1, userID2)
	return err
}

func (r *FriendRepository) DeleteRequest(requestID string) error {
	query := `DELETE FROM friend_requests WHERE id = $1`
	_, err := r.db.Exec(query, requestID)
	return err
}

// Message Repository
type MessageRepository struct {
	db *sql.DB
}

func NewMessageRepository(db *sql.DB) *MessageRepository {
	return &MessageRepository{db: db}
}

func (r *MessageRepository) Create(msg *model.Message) error {
	query := `
		INSERT INTO messages (id, sender_id, receiver_id, group_id, content, type, status, reply_to_id, is_recalled, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`
	_, err := r.db.Exec(query, msg.ID, msg.SenderID, msg.ReceiverID, msg.GroupID, msg.Content, msg.Type, msg.Status, msg.ReplyToID, msg.IsRecalled, msg.CreatedAt, msg.UpdatedAt)
	return err
}

func (r *MessageRepository) GetByID(id string) (*model.Message, error) {
	query := `
		SELECT id, sender_id, receiver_id, group_id, content, type, status, reply_to_id, is_recalled, created_at, updated_at
		FROM messages WHERE id = $1
	`
	msg := &model.Message{}
	var receiverID, groupID, replyToID sql.NullString
	err := r.db.QueryRow(query, id).Scan(
		&msg.ID, &msg.SenderID, &receiverID, &groupID, &msg.Content, &msg.Type, &msg.Status,
		&replyToID, &msg.IsRecalled, &msg.CreatedAt, &msg.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	msg.ReceiverID = receiverID.String
	msg.GroupID = groupID.String
	msg.ReplyToID = replyToID.String
	return msg, err
}

func (r *MessageRepository) GetPrivateMessages(userID1, userID2 string, limit, offset int) ([]*model.Message, error) {
	query := `
		SELECT id, sender_id, receiver_id, group_id, content, type, status, reply_to_id, is_recalled, created_at, updated_at
		FROM messages
		WHERE (sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1)
		AND group_id IS NULL
		ORDER BY created_at DESC
		LIMIT $3 OFFSET $4
	`
	rows, err := r.db.Query(query, userID1, userID2, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return r.scanMessages(rows)
}

func (r *MessageRepository) GetGroupMessages(groupID string, limit, offset int) ([]*model.Message, error) {
	query := `
		SELECT id, sender_id, receiver_id, group_id, content, type, status, reply_to_id, is_recalled, created_at, updated_at
		FROM messages
		WHERE group_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.db.Query(query, groupID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	return r.scanMessages(rows)
}

func (r *MessageRepository) scanMessages(rows *sql.Rows) ([]*model.Message, error) {
	var messages []*model.Message
	for rows.Next() {
		msg := &model.Message{}
		var receiverID, groupID, replyToID sql.NullString
		err := rows.Scan(
			&msg.ID, &msg.SenderID, &receiverID, &groupID, &msg.Content, &msg.Type, &msg.Status,
			&replyToID, &msg.IsRecalled, &msg.CreatedAt, &msg.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		msg.ReceiverID = receiverID.String
		msg.GroupID = groupID.String
		msg.ReplyToID = replyToID.String
		messages = append(messages, msg)
	}
	return messages, nil
}

func (r *MessageRepository) UpdateStatus(id, status string) error {
	query := `UPDATE messages SET status = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.Exec(query, status, time.Now(), id)
	return err
}

func (r *MessageRepository) Recall(id string) error {
	query := `UPDATE messages SET is_recalled = true, updated_at = $1 WHERE id = $2`
	_, err := r.db.Exec(query, time.Now(), id)
	return err
}

func (r *MessageRepository) GetLastMessage(userID1, userID2 string) (*model.Message, error) {
	query := `
		SELECT id, sender_id, receiver_id, group_id, content, type, status, reply_to_id, is_recalled, created_at, updated_at
		FROM messages
		WHERE (sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1)
		AND group_id IS NULL
		ORDER BY created_at DESC
		LIMIT 1
	`
	msg := &model.Message{}
	var receiverID, groupID, replyToID sql.NullString
	err := r.db.QueryRow(query, userID1, userID2).Scan(
		&msg.ID, &msg.SenderID, &receiverID, &groupID, &msg.Content, &msg.Type, &msg.Status,
		&replyToID, &msg.IsRecalled, &msg.CreatedAt, &msg.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	msg.ReceiverID = receiverID.String
	msg.GroupID = groupID.String
	msg.ReplyToID = replyToID.String
	return msg, err
}

func (r *MessageRepository) GetUnreadCount(chatID, userID string) (int, error) {
	query := `
		SELECT COUNT(*) FROM messages
		WHERE receiver_id = $1 AND sender_id = $2 AND status != 'read'
	`
	var count int
	err := r.db.QueryRow(query, userID, chatID).Scan(&count)
	return count, err
}

// Group Repository
type GroupRepository struct {
	db *sql.DB
}

func NewGroupRepository(db *sql.DB) *GroupRepository {
	return &GroupRepository{db: db}
}

func (r *GroupRepository) Create(group *model.Group) error {
	query := `
		INSERT INTO groups (id, name, description, avatar, owner_id, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err := r.db.Exec(query, group.ID, group.Name, group.Description, group.Avatar, group.OwnerID, group.CreatedAt)
	return err
}

func (r *GroupRepository) GetByID(id string) (*model.Group, error) {
	query := `
		SELECT id, name, description, avatar, owner_id, created_at, updated_at
		FROM groups WHERE id = $1
	`
	group := &model.Group{}
	err := r.db.QueryRow(query, id).Scan(
		&group.ID, &group.Name, &group.Description, &group.Avatar, &group.OwnerID, &group.CreatedAt, &group.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return group, err
}

func (r *GroupRepository) GetUserGroups(userID string) ([]*model.Group, error) {
	query := `
		SELECT g.id, g.name, g.description, g.avatar, g.owner_id, g.created_at, g.updated_at
		FROM groups g
		JOIN group_members gm ON g.id = gm.group_id
		WHERE gm.user_id = $1
		ORDER BY g.created_at DESC
	`
	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []*model.Group
	for rows.Next() {
		group := &model.Group{}
		err := rows.Scan(&group.ID, &group.Name, &group.Description, &group.Avatar, &group.OwnerID, &group.CreatedAt, &group.UpdatedAt)
		if err != nil {
			return nil, err
		}
		groups = append(groups, group)
	}
	return groups, nil
}

func (r *GroupRepository) AddMember(member *model.GroupMember) error {
	query := `
		INSERT INTO group_members (id, group_id, user_id, role, joined_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	_, err := r.db.Exec(query, member.ID, member.GroupID, member.UserID, member.Role, member.JoinedAt)
	return err
}

func (r *GroupRepository) GetMembers(groupID string) ([]*model.GroupMember, error) {
	query := `
		SELECT gm.id, gm.group_id, gm.user_id, gm.role, gm.joined_at,
			   u.id, u.username, u.email, u.avatar, u.is_online, u.last_seen, u.created_at
		FROM group_members gm
		JOIN users u ON gm.user_id = u.id
		WHERE gm.group_id = $1
		ORDER BY gm.joined_at ASC
	`
	rows, err := r.db.Query(query, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var members []*model.GroupMember
	for rows.Next() {
		member := &model.GroupMember{User: &model.User{}}
		err := rows.Scan(
			&member.ID, &member.GroupID, &member.UserID, &member.Role, &member.JoinedAt,
			&member.User.ID, &member.User.Username, &member.User.Email, &member.User.Avatar,
			&member.User.IsOnline, &member.User.LastSeen, &member.User.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		members = append(members, member)
	}
	return members, nil
}

func (r *GroupRepository) RemoveMember(groupID, userID string) error {
	query := `DELETE FROM group_members WHERE group_id = $1 AND user_id = $2`
	_, err := r.db.Exec(query, groupID, userID)
	return err
}

func (r *GroupRepository) IsMember(groupID, userID string) (bool, error) {
	query := `SELECT COUNT(*) FROM group_members WHERE group_id = $1 AND user_id = $2`
	var count int
	err := r.db.QueryRow(query, groupID, userID).Scan(&count)
	return count > 0, err
}

// Call Repository
type CallRepository struct {
	db *sql.DB
}

func NewCallRepository(db *sql.DB) *CallRepository {
	return &CallRepository{db: db}
}

func (r *CallRepository) Create(call *model.Call) error {
	query := `
		INSERT INTO calls (id, caller_id, callee_id, type, status, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err := r.db.Exec(query, call.ID, call.CallerID, call.CalleeID, call.Type, call.Status, call.CreatedAt)
	return err
}

func (r *CallRepository) GetByID(id string) (*model.Call, error) {
	query := `
		SELECT id, caller_id, callee_id, type, status, created_at, started_at, ended_at, duration
		FROM calls WHERE id = $1
	`
	call := &model.Call{}
	err := r.db.QueryRow(query, id).Scan(
		&call.ID, &call.CallerID, &call.CalleeID, &call.Type, &call.Status,
		&call.CreatedAt, &call.StartedAt, &call.EndedAt, &call.Duration,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return call, err
}

func (r *CallRepository) UpdateStatus(id, status string, startedAt, endedAt *time.Time, duration int) error {
	query := `UPDATE calls SET status = $1, started_at = $2, ended_at = $3, duration = $4 WHERE id = $5`
	_, err := r.db.Exec(query, status, startedAt, endedAt, duration, id)
	return err
}

// Helper function to generate UUID
func GenerateUUID() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}
