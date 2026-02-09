import 'package:ecp/src/types/activities.dart';

/// A combination of an activity with its recipients
typedef ActivityWithMetaData = ({StableActivity activity, Uri actor, Uri id});
typedef CapabilitiesWithTime = ({
  Map<String, dynamic> capabilites,
  DateTime timestamp,
});
