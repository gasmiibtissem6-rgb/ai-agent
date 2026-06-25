import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Participant {
  final String name;
  final String email;
  final String role;
  final String status;

  Participant({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });
}

class DealVersion {
  final int number;
  final String date;
  final String creator;
  final String changes;

  DealVersion({
    required this.number,
    required this.date,
    required this.creator,
    required this.changes,
  });
}

class DealActivity {
  final String type; // 'comment', 'version', 'joined', 'invitation'
  final String author;
  final String message;
  final String time;

  DealActivity({
    required this.type,
    required this.author,
    required this.message,
    required this.time,
  });
}

class Deal {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status; // 'draft', 'negotiation', 'approved', 'rejected', 'archived'
  final String date;
  final String expirationDate;
  final String amount;
  final List<Participant> participants;
  final List<DealVersion> versions;
  final List<DealActivity> activity;

  Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.date,
    required this.expirationDate,
    required this.amount,
    required this.participants,
    required this.versions,
    required this.activity,
  });

  Deal copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? status,
    String? date,
    String? expirationDate,
    String? amount,
    List<Participant>? participants,
    List<DealVersion>? versions,
    List<DealActivity>? activity,
  }) {
    return Deal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      date: date ?? this.date,
      expirationDate: expirationDate ?? this.expirationDate,
      amount: amount ?? this.amount,
      participants: participants ?? this.participants,
      versions: versions ?? this.versions,
      activity: activity ?? this.activity,
    );
  }
}

class Contract {
  final String id;
  final String name;
  final String dealId;
  final String approvalDate;
  final String status; // 'approved', 'pending'
  final int approvedBy;
  final int pending;

  Contract({
    required this.id,
    required this.name,
    required this.dealId,
    required this.approvalDate,
    required this.status,
    required this.approvedBy,
    required this.pending,
  });
}

class DealsProvider extends ChangeNotifier {
  final List<Deal> _deals = [];
  final List<Contract> _contracts = [];

  List<Deal> get deals => _deals;
  List<Contract> get contracts => _contracts;

  DealsProvider() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Populate Deals
    _deals.addAll([
      Deal(
        id: '1',
        title: 'Partnership Agreement',
        description: 'Strategic partnership agreement for joint venture development with ABC Corp.',
        category: 'Partnership',
        status: 'negotiation',
        date: 'Mar 12, 2025',
        expirationDate: 'Apr 12, 2025',
        amount: '\$50,000',
        participants: [
          Participant(name: 'Hamza', email: 'hamza@example.com', role: 'Owner', status: 'active'),
          Participant(name: 'Ahmed Hassan', email: 'ahmed@abccorp.com', role: 'Partner', status: 'active'),
          Participant(name: 'Sarah Johnson', email: 'sarah@abccorp.com', role: 'Partner', status: 'invited'),
        ],
        versions: [
          DealVersion(number: 2, date: 'Mar 14, 2025', creator: 'Ahmed Hassan', changes: '3 changes'),
          DealVersion(number: 1, date: 'Mar 12, 2025', creator: 'Hamza', changes: 'Initial version'),
        ],
        activity: [
          DealActivity(type: 'comment', author: 'Ahmed Hassan', message: 'Let me review this section', time: '2 hours ago'),
          DealActivity(type: 'version', author: 'Ahmed Hassan', message: 'Created version 2.0', time: '5 hours ago'),
          DealActivity(type: 'joined', author: 'Sarah Johnson', message: 'Joined the deal', time: '1 day ago'),
        ],
      ),
      Deal(
        id: '2',
        title: 'Marketing Contract',
        description: 'Global marketing partnership campaign agreement.',
        category: 'Service',
        status: 'approved',
        date: 'Mar 10, 2025',
        expirationDate: 'Jun 10, 2025',
        amount: '\$25,000',
        participants: [
          Participant(name: 'Hamza', email: 'hamza@example.com', role: 'Owner', status: 'active'),
          Participant(name: 'Elena Rostova', email: 'elena@marketing.com', role: 'Partner', status: 'active'),
        ],
        versions: [
          DealVersion(number: 1, date: 'Mar 10, 2025', creator: 'Hamza', changes: 'Final version'),
        ],
        activity: [
          DealActivity(type: 'joined', author: 'Elena Rostova', message: 'Joined the deal', time: '2 days ago'),
        ],
      ),
      Deal(
        id: '3',
        title: 'Investment Proposal',
        description: 'Seed round financing proposal.',
        category: 'Investment',
        status: 'draft',
        date: 'Mar 8, 2025',
        expirationDate: 'May 8, 2025',
        amount: '\$150,000',
        participants: [
          Participant(name: 'Hamza', email: 'hamza@example.com', role: 'Owner', status: 'active'),
          Participant(name: 'Investor Group', email: 'invest@ventures.com', role: 'Investor', status: 'invited'),
        ],
        versions: [],
        activity: [],
      ),
      Deal(
        id: '4',
        title: 'Supplier Agreement',
        description: 'Raw materials supply contract.',
        category: 'Supply',
        status: 'approved',
        date: 'Mar 5, 2025',
        expirationDate: 'Sep 5, 2025',
        amount: '\$75,000',
        participants: [
          Participant(name: 'Hamza', email: 'hamza@example.com', role: 'Owner', status: 'active'),
          Participant(name: 'John Smith', email: 'john@supplies.com', role: 'Supplier', status: 'active'),
        ],
        versions: [],
        activity: [],
      ),
      Deal(
        id: '5',
        title: 'Service Contract',
        description: 'IT maintenance service SLA.',
        category: 'Service',
        status: 'rejected',
        date: 'Mar 1, 2025',
        expirationDate: 'Mar 1, 2026',
        amount: '\$35,000',
        participants: [
          Participant(name: 'Hamza', email: 'hamza@example.com', role: 'Owner', status: 'active'),
          Participant(name: 'Saber', email: 'saber@it.com', role: 'Client', status: 'active'),
        ],
        versions: [],
        activity: [],
      ),
      Deal(
        id: '6',
        title: 'Non-Disclosure Agreement',
        description: 'Mutual confidentiality agreement for strategic discussion.',
        category: 'License',
        status: 'archived',
        date: 'Feb 28, 2025',
        expirationDate: 'Feb 28, 2028',
        amount: 'N/A',
        participants: [
          Participant(name: 'Hamza', email: 'hamza@example.com', role: 'Owner', status: 'active'),
        ],
        versions: [],
        activity: [],
      ),
    ]);

