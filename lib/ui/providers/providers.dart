import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/notifications/notification_service.dart';
import '../../data/db/database.dart';
import '../../services/chat/chat_service.dart';
import '../../services/contacts/contact_service.dart';
import '../../services/crypto/identity_service.dart';
import '../../services/crypto/session_crypto.dart';
import '../../services/security/pin_service.dart';
import '../../services/mesh/mesh_foreground.dart';
import '../../services/mesh/mesh_router.dart';
import '../../services/transfer/media_store.dart';
import '../../services/transfer/transfer_service.dart';
import '../../services/wipe/wipe_service.dart';
import '../../transport/connectivity_manager.dart';

/// Everything below the UI, booted once after onboarding.
class MessyCore {
  MessyCore._({
    required this.db,
    required this.identity,
    required this.identityService,
    required this.crypto,
    required this.connectivity,
    required this.router,
    required this.chat,
    required this.contacts,
    required this.transfer,
    required this.wipe,
  });

  final MessyDatabase db;
  final LocalIdentity identity;
  final IdentityService identityService;
  final SessionCrypto crypto;
  final ConnectivityManager connectivity;
  final MeshRouter router;
  final ChatService chat;
  final ContactService contacts;
  final TransferService transfer;
  final WipeService wipe;

  static Future<MessyCore> boot() async {
    final identityService = IdentityService();
    final identity = await identityService.load();
    final db = MessyDatabase();
    final crypto = SessionCrypto();
    final mediaStore = MediaStore();
    final connectivity = ConnectivityManager(
      identity: identity,
      identityService: identityService,
    );
    final router = MeshRouter(
      db: db,
      identity: identity,
      crypto: crypto,
      connectivity: connectivity,
      mediaStore: mediaStore,
    );
    final core = MessyCore._(
      db: db,
      identity: identity,
      identityService: identityService,
      crypto: crypto,
      connectivity: connectivity,
      router: router,
      chat: ChatService(db: db, identity: identity, router: router),
      contacts: ContactService(
        db: db,
        identity: identity,
        identityService: identityService,
        connectivity: connectivity,
        router: router,
      ),
      transfer: TransferService(
        db: db,
        identity: identity,
        router: router,
        mediaStore: mediaStore,
      ),
      wipe: WipeService(db: db, mediaStore: mediaStore),
    );
    router.start();
    core.wipe.start();
    await connectivity.start();

    // Message notifications: prompt for the permission (API 33+) and show a
    // heads-up for messages that arrive while the app isn't in front.
    final notifications = NotificationService();
    await notifications.init();
    router.onIncoming = (chatId, title, body) {
      final state = WidgetsBinding.instance.lifecycleState;
      if (state != AppLifecycleState.resumed) {
        notifications.showMessage(chatId: chatId, title: title, body: body);
      }
    };

    // Keep the mesh alive when the app is backgrounded (user can toggle
    // off in Settings).
    await MeshForeground.start();
    return core;
  }
}

final identityServiceProvider = Provider((ref) => IdentityService());

final pinServiceProvider = Provider((ref) => PinService());

/// What stands between the user and the app right now.
enum AppGate { onboarding, pinSetup, locked, ready }

final appGateProvider = FutureProvider<AppGate>((ref) async {
  final identityService = ref.watch(identityServiceProvider);
  final pinService = ref.watch(pinServiceProvider);
  if (!await identityService.hasIdentity()) return AppGate.onboarding;
  if (await pinService.needsUnlock()) {
    return await pinService.hasPin() ? AppGate.locked : AppGate.pinSetup;
  }
  return AppGate.ready;
});

final coreProvider = FutureProvider<MessyCore>((ref) => MessyCore.boot());

/// Live peer count for the mesh-status chip.
final peerCountProvider = StreamProvider<int>((ref) async* {
  final core = await ref.watch(coreProvider.future);
  yield core.connectivity.liveLinks.length;
  await for (final _ in core.connectivity.onPeersChanged) {
    yield core.connectivity.liveLinks.length;
  }
});

final chatsProvider = StreamProvider((ref) async* {
  final core = await ref.watch(coreProvider.future);
  yield* core.chat.watchChats();
});

final contactsProvider = StreamProvider((ref) async* {
  final core = await ref.watch(coreProvider.future);
  yield* core.chat.watchContacts();
});

final allMessagesProvider = StreamProvider((ref) async* {
  final core = await ref.watch(coreProvider.future);
  yield* core.chat.watchAllMessages();
});

final messagesProvider = StreamProvider.family((ref, String chatId) async* {
  final core = await ref.watch(coreProvider.future);
  yield* core.chat.watchMessages(chatId);
});

final groupsProvider = StreamProvider((ref) async* {
  final core = await ref.watch(coreProvider.future);
  yield* core.chat.watchGroups();
});

final mediaProvider = StreamProvider.family((ref, String mediaId) async* {
  final core = await ref.watch(coreProvider.future);
  yield* (core.db.select(core.db.mediaItems)
        ..where((m) => m.mediaId.equals(mediaId)))
      .watchSingleOrNull();
});

final pendingRequestsProvider = StreamProvider((ref) async* {
  final core = await ref.watch(coreProvider.future);
  yield core.contacts.currentPending;
  yield* core.contacts.pendingRequests;
});
