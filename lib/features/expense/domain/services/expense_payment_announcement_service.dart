import 'package:uuid/uuid.dart';

import '../../../chat/domain/entities/message.dart';
import '../../../chat/domain/usecases/send_message.dart';
import '../entities/expense.dart';
import '../entities/expense_split.dart';

class ExpensePaymentAnnouncementService {
  final SendMessage sendMessage;

  ExpensePaymentAnnouncementService({required this.sendMessage});

  Future<void> announceSplitPaid({
    required Expense expense,
    required ExpenseSplit split,
  }) async {
    final chatRoomId = expense.chatRoomId;
    if (chatRoomId == null || chatRoomId.isEmpty) {
      return;
    }

    final payerName = split.userName.trim().isEmpty
        ? 'Someone'
        : split.userName.trim();

    await sendMessage(
      SendMessageParams(
        message: Message(
          id: const Uuid().v4(),
          senderId: 'system',
          senderName: payerName,
          content:
              '$payerName paid RM ${split.amount.toStringAsFixed(2)} for ${expense.title}',
          chatRoomId: chatRoomId,
          timestamp: DateTime.now(),
          type: MessageType.system,
          sendStatus: MessageSendStatus.sending,
          eventData: {
            'expenseId': expense.id,
            'paidByUserId': split.userId,
            'excludedUserIds': [split.userId],
          },
        ),
      ),
    );
  }
}
