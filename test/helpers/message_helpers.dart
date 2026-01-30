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
    List<ActivityWithRecipients> messages,
    String expectedContent, {
    int index = 0,
  }) {
    expect(messages.length, greaterThan(index));
    final activity = messages[index].activity;
    expect(activity, isA<Create>());
    final object = (activity as Create).object;
    expect(object, isA<Note>());
    expect((object as Note).content, expectedContent);
  }
}
