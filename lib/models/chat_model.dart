import '../core/utils/data_parser.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String senderRole;
  final String content;
  final String time;
  final DateTime timestamp;
  final String? channelId;
  final String? receiverId;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.senderRole,
    required this.content,
    required this.time,
    required this.timestamp,
    this.channelId,
    this.receiverId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'senderRole': senderRole,
      'content': content,
      'time': time,
      'timestamp': timestamp.toIso8601String(),
      'channelId': channelId,
      'receiverId': receiverId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderAvatar: map['senderAvatar'] as String? ?? '',
      senderRole: map['senderRole'] as String? ?? '',
      content: map['content'] as String? ?? '',
      time: map['time'] as String? ?? '',
      timestamp: DataParser.parseDateTime(map['timestamp']),
      channelId: map['channelId'] as String?,
      receiverId: map['receiverId'] as String?,
    );
  }
}

class ChatChannel {
  final String id;
  final String name;
  final String description;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;

  const ChatChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  ChatChannel copyWith({
    String? id,
    String? name,
    String? description,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
    };
  }

  factory ChatChannel.fromMap(Map<String, dynamic> map) {
    return ChatChannel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: map['lastMessageTime'] as String? ?? '',
      unreadCount: map['unreadCount'] as int? ?? 0,
    );
  }
}
