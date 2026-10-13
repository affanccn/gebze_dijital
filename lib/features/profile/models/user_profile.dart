import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String neighborhood;
  final String address;
  final String tcNo;
  final String avatarUrl;
  final String role;
  final bool isVerified;
  final String language; // 'tr', 'en', 'ar'
  final bool isLargeFont;
  final String themeMode; // 'light', 'dark', 'system'
  final Map<String, bool> notificationPreferences;
  final int totalRequests;
  final int totalSuggestions;
  final int totalSupported;
  final int totalSaved;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.neighborhood,
    required this.address,
    required this.tcNo,
    required this.avatarUrl,
    this.role = 'citizen',
    this.isVerified = true,
    this.language = 'tr',
    this.isLargeFont = false,
    this.themeMode = 'light',
    this.notificationPreferences = const {
      'push': true,
      'sms': true,
      'outages': true,
      'emergency': true,
      'news': true,
      'sozSende': true,
    },
    this.totalRequests = 3,
    this.totalSuggestions = 2,
    this.totalSupported = 7,
    this.totalSaved = 4,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.defaultProfile() {
    return UserProfile(
      id: 'default_citizen',
      fullName: 'Ahmet Yılmaz',
      email: 'ahmet.yilmaz@gebze.bel.tr',
      phoneNumber: '0532 456 78 90',
      neighborhood: 'Mustafapaşa',
      address: 'Mustafapaşa Mah. Şehit Yılmaz Cad. No: 18/4 Gebze',
      tcNo: '12345678901',
      avatarUrl: '',
      role: 'citizen',
      isVerified: true,
      language: 'tr',
      isLargeFont: false,
      themeMode: 'light',
      notificationPreferences: const {
        'push': true,
        'sms': true,
        'outages': true,
        'emergency': true,
        'news': true,
        'sozSende': true,
      },
      totalRequests: 3,
      totalSuggestions: 2,
      totalSupported: 7,
      totalSaved: 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final notifs = data['notificationPreferences'];
    Map<String, bool> parsedNotifs = {
      'push': true,
      'sms': true,
      'outages': true,
      'emergency': true,
      'news': true,
      'sozSende': true,
    };
    if (notifs is Map) {
      notifs.forEach((k, v) {
        if (v is bool) parsedNotifs[k.toString()] = v;
      });
    }

    DateTime? parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d);
      return null;
    }

    return UserProfile(
      id: doc.id,
      fullName: data['fullName'] ?? 'Ahmet Yılmaz',
      email: data['email'] ?? 'ahmet.yilmaz@gebze.bel.tr',
      phoneNumber: data['phoneNumber'] ?? '0532 456 78 90',
      neighborhood: data['neighborhood'] ?? 'Mustafapaşa',
      address: data['address'] ?? 'Mustafapaşa Mah. No: 18 Gebze',
      tcNo: data['tcNo'] ?? '12345678901',
      avatarUrl: data['avatarUrl'] ?? '',
      role: data['role'] ?? 'citizen',
      isVerified: data['isVerified'] ?? true,
      language: data['language'] ?? 'tr',
      isLargeFont: data['isLargeFont'] ?? false,
      themeMode: data['themeMode'] ?? 'light',
      notificationPreferences: parsedNotifs,
      totalRequests: (data['totalRequests'] ?? 3) as int,
      totalSuggestions: (data['totalSuggestions'] ?? 2) as int,
      totalSupported: (data['totalSupported'] ?? 7) as int,
      totalSaved: (data['totalSaved'] ?? 4) as int,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'neighborhood': neighborhood,
      'address': address,
      'tcNo': tcNo,
      'avatarUrl': avatarUrl,
      'role': role,
      'isVerified': isVerified,
      'language': language,
      'isLargeFont': isLargeFont,
      'themeMode': themeMode,
      'notificationPreferences': notificationPreferences,
      'totalRequests': totalRequests,
      'totalSuggestions': totalSuggestions,
      'totalSupported': totalSupported,
      'totalSaved': totalSaved,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? neighborhood,
    String? address,
    String? tcNo,
    String? avatarUrl,
    String? role,
    bool? isVerified,
    String? language,
    bool? isLargeFont,
    String? themeMode,
    Map<String, bool>? notificationPreferences,
    int? totalRequests,
    int? totalSuggestions,
    int? totalSupported,
    int? totalSaved,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      neighborhood: neighborhood ?? this.neighborhood,
      address: address ?? this.address,
      tcNo: tcNo ?? this.tcNo,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      language: language ?? this.language,
      isLargeFont: isLargeFont ?? this.isLargeFont,
      themeMode: themeMode ?? this.themeMode,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      totalRequests: totalRequests ?? this.totalRequests,
      totalSuggestions: totalSuggestions ?? this.totalSuggestions,
      totalSupported: totalSupported ?? this.totalSupported,
      totalSaved: totalSaved ?? this.totalSaved,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class UserActivityItem {
  final String id;
  final String type; // 'talep', 'oneri', 'destek', 'kayit'
  final String title;
  final String description;
  final String date;
  final String status; // 'İnceleniyor', 'İşleme Alındı', 'Çözüldü', 'Yayında', 'Desteklendi'
  final String category;

  const UserActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.category,
  });

  factory UserActivityItem.fromMap(Map<String, dynamic> map, String id) {
    return UserActivityItem(
      id: id,
      type: map['type'] ?? 'talep',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      status: map['status'] ?? 'İnceleniyor',
      category: map['category'] ?? 'Genel',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'date': date,
      'status': status,
      'category': category,
    };
  }
}
