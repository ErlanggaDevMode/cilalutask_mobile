import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import '../repositories/cilalu_repository.dart';

/// Dedicated controller for Chat channels, messages, and real-time conversation streams.
class ChatController extends ChangeNotifier {
  final CilaluRepository _repository;

  List<ChatChannel> _channels = [
    const ChatChannel(
      id: 'ch-umum',
      name: '#umum',
      description: 'Saluran pengumuman dan diskusi seluruh divisi',
      lastMessage: 'Halo tim, mohon cek dashboard tugas & SOP hari ini ya.',
      lastMessageTime: '10:15',
      unreadCount: 2,
    ),
    const ChatChannel(
      id: 'ch-ops',
      name: '#operasional-gudang',
      description: 'Koordinasi stok opname dan logistik cikarang',
      lastMessage: 'Pemeriksaan modul TV rack A1-A12 telah selesai.',
      lastMessageTime: '09:45',
      unreadCount: 0,
    ),
    const ChatChannel(
      id: 'ch-it',
      name: '#it-tech-core',
      description: 'DevOps, database Aurora, dan keamanan cloud server',
      lastMessage: 'Replication slot AWS DMS aktif tanpa kendala.',
      lastMessageTime: '09:30',
      unreadCount: 1,
    ),
    const ChatChannel(
      id: 'ch-marketing',
      name: '#pemasaran-kreatif',
      description: 'Kampanye promo mid-year sale dan konten media sosial',
      lastMessage: 'Visual master banner 3 format telah rampung.',
      lastMessageTime: 'Kemarin',
      unreadCount: 0,
    ),
    const ChatChannel(
      id: 'ch-finance',
      name: '#finance-akuntansi',
      description: 'Rekonsiliasi pajak bulanan dan pengajuan klaim staf',
      lastMessage: 'File CSV SPT masa siap di-upload ke portal DJP.',
      lastMessageTime: 'Kemarin',
      unreadCount: 0,
    ),
  ];

