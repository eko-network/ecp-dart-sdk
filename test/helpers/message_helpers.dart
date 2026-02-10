import 'package:ecp/ecp.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

class MessageFactory {
  static final _uuid = Uuid();

  static Create note(String content, Uri to, {UuidValue? inReplyTo}) {
    return Create(
      base: ActivityBase(id: _uuid.v4obj(), to: to),
      object: Note(
        base: ObjectBase(id: _uuid.v4obj(), inReplyTo: inReplyTo),
        content: content,
      ),
    );
  }
}

class MessageAssertions {
  static void expectNoteContent(
    List<ActivityWithMetaData> messages,
    String expectedContent, {
    int index = 0,
  }) {
    // Filter out Delivered activities to get only Create activities
    final createMessages = messages.where((m) => m.activity is Create).toList();

    expect(
      createMessages.length,
      greaterThan(index),
      reason:
          'Expected at least ${index + 1} Create messages, but found ${createMessages.length}',
    );

    final activity = createMessages[index].activity;
    expect(activity, isA<Create>());
    final object = (activity as Create).object;
    expect(object, isA<Note>());
    expect((object as Note).content, expectedContent);
  }
}
