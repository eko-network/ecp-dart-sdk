import 'package:ecp/src/types/activities.dart';

/// A combination of an activity with its recipients
typedef ActivityWithRecipients = ({
  StableActivity activity,
  List<Uri> to,
  Uri from,
});
