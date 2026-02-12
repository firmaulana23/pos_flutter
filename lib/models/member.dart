class Member {
  final int id;
  final String fullName;
  final String? phoneNumber;
  final String memberCode;
  final int points;
  final double discount; // Added discount
  final DateTime expiredDate;

  Member({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    required this.memberCode, // Renamed from cardNumber
    required this.points,
    required this.discount, // Added discount
    required this.expiredDate,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    // Handle nested member data if present
    final memberData = json['member'] ?? json;

    return Member(
      id: memberData['id'],
      fullName: memberData['full_name'],
      phoneNumber: memberData['phone_number'],
      memberCode:
          memberData['member_code'] ??
          memberData['card_number'], // Handle both keys
      points: memberData['points'] ?? 0,
      discount:
          (memberData['discount_percent'] as num? ??
                  memberData['discount'] as num? ??
                  0.0)
              .toDouble(), // Added discount
      expiredDate: DateTime.parse(memberData['expired_date']),
    );
  }
}
