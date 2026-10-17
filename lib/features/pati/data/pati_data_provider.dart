import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pet_adoption.dart';
import '../models/feeding_point.dart';

/// Örnek / Yedek Sahiplendirme İlanları (Admin panelinden ya da Firestore'dan veri henüz gelmediyse veya çevrimdışıysa)
final List<PetAdoption> kFallbackPets = [
  const PetAdoption(
    id: 'sample-1',
    name: 'Pamuk',
    species: 'Kedi',
    breed: 'Tekir Melez',
    gender: 'Dişi',
    age: '6 Aylık',
    imageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80',
    description: 'Sokakta yaralı bulunup merkezimizde tedavisi tamamlandı. Çok uysal, insan canlısı ve oyuncu bir can dostumuz.',
    healthStatus:
        'Karma aşıları yapıldı, iç-dış parazit uygulandı, mikroçipli.',
    centerPhone: '(0262) 642 04 30',
  ),
  const PetAdoption(
    id: 'sample-2',
    name: 'Karabaş',
    species: 'Köpek',
    breed: 'Anadolu Çoban Melezi',
    gender: 'Erkek',
    age: '1.5 Yaşında',
    imageUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=800&q=80',
    description: 'Bahçeli bir yuvaya veya sevgi dolu bir aileye çok uygun. Temel eğitimleri merkezimiz eğitmenlerince verildi.',
    healthStatus: 'Kuduz ve karma aşıları tam, kısırlaştırıldı, çipli.',
    centerPhone: '(0262) 642 04 30',
  ),
  const PetAdoption(
    id: 'sample-3',
    name: 'Zeytin',
    species: 'Kedi',
    breed: 'Siyah Bombay Melezi',
    gender: 'Erkek',
    age: '1 Yaşında',
    imageUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?auto=format&fit=crop&w=800&q=80',
    description: 'Göz tedavisi tamamlandı, tamamen sağlığına kavuştu. Kucak delisi ve çok sakin.',
    healthStatus: 'Aşı takvimi tamamlandı, kısırlaştırıldı.',
    centerPhone: '(0262) 642 04 30',
  ),
  const PetAdoption(
    id: 'sample-4',
    name: 'Maya',
    species: 'Köpek',
    breed: 'Golden Melezi',
    gender: 'Dişi',
    age: '8 Aylık',
    imageUrl: 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=800&q=80',
    description: 'Terk edilmiş halde bulundu, rehabilitasyon merkezimizde sevgiyle büyütüldü. Çocuklarla ve diğer hayvanlarla çok iyi anlaşıyor.',
    healthStatus: 'Tüm gençlik aşıları ve parazit aşıları yapıldı.',
    centerPhone: '(0262) 642 04 30',
  ),
];

/// Gebze Mama ve Su Odakları Fallback Listesi
const List<FeedingPoint> kGebzeFeedingPoints = [
  FeedingPoint(
    id: 'fp-1',
    title: 'Gebze Kent Meydanı Besleme Odağı',
    neighborhood: 'Hacıhalil',
    address: 'Gebze Kent Meydanı Park Alanı Batı Çıkışı',
    latitude: 40.8031,
    longitude: 29.4312,
    type: 'Mama ve Otomatik Su Odağı',
    equipment: 'Güneş enerjili otomatik su kabı, paslanmaz çelik mama haznesi',
  ),
  FeedingPoint(
    id: 'fp-2',
    title: 'Millet Bahçesi Kedi Köyü & Besleme Noktası',
    neighborhood: 'Mevlana',
    address: 'Mevlana Mah. Issıkgöl Cad. Millet Bahçesi İçi',
    latitude: 40.8160,
    longitude: 29.4395,
    type: 'Kedi Köyü & Su İstasyonu',
    equipment: '4 katlı yalıtımlı kedi evi, taze su pınarı, kuru mama ünitesi',
  ),
  FeedingPoint(
    id: 'fp-3',
    title: 'Alaettin Kurt Stadyumu Çevresi Besleme Odağı',
    neighborhood: 'Gaziler',
    address: 'Şehit Fahrettin Çevik Parkı giriş kapısı yanı',
    latitude: 40.8095,
    longitude: 29.4445,
    type: 'Büyük Can Dostlar Mama ve Su Odağı',
    equipment: 'Geniş hazneli kuru mama besleme noktası ve temiz su kabı',
  ),
  FeedingPoint(
    id: 'fp-4',
    title: 'Eskihisar Sahil Parkı Besleme Noktası',
    neighborhood: 'Eskihisar',
    address: 'Eskihisar Sahil Kordon Yürüyüş Yolu başlangıcı',
    latitude: 40.7718,
    longitude: 29.4285,
    type: 'Sahil Kedi ve Köpek Besleme Odağı',
    equipment: 'Rüzgar ve yağmur korumalı mama istasyonu, su kabı',
  ),
  FeedingPoint(
    id: 'fp-5',
    title: 'Tatlıkuyu Vadisi Parkı Besleme Noktası',
    neighborhood: 'Tatlıkuyu',
    address: 'Tatlıkuyu Vadisi 1. Etap Gölet Kenarı Ahşap Köprü Yanı',
    latitude: 40.7962,
    longitude: 29.4210,
    type: 'Kedi Evi & Mama Odağı',
    equipment: '3 adet ahşap korunaklı kedi evi, mama ve su otomatı',
  ),
  FeedingPoint(
    id: 'fp-6',
    title: 'Gaziler Dağı Tabiat Parkı Doğal Besleme Noktası',
    neighborhood: 'Gaziler',
    address: 'Gaziler Dağı Orman Girişi Mesire Alanı Kenarı',
    latitude: 40.8220,
    longitude: 29.4510,
    type: 'Orman Bölgesi Sokak Hayvanları Odağı',
    equipment: 'Büyük boy korunaklı kuru mama besleme noktası',
  ),
  FeedingPoint(
    id: 'fp-7',
    title: 'Arapçeşme Parkı Besleme İstasyonu',
    neighborhood: 'Arapçeşme',
    address: 'Arapçeşme Mah. Şehit Oktay Kaya Cad. Park Alanı',
    latitude: 40.8080,
    longitude: 29.4250,
    type: 'Mama ve Su Odak Noktası',
    equipment: 'Korumalı mama haznesi ve otomatik taze su vanası',
  ),
  FeedingPoint(
    id: 'fp-8',
    title: 'Mustafapaşa Mahallesi Parkı Besleme Odağı',
    neighborhood: 'Mustafapaşa',
    address: 'Mustafapaşa Mah. 721. Sokak Çocuk Parkı Yanı',
    latitude: 40.8010,
    longitude: 29.4410,
    type: 'Kedi Evi ve Besleme Ünitesi',
    equipment: 'Yalıtımlı kedi yuvası ve kuru mama haznesi',
  ),
];