    // Populate Contracts
    _contracts.addAll([
      Contract(
        id: '1',
        name: 'Partnership Agreement v2.0',
        dealId: '1',
        approvalDate: 'Mar 14, 2025',
        status: 'approved',
        approvedBy: 3,
        pending: 0,
      ),
      Contract(
        id: '2',
        name: 'Marketing Contract Final',
        dealId: '2',
        approvalDate: 'Mar 10, 2025',
        status: 'approved',
        approvedBy: 2,
        pending: 0,
      ),
      Contract(
        id: '3',
        name: 'Investment Proposal v1.0',
        dealId: '3',
        approvalDate: 'Mar 8, 2025',
        status: 'pending',
        approvedBy: 1,
        pending: 3,
      ),
      Contract(
        id: '4',
        name: 'Supplier Agreement Final',
        dealId: '4',
        approvalDate: 'Mar 5, 2025',
        status: 'approved',
        approvedBy: 2,
        pending: 0,
      ),
    ]);
  }

  // Create a new deal
  void createDeal({
    required String title,
    required String description,
    required String category,
    required String expirationDate,
    required List<Map<String, String>> participantsData,
  }) {
    final String newId = (_deals.length + 1).toString();
    final String today = DateFormat('MMM dd, yyyy').format(DateTime.now());
    
    final List<Participant> listParticipants = [
      Participant(name: 'Hamza', email: 'hamza@example.com', role: 'Owner', status: 'active')
    ];
    
    for (var p in participantsData) {
      if (p['email'] != null && p['email']!.isNotEmpty) {
        listParticipants.add(
          Participant(
            name: p['email']!.split('@')[0],
            email: p['email']!,
            role: p['role'] ?? 'Partner',
            status: 'invited',
          ),
        );
      }
    }

    final Deal newDeal = Deal(
      id: newId,
      title: title,
      description: description,
      category: category,
      status: 'draft',
      date: today,
      expirationDate: expirationDate.isNotEmpty ? expirationDate : 'N/A',
      amount: 'N/A',
      participants: listParticipants,
      versions: [
        DealVersion(number: 1, date: today, creator: 'Hamza', changes: 'Initial version')
      ],
      activity: [
        DealActivity(type: 'version', author: 'Hamza', message: 'Created initial draft', time: 'Just now')
      ],
    );

    _deals.insert(0, newDeal);
    notifyListeners();
  }

  // Add comment to deal
  void addComment(String dealId, String author, String message) {
    final int index = _deals.indexWhere((d) => d.id == dealId);
    if (index != -index) {
      final List<DealActivity> updatedActivity = List.from(_deals[index].activity);
      updatedActivity.insert(
        0,
        DealActivity(
          type: 'comment',
          author: author,
          message: message,
          time: 'Just now',
        ),
      );
      _deals[index] = _deals[index].copyWith(activity: updatedActivity);
      notifyListeners();
    }
  }

  // Invite participant
  void inviteParticipant(String dealId, String email, String role) {
    final int index = _deals.indexWhere((d) => d.id == dealId);
    if (index != -1) {
      final List<Participant> updatedParticipants = List.from(_deals[index].participants);
      updatedParticipants.add(
        Participant(
          name: email.split('@')[0],
          email: email,
          role: role,
          status: 'invited',
        ),
      );
      
      final List<DealActivity> updatedActivity = List.from(_deals[index].activity);
      updatedActivity.insert(
        0,
        DealActivity(
          type: 'invitation',
          author: 'Hamza',
          message: 'Invited $email to the deal',
          time: 'Just now',
        ),
      );
      
      _deals[index] = _deals[index].copyWith(
        participants: updatedParticipants,
        activity: updatedActivity,
      );
      notifyListeners();
    }
  }
}
