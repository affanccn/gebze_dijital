import 'package:cloud_firestore/cloud_firestore.dart';

class NeighborhoodSeeder {
  static const collection = 'neighborhood_works';

  static Future<int> seed() async {
    final trNow = DateTime.now().toUtc().add(const Duration(hours: 3));

    Timestamp at(int dayOffset, [int hour = 9]) => Timestamp.fromDate(
      DateTime.utc(trNow.year, trNow.month, trNow.day + dayOffset, hour - 3),
    );

    final items = <Map<String, dynamic>>[
      {
        'title': 'Doğalgaz Hattı Kazı Çalışması',
        'description': 'Yeni doğalgaz bağlantı hattı için cadde boyunca kazı yapılacaktır. Geçici trafik düzenlemesi uygulanır.',
        'category': 'kazi',
        'neighborhood': 'Güzeller',
        'address': 'Bahar Cd.',
        'unit': 'Fen İşleri Müdürlüğü',
        'startDate': at(-2),
        'endDate': at(3, 18),
      },
      {
        'title': 'Yağmur Suyu Hattı Yenileme',
        'description': 'Sık su baskını yaşanan bölgede eski yağmur suyu hattı değiştirilmektedir.',
        'category': 'altyapi',
        'neighborhood': 'Mustafapaşa',
        'address': '712. Sokak',
        'unit': 'İSU',
        'startDate': at(-1),
        'endDate': at(5, 17),
      },
      {
        'title': 'Asfalt Yenileme ve Yol Bakımı',
        'description': 'Bozulan asfalt tabakası sıyrılıp yeniden serilecektir. Çalışma süresince yol tek şeritten kullanılabilir.',
        'category': 'yol_bakim',
        'neighborhood': 'Osman Yılmaz',
        'address': 'Atatürk Cd.',
        'unit': 'Yol Bakım Birimi',
        'startDate': at(0, 8),
        'endDate': at(2, 19),
      },
      {
        'title': 'Park Peyzaj ve Ağaç Budama',
        'description': 'Mahalle parkında peyzaj düzenlemesi ve tehlike oluşturan dalların budanması yapılacaktır.',
        'category': 'cevre',
        'neighborhood': 'Arapçeşme',
        'address': 'Çınar Parkı',
        'unit': 'Park ve Bahçeler Müdürlüğü',
        'startDate': at(-3),
        'endDate': at(1, 16),
      },
      {
        'title': 'Elektrik Kablo Kanalı Kazısı',
        'description': 'Yeraltı elektrik kablo kanalı için kaldırım ve yol kenarında kazı yapılacaktır.',
        'category': 'kazi',
        'neighborhood': 'Hacıhalil',
        'address': 'Fatih Cd.',
        'unit': 'Fen İşleri Müdürlüğü',
        'startDate': at(-1),
        'endDate': at(4, 18),
      },
      {
        'title': 'İçme Suyu Ana Hat Bakımı',
        'description': 'Ana isale hattında bakım yapılacaktır. Kısa süreli su kesintisi yaşanabilir.',
        'category': 'altyapi',
        'neighborhood': 'Güzeller',
        'address': 'Gül Sk.',
        'unit': 'İSU',
        'startDate': at(0, 10),
        'endDate': at(1, 15),
      },

      {
        'title': 'Kanalizasyon Hattı Genişletme',
        'description': 'Artan nüfus nedeniyle mevcut kanalizasyon hattı daha büyük çapta yenilenecektir.',
        'category': 'altyapi',
        'neighborhood': 'Mevlana',
        'address': 'Sanayi Cd.',
        'unit': 'İSU',
        'startDate': at(2),
        'endDate': at(9, 18),
      },
      {
        'title': 'Kaldırım Düzenleme ve Bordür Yenileme',
        'description': 'Yaya güvenliği için bozulan kaldırımlar ve bordürler yenilenecektir.',
        'category': 'yol_bakim',
        'neighborhood': 'Mustafapaşa',
        'address': 'İstasyon Cd.',
        'unit': 'Yol Bakım Birimi',
        'startDate': at(3),
        'endDate': at(8, 18),
      },
      {
        'title': 'Cadde Çizgi ve Yaya Geçidi Boyama',
        'description':
            'Silinen yol çizgileri ve yaya geçitleri yeniden boyanacaktır.',
        'category': 'yol_bakim',
        'neighborhood': 'Güzeller',
        'address': 'Bahar Cd. ve çevresi',
        'unit': 'Trafik Hizmetleri',
        'startDate': at(4, 7),
        'endDate': at(5, 12),
      },
      {
        'title': 'Çöp Konteyneri Yenileme ve Yer Altı Sistemi',
        'description': 'Eski konteynerler kaldırılarak yer altı çöp toplama sistemi kurulacaktır.',
        'category': 'cevre',
        'neighborhood': 'Osman Yılmaz',
        'address': 'Meydan Sk.',
        'unit': 'Temizlik İşleri Müdürlüğü',
        'startDate': at(5),
        'endDate': at(7, 17),
      },
      {
        'title': 'Fiber Altyapı Kazısı',
        'description': 'Mahallede fiber internet altyapısı için kaldırım kenarında kazı yapılacaktır.',
        'category': 'kazi',
        'neighborhood': 'Köşklü Çeşme',
        'address': 'Dere Sk.',
        'unit': 'Fen İşleri Müdürlüğü',
        'startDate': at(6),
        'endDate': at(12, 18),
      },
      {
        'title': 'Dere Yatağı Temizliği',
        'description': 'Taşkın riskine karşı dere yatağındaki tortu ve atıklar temizlenecektir.',
        'category': 'cevre',
        'neighborhood': 'Eskihisar',
        'address': 'Sahil Yolu',
        'unit': 'Çevre Koruma Müdürlüğü',
        'startDate': at(7),
        'endDate': at(10, 17),
      },
      {
        'title': 'Sokak Aydınlatma Kablo Değişimi',
        'description': 'Arızalı sokak aydınlatma kabloları değiştirilecek, lambalar LED ile yenilenecektir.',
        'category': 'altyapi',
        'neighborhood': 'Arapçeşme',
        'address': 'Lale Sk.',
        'unit': 'Elektrik İşleri',
        'startDate': at(8),
        'endDate': at(11, 18),
      },
      {
        'title': 'Parke Taşı Yol Onarımı',
        'description':
            'Çöken parke taşı yol kesimleri sökülüp yeniden döşenecektir.',
        'category': 'yol_bakim',
        'neighborhood': 'Hacıhalil',
        'address': 'Çarşı Sk.',
        'unit': 'Yol Bakım Birimi',
        'startDate': at(9),
        'endDate': at(14, 18),
      },
      {
        'title': 'Mahalle Parkı Fidan Dikimi',
        'description':
            'Mahalle sakinlerinin katılımıyla fidan dikim etkinliği.',
        'category': 'cevre',
        'neighborhood': 'Mevlana',
        'address': 'Yeşil Park',
        'unit': 'Park ve Bahçeler Müdürlüğü',
        'startDate': at(10, 10),
        'endDate': at(10, 14),
      },

      {
        'title': '[GEÇMİŞ] Asfalt Yama Çalışması',
        'description': 'Tamamlanmış çalışma. Listede görünmemesi gerekir.',
        'category': 'yol_bakim',
        'neighborhood': 'Güzeller',
        'address': 'Eski Cd.',
        'unit': 'Yol Bakım Birimi',
        'startDate': at(-15),
        'endDate': at(-10, 18),
      },
      {
        'title': '[GEÇMİŞ] Su Hattı Kazısı',
        'description': 'Tamamlanmış çalışma. Listede görünmemesi gerekir.',
        'category': 'kazi',
        'neighborhood': 'Mustafapaşa',
        'address': 'Eski Sk.',
        'unit': 'İSU',
        'startDate': at(-20),
        'endDate': at(-14, 18),
      },
      {
        'title': '[GEÇMİŞ] Park Temizlik Çalışması',
        'description': 'Tamamlanmış çalışma. Listede görünmemesi gerekir.',
        'category': 'cevre',
        'neighborhood': 'Osman Yılmaz',
        'address': 'Merkez Park',
        'unit': 'Temizlik İşleri Müdürlüğü',
        'startDate': at(-8),
        'endDate': at(-5, 17),
      },
      {
        'title': '[GEÇMİŞ] Kablo Değişimi',
        'description': 'Dün biten çalışma. Listede görünmemesi gerekir.',
        'category': 'altyapi',
        'neighborhood': 'Arapçeşme',
        'address': 'Eski Cd.',
        'unit': 'Elektrik İşleri',
        'startDate': at(-4),
        'endDate': at(-1, 8),
      },
    ];

    final col = FirebaseFirestore.instance.collection(collection);
    final batch = FirebaseFirestore.instance.batch();

    for (var i = 0; i < items.length; i++) {
      final id = 'demo_${(i + 1).toString().padLeft(2, '0')}';
      batch.set(col.doc(id), items[i]);
    }
    await batch.commit();
    return items.length;
  }
}