  List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg-1',
      channelId: 'ch-umum',
      senderId: 'admin-1',
      senderName: 'Sarah Pratama',
      senderAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=256',
      senderRole: 'Admin / Manager',
      content: 'Selamat pagi seluruh tim Cilalutask! Mohon cek dashboard tugas masing-masing dan verifikasi kepatuhan SOP K3 terbaru.',
      time: '08:30',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatMessage(
      id: 'msg-2',
      channelId: 'ch-umum',
      senderId: 'emp-1',
      senderName: 'Budi Santoso',
      senderAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=256',
      senderRole: 'Staf Operasional',
      content: 'Siap Bu Sarah, tim gudang Cikarang sedang menyelesaikan checklist Pallet B4. Dokumen SOP sudah saya baca dan konfirmasi.',
      time: '08:45',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
    ),
    ChatMessage(
      id: 'msg-3',
      channelId: 'ch-ops',
      senderId: 'emp-1',
      senderName: 'Budi Santoso',
      senderAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=256',
      senderRole: 'Staf Operasional',
      content: 'Laporan forklift: Unit 2 baterai 100%, siap untuk pemindahan material rack A12.',
      time: '09:00',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    ChatMessage(
      id: 'msg-4',
      channelId: 'ch-it',
      senderId: 'emp-3',
      senderName: 'Kevin Maulana',
      senderAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=256',
      senderRole: 'Tech Lead / DevOps',
      content: 'Update migrasi AWS DMS: CDC replication aktif, lag 0 detik. Database server berjalan optimal.',
      time: '09:30',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ChatMessage(
      id: 'msg-5',
      channelId: 'ch-marketing',
      senderId: 'emp-2',
      senderName: 'Nadia Salsabila',
      senderAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=256',
      senderRole: 'Desainer Grafis',
      content: 'Master banner Mid-Year Sale sudah saya kirimkan di folder Google Drive, mohon review tim lead.',
      time: '09:40',
      timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
    ChatMessage(
      id: 'msg-6',
      channelId: 'ch-finance',
      senderId: 'emp-4',
      senderName: 'Rina Kusuma',
      senderAvatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&q=80&w=256',
      senderRole: 'Finance & Tax Officer',
      content: 'Draft SPT Masa PPh 21 sudah direkonsiliasi. Pengajuan reimbursement staf diproses siang ini.',
      time: '09:55',
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
  ];

  StreamSubscription<List<ChatMessage>>? _chatSubscription;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  ChatController({
    CilaluRepository? repository,
    List<ChatChannel>? initialChannels,
    List<ChatMessage>? initialMessages,
  }) : _repository = repository ?? CilaluRepository() {
    if (initialChannels != null) {
      _channels = List.from(initialChannels);
    }
    if (initialMessages != null) {
      _messages = List.from(initialMessages);
    }
  }

  List<ChatChannel> get channels => List.unmodifiable(_channels);
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void setChannels(List<ChatChannel> channels) {
    _channels = List.from(channels);
    notifyListeners();
  }

  void setMessages(List<ChatMessage> messages) {
    _messages = List.from(messages);
    notifyListeners();
  }

  void clear() {
    cancelSubscription();
    _channels = [];
    _messages = [];
    _errorMessage = null;
    notifyListeners();
  }

  List<ChatMessage> getMessagesForChannel(String channelId) {
    return _messages.where((m) => m.channelId == channelId).toList();
  }

  List<ChatMessage> getDirectMessagesWith(String otherUserId, String myId) {
    return _messages.where((m) {
      return (m.senderId == myId && m.receiverId == otherUserId) ||
          (m.senderId == otherUserId && m.receiverId == myId);
    }).toList();
  }

  List<ChatMessage> messagesForChannel(String? channelId) {
    if (channelId == null) return _messages;
    return _messages.where((m) => m.channelId == channelId).toList();
  }

  Future<void> loadChatData(String companyCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedChannels = await _repository.getChannels(companyCode);
      if (loadedChannels.isNotEmpty) {
        _channels = loadedChannels;
      }

      final loadedMessages = await _repository.getMessages(companyCode);
      if (loadedMessages.isNotEmpty || companyCode != 'CILALU-88') {
        _messages = loadedMessages;
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('ChatController.loadChatData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startSubscription(String companyCode) {
    cancelSubscription();
    if (!_repository.isCloudAvailable) return;

    _chatSubscription = _repository.streamMessages(companyCode).listen((
      incoming,
    ) {
      if (incoming.isNotEmpty) {
        _messages = incoming;
        notifyListeners();
      }
    }, onError: (e) => debugPrint('Chat subscription error: $e'));
  }

  void cancelSubscription() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
  }

  Future<void> sendChatMessage(String companyCode, ChatMessage message) async {
    _messages = [..._messages, message];

    if (message.channelId != null) {
      _channels = _channels.map((ch) {
        if (ch.id == message.channelId) {
          return ch.copyWith(
            lastMessage: message.content,
            lastMessageTime: message.time,
          );
        }
        return ch;
      }).toList();
    }

    notifyListeners();

    try {
      await _repository.sendMessage(companyCode, message);
      await _repository.saveChannels(companyCode, _channels);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('ChatController.sendChatMessage repository error: $e');
    }
  }

  Future<void> deleteChatMessage(String companyCode, String messageId) async {
    _messages = _messages.where((m) => m.id != messageId).toList();
    notifyListeners();

    try {
      await _repository.deleteMessage(companyCode, messageId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('ChatController.deleteChatMessage repository error: $e');
    }
  }

  Future<void> addChannel(
    String companyCode,
    String name,
    String description,
  ) async {
    final newCh = ChatChannel(
      id: 'ch-${DateTime.now().millisecondsSinceEpoch}',
      name: name.startsWith('#') ? name : '#$name',
      description: description,
      lastMessage: 'Saluran baru dibuat.',
      lastMessageTime: 'Baru saja',
      unreadCount: 0,
    );
    _channels = [..._channels, newCh];
    notifyListeners();

    try {
      await _repository.saveChannels(companyCode, _channels);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('ChatController.addChannel repository error: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    cancelSubscription();
    super.dispose();
  }
}
