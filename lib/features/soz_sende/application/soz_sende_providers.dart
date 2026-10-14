import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../screens/auth_service.dart' show authStateProvider;
import '../data/soz_sende_repository.dart';
import '../data/vote_local_store.dart';

final sozRepoProvider = Provider<SozSendeRepository>(
  (ref) => SozSendeRepository(),
);

final voteLocalStoreProvider = Provider<VoteLocalStore>(
  (ref) => VoteLocalStore(),
);

/// Giriş yapmış üyenin Firebase uid'si. Misafirde (oturum yok) null.
final sozUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.uid,
);

/// pollKey -> seçilen şık.
/// Önce yerel kopya (anında), ardından Firestore akışı gelir.
/// Oy geri alınamadığı için iki kaynağı birleştirmek her zaman güvenlidir.
final myVotesProvider = StreamProvider.autoDispose<Map<String, int>>((
  ref,
) async* {
  final uid = ref.watch(sozUidProvider);
  if (uid == null) {
    yield <String, int>{};
    return;
  }
  final local = ref.read(voteLocalStoreProvider);
  var merged = await local.votes(uid);
  yield merged;

  await for (final snap in ref.read(sozRepoProvider).myVotesRaw(uid)) {
    final remote = <String, int>{
      for (final d in snap.docs)
        if (d.data()['optionIndex'] is num)
          d.id: (d.data()['optionIndex'] as num).toInt(),
    };
    merged = {...merged, ...remote};
    yield merged;

    // Yalnızca sunucuda onaylanan oyları kalıcı yap; kural tarafından
    // reddedilen bir yazma yerelde "oy verildi" olarak kalmasın.
    final confirmed = <String, int>{
      for (final d in snap.docs)
        if (!d.metadata.hasPendingWrites && d.data()['optionIndex'] is num)
          d.id: (d.data()['optionIndex'] as num).toInt(),
    };
    if (confirmed.isNotEmpty) {
      final stored = await local.votes(uid);
      await local.saveVotes(uid, {...stored, ...confirmed});
    }
  }
});

/// Desteklenen önerilerin doküman kimlikleri.
final mySupportedProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(sozUidProvider);
  if (uid == null) return Stream.value(<String>{});
  return ref.read(sozRepoProvider).mySupportedIds(uid);
});
