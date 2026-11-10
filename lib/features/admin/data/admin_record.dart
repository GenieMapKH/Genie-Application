class AdminRecord {
  final Map<String, dynamic> values;
  const AdminRecord(this.values);

  String get id =>
      (values['id'] ??
              '${values['propertyId'] ?? ''}:${values['userId']}:${values['channel'] ?? ''}')
          .toString();

  String get title {
    if (values['purpose'] == 'LISTING_PUBLISH') return 'One-time property post';
    if (values['purpose'] == 'SUBSCRIPTION' || values['tier'] != null) {
      final tier = (values['subscriptionTier'] ?? values['tier'] ?? '')
          .toString();
      return tier.isEmpty
          ? 'Subscription'
          : '${tier[0].toUpperCase()}${tier.substring(1)} subscription';
    }
    final property = values['property'] as Map<String, dynamic>?;
    final username = values['username'] as String?;
    return (values['title'] ??
            (username == null ? null : '@$username') ??
            values['name'] ??
            property?['title'] ??
            values['reason'] ??
            values['purpose'] ??
            values['tier'] ??
            'Account')
        .toString();
  }

  String get subtitle {
    final account = values['account'] as Map<String, dynamic>?;
    return [
          values['name'],
          account?['username'] ?? account?['name'],
          values['status'],
          values['provider'],
          values['channel'],
          values['tier'],
          values['email'],
        ]
        .where((value) => value != null && value.toString().isNotEmpty)
        .join(' · ');
  }
}

typedef AdminRecordsPage = ({List<AdminRecord> items, int? nextOffset});
