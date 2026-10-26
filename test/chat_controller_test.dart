import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cilalutask_mobile/models/chat_model.dart';
import 'package:cilalutask_mobile/state/chat_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatController Unit Tests', () {
    test('Initializes with default channels and messages', () {
      final controller = ChatController();
      addTearDown(() => controller.dispose());

      expect(controller.channels.isNotEmpty, isTrue);
      expect(controller.messages.isNotEmpty, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test('Filter messages by channel and direct messages', () {
      final controller = ChatController();
      addTearDown(() => controller.dispose());

      final channelMsgs = controller.getMessagesForChannel('ch-umum');
      expect(channelMsgs.isNotEmpty, isTrue);
      expect(channelMsgs.every((m) => m.channelId == 'ch-umum'), isTrue);

      final directMsgs = controller.getDirectMessagesWith('emp-1', 'admin-1');
      expect(directMsgs, isA<List<ChatMessage>>());
    });

    test(
      'sendChatMessage adds message and updates channel lastMessage',
      () async {
        final controller = ChatController();
        addTearDown(() => controller.dispose());

        final newMsg = ChatMessage(
          id: 'msg-test-1',
          channelId: 'ch-umum',
          senderId: 'admin-1',
          senderName: 'Sarah',
          senderAvatar: '',
          senderRole: 'Admin',
          content: 'Halo tim testing!',
          time: '12:00',
          timestamp: DateTime.now(),
        );

        await controller.sendChatMessage('TEST-CO', newMsg);

        expect(controller.messages.last.id, 'msg-test-1');
        final updatedCh = controller.channels.firstWhere(
          (c) => c.id == 'ch-umum',
        );
        expect(updatedCh.lastMessage, 'Halo tim testing!');
      },
    );

    test('deleteChatMessage removes message correctly', () async {
      final controller = ChatController();
      addTearDown(() => controller.dispose());

      final firstMsgId = controller.messages.first.id;
      await controller.deleteChatMessage('TEST-CO', firstMsgId);

      expect(controller.messages.any((m) => m.id == firstMsgId), isFalse);
    });

    test('addChannel adds channel to list', () async {
      final controller = ChatController();
      addTearDown(() => controller.dispose());

      await controller.addChannel(
        'TEST-CO',
        'rnd-infrastruktur',
        'Kanal khusus RnD',
      );

      expect(
        controller.channels.any((c) => c.name == '#rnd-infrastruktur'),
        isTrue,
      );
    });

    test('clear resets channels and messages', () {
      final controller = ChatController();
      addTearDown(() => controller.dispose());

      controller.clear();
      expect(controller.channels.isEmpty, isTrue);
      expect(controller.messages.isEmpty, isTrue);
    });
  });
}
