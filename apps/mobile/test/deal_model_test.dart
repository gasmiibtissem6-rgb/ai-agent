import 'package:flutter_test/flutter_test.dart';

import 'package:ideal_app/features/deal/domain/deal_model.dart';

void main() {
  group('DealStatus wire mapping', () {
    test('every enum value round-trips through its wire value', () {
      for (final status in DealStatus.values) {
        expect(
          DealStatusX.fromWire(status.wireValue),
          status,
          reason: '${status.name} did not round-trip',
        );
      }
    });

    test('wire values match the Postgres deal_status labels', () {
      expect(DealStatus.draft.wireValue, 'DRAFT');
      expect(DealStatus.negotiation.wireValue, 'NEGOTIATION');
      expect(DealStatus.pendingApproval.wireValue, 'PENDING_APPROVAL');
      expect(DealStatus.locked.wireValue, 'LOCKED');
      expect(DealStatus.cancelled.wireValue, 'CANCELLED');
    });

    test('NEGOTIATION is surfaced to users as "Bridged"', () {
      expect(DealStatus.negotiation.label, 'Bridged');
      expect(DealStatusX.fromWire('NEGOTIATION').label, 'Bridged');
    });

    test('an unknown or missing status degrades to draft', () {
      expect(DealStatusX.fromWire(null), DealStatus.draft);
      expect(DealStatusX.fromWire('BRIDGED'), DealStatus.draft);
    });

    test('creator-settable statuses are exactly Approved, Bridged, Cancelled', () {
      expect(kCreatorSettableStatuses.map((s) => s.label), [
        'Approved',
        'Bridged',
        'Cancelled',
      ]);
    });
  });

  group('DealContentType wire mapping', () {
    test('round-trips every value', () {
      for (final type in DealContentType.values) {
        expect(DealContentTypeX.fromWire(type.wireValue), type);
      }
    });

    test('an absent deal_type yields null rather than a wrong default', () {
      expect(DealContentTypeX.fromWire(null), isNull);
      expect(DealContentTypeX.fromWire('pdf'), isNull);
    });
  });

  group('Deal.fromJson', () {
    Map<String, dynamic> payload({String status = 'NEGOTIATION'}) => {
      'id': 'deal-1',
      'creatorProfileId': 'profile-1',
      'title': 'Supply agreement',
      'description': 'Quarterly supply',
      'dealType': 'scanned',
      'status': status,
      'currentVersionId': 'v1',
      'lockedVersionId': null,
      'createdAt': '2026-07-09T10:00:00.000Z',
      'cancelledAt': null,
      'archivedAt': null,
      'versions': [
        {
          'id': 'v1',
          'dealId': 'deal-1',
          'versionNumber': 1,
          'status': 'DRAFT',
          'title': 'Supply agreement',
          'termsJson': {'category': 'Supply', 'document': 'Rendered body'},
          'summary': 'Initial draft',
          'lockedAt': null,
          'createdByProfileId': 'profile-1',
          'createdAt': '2026-07-09T10:00:00.000Z',
        },
      ],
    };

    test('parses the NestJS/Prisma camelCase shape', () {
      final deal = Deal.fromJson(payload());

      expect(deal.id, 'deal-1');
      expect(deal.creatorProfileId, 'profile-1');
      expect(deal.status, DealStatus.negotiation);
      expect(deal.statusLabel, 'Bridged');
      expect(deal.contentType, DealContentType.scanned);
      expect(deal.versions.single.document, 'Rendered body');
      expect(deal.versions.single.isFinal, isFalse);
    });

    test('only the creator may act on the deal', () {
      final deal = Deal.fromJson(payload());
      expect(deal.isCreatedBy('profile-1'), isTrue);
      expect(deal.isCreatedBy('someone-else'), isFalse);
      expect(deal.isCreatedBy(null), isFalse);
    });

    test('LOCKED and ARCHIVED deals are terminal, others are not', () {
      expect(Deal.fromJson(payload(status: 'LOCKED')).isTerminal, isTrue);
      expect(Deal.fromJson(payload(status: 'ARCHIVED')).isTerminal, isTrue);
      expect(Deal.fromJson(payload(status: 'APPROVED')).isTerminal, isFalse);
      expect(Deal.fromJson(payload(status: 'NEGOTIATION')).isTerminal, isFalse);
    });

    test('only a DRAFT deal is editable', () {
      expect(Deal.fromJson(payload(status: 'DRAFT')).isEditable, isTrue);
      expect(Deal.fromJson(payload(status: 'APPROVED')).isEditable, isFalse);
    });

    test('a version with no document falls back to an empty body', () {
      final json = payload();
      (json['versions'] as List)[0]['termsJson'] = {'category': 'Supply'};
      expect(Deal.fromJson(json).versions.single.document, '');
    });
  });
}
