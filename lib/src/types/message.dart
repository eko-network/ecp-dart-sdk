class Message {
  final Uri from;
  final Uri to;
  final Uri id;
  final String content;

  Message({
    required this.from,
    required this.to,
    required this.content,
    required this.id,
  });
}