/// Sahipli Evcil Hayvan Durumları İçin Gebze Özel Nöbetçi & 7/24 Veteriner Klinikleri Fallback Listesi
const List<DutyVetClinic> kGebzeDutyVetClinics = [
  DutyVetClinic(
    id: 'vet-1',
    name: 'Gebze Pati Veteriner Kliniği (7/24 Nöbetçi)',
    district: 'Gebze / Kocaeli',
    address: 'Hacıhalil Mah. Hükümet Cad. No:42/A, Gebze/Kocaeli',
    phone: '(0262) 641 22 33',
    emergencyHours: '7/24 Acil Nöbetçi Hizmeti',
    latitude: 40.8035,
    longitude: 29.4320,
    is24Hours: true,
  ),
  DutyVetClinic(
    id: 'vet-2',
    name: 'Anka Veteriner Tıp Merkezi & Cerrahi',
    district: 'Gebze / Kocaeli',
    address: 'Osman Yılmaz Mah. İstanbul Cad. No:88, Gebze/Kocaeli',
    phone: '(0262) 646 10 20',
    emergencyHours: '24 Saat Acil Müdahale & Yoğun Bakım',
    latitude: 40.8005,
    longitude: 29.4270,
    is24Hours: true,
  ),
  DutyVetClinic(
    id: 'vet-3',
    name: 'Dostlar Veteriner Kliniği',
    district: 'Gebze / Kocaeli',
    address: 'Tatlıkuyu Mah. Güney Yanyol Cad. No:15, Gebze/Kocaeli',
    phone: '(0262) 644 55 66',
    emergencyHours: 'Hafta içi & Hafta sonu Gece Nöbeti (09:00 - 02:00)',
    latitude: 40.7970,
    longitude: 29.4225,
    is24Hours: false,
  ),
  DutyVetClinic(
    id: 'vet-4',
    name: 'Mavi Pati Veteriner Kliniği',
    district: 'Gebze / Kocaeli',
    address: 'Mevlana Mah. Issıkgöl Cad. No:62/B, Gebze/Kocaeli',
    phone: '(0262) 643 78 90',
    emergencyHours: '7/24 Acil Çağrı & Müdahale',
    latitude: 40.8140,
    longitude: 29.4380,
    is24Hours: true,
  ),
  DutyVetClinic(
    id: 'vet-5',
    name: 'Eskihisar Veteriner Kliniği',
    district: 'Gebze / Kocaeli',
    address: 'İstasyon Mah. Çerkeşli Cad. No:24, Gebze/Kocaeli',
    phone: '(0262) 655 40 50',
    emergencyHours: '08:30 - 23:00 / Acil Telefon Hattı Açık',
    latitude: 40.7850,
    longitude: 29.4310,
    is24Hours: false,
  ),
];

/// 1. Sahiplendirme Stream Provider - Firestore 'pet_adoptions' koleksiyonu
final petAdoptionsStreamProvider =
    StreamProvider.autoDispose<List<PetAdoption>>((ref) {
      return FirebaseFirestore.instance
          .collection('pet_adoptions')
          .where('isAdopted', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return kFallbackPets;
            }
            return snapshot.docs
                .map((doc) => PetAdoption.fromFirestore(doc))
                .toList();
          })
          .handleError((error) {
            return kFallbackPets;
          });
    });

/// 2. Mama ve Su Odakları Stream Provider - Firestore 'feeding_points' koleksiyonu
final feedingPointsStreamProvider =
    StreamProvider.autoDispose<List<FeedingPoint>>((ref) {
      return FirebaseFirestore.instance
          .collection('feeding_points')
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return kGebzeFeedingPoints;
            }
            return snapshot.docs
                .map((doc) => FeedingPoint.fromFirestore(doc))
                .toList();
          })
          .handleError((error) {
            return kGebzeFeedingPoints;
          });
    });

/// 3. Özel & Nöbetçi Veteriner Klinikleri Stream Provider - Firestore 'vet_clinics' koleksiyonu
final vetClinicsStreamProvider =
    StreamProvider.autoDispose<List<DutyVetClinic>>((ref) {
      return FirebaseFirestore.instance
          .collection('vet_clinics')
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return kGebzeDutyVetClinics;
            }
            return snapshot.docs
                .map((doc) => DutyVetClinic.fromFirestore(doc))
                .toList();
          })
          .handleError((error) {
            return kGebzeDutyVetClinics;
          });
    });
