# Phase 3 — Firebase (enable when you have a project)

Firebase is **not enabled by default** so the app runs fully offline. Turning it
on cannot be done from here — it needs *your* Firebase project and credentials.
This doc is the exact recipe + reference code.

## 1. Create the project & configure

```bash
npm i -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure          # generates lib/firebase_options.dart
```

Then uncomment the Firebase deps in `pubspec.yaml` and run `flutter pub get`.

## 2. Initialise in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: LifeOsApp()));
}
```

## 3. Swap the Money data source (no UI/domain changes)

Create `lib/features/money/data/datasources/firestore_money_datasource.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/domain/entities/transaction.dart';
import 'package:lifeos/shared/models/money.dart';

class FirestoreMoneyDataSource {
  FirestoreMoneyDataSource(this._db, this._userId);
  final FirebaseFirestore _db;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('money').doc(_userId).collection('transactions');

  Future<void> add(Transaction t) => _col.doc(t.id).set(_toMap(t));

  Stream<List<Transaction>> watch() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => _fromMap(d.id, d.data())).toList());

  Map<String, dynamic> _toMap(Transaction t) => {
        'amountMinorUnits': t.amount.minorUnits,
        'currency': t.amount.currency,
        'type': t.type.name,
        'categoryId': t.categoryId,
        'note': t.note,
        'date': Timestamp.fromDate(t.date),
      };

  Transaction _fromMap(String id, Map<String, dynamic> m) => Transaction(
        id: id,
        amount: Money(m['amountMinorUnits'] as int,
            currency: m['currency'] as String),
        type: TransactionType.values.byName(m['type'] as String),
        categoryId: m['categoryId'] as String,
        note: (m['note'] as String?) ?? '',
        date: (m['date'] as Timestamp).toDate(),
      );
}
```

Then point `moneyRepositoryProvider` at a `MoneyRepositoryImpl` backed by this
source instead of `MoneyLocalDataSource`. Everything else is untouched.

## 4. Firestore layout

```
users/{uid}
money/{uid}/transactions/{id}
food/{uid}/items/{id}
health/{uid}/days/{yyyy-mm-dd}
mind/{uid}/habits/{id}   mind/{uid}/tasks/{id}
goals/{uid}/goals/{id}
events/{uid}/log/{eventId}          # append-only life event log
notifications/{uid}/items/{id}
ai_insights/{uid}/items/{id}
```

## 5. Security rules (starter)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /{root}/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## 6. Offline-first sync

Keep the local data source as a cache and mirror the append-only `events/` log
to Firestore from an `EventHandler` (a `FirestoreSyncHandler` registered in the
`LifeCoreEngine`). Because every state change is already an event, sync is just
"append each event to the cloud log and let listeners rebuild" — no bespoke
merge logic per feature.
