// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


enum BusinessType {
  bistro,
  bakery,
  pizzeria,
  cafe,
  opiateLab,
  lawPractice,
  medicalPractice,
  theater,
}

extension BusinessTypeExtension on BusinessType {
  String get displayName {
    switch (this) {
      case BusinessType.bistro:
        return 'High-End Bistro';
      case BusinessType.bakery:
        return 'Artisanal Bakery';
      case BusinessType.pizzeria:
        return 'Piedmontese Pizzeria';
      case BusinessType.cafe:
        return 'Viennese Cafe';
      case BusinessType.opiateLab:
        return 'Chemical Opiate Laboratory';
      case BusinessType.lawPractice:
        return 'Gothic Law Chambers';
      case BusinessType.medicalPractice:
        return 'Private Medical Clinic';
      case BusinessType.theater:
        return 'Imperial Grand Theater';
    }
  }
}

class LedgerEntry {
  final String date;
  final String description;
  final double amount; // positive is income, negative is expense

  LedgerEntry({
    required this.date,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'description': description,
        'amount': amount,
      };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        date: json['date'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

class ActiveBusiness {
  final String id;
  final BusinessType type;
  final String name;
  final String proposerId; // NPC that set this up
  final String status; // 'proposal', 'inProgress', 'active', 'shutDown'
  final int currentAssignmentIndex;
  final List<String> assignments;
  final List<String> holdings; // Rooms or buildings dedicated (room IDs)
  final List<String> agreements; // Custom text agreements
  final List<String> employeeIds; // Hired characters dedicated
  final List<String> logs;
  final List<LedgerEntry> ledger;
  
  // Theater specific parameters (stored in metadata for flexibility)
  final Map<String, dynamic> metadata;

  ActiveBusiness({
    required this.id,
    required this.type,
    required this.name,
    required this.proposerId,
    required this.status,
    required this.currentAssignmentIndex,
    required this.assignments,
    required this.holdings,
    required this.agreements,
    required this.employeeIds,
    required this.logs,
    required this.ledger,
    this.metadata = const {},
  });

  ActiveBusiness copyWith({
    String? id,
    BusinessType? type,
    String? name,
    String? proposerId,
    String? status,
    int? currentAssignmentIndex,
    List<String>? assignments,
    List<String>? holdings,
    List<String>? agreements,
    List<String>? employeeIds,
    List<String>? logs,
    List<LedgerEntry>? ledger,
    Map<String, dynamic>? metadata,
  }) {
    return ActiveBusiness(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      proposerId: proposerId ?? this.proposerId,
      status: status ?? this.status,
      currentAssignmentIndex: currentAssignmentIndex ?? this.currentAssignmentIndex,
      assignments: assignments ?? List<String>.from(this.assignments),
      holdings: holdings ?? List<String>.from(this.holdings),
      agreements: agreements ?? List<String>.from(this.agreements),
      employeeIds: employeeIds ?? List<String>.from(this.employeeIds),
      logs: logs ?? List<String>.from(this.logs),
      ledger: ledger ?? List<LedgerEntry>.from(this.ledger),
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'name': name,
        'proposerId': proposerId,
        'status': status,
        'currentAssignmentIndex': currentAssignmentIndex,
        'assignments': assignments,
        'holdings': holdings,
        'agreements': agreements,
        'employeeIds': employeeIds,
        'logs': logs,
        'ledger': ledger.map((e) => e.toJson()).toList(),
        'metadata': metadata,
      };

  factory ActiveBusiness.fromJson(Map<String, dynamic> json) => ActiveBusiness(
        id: json['id'] as String,
        type: BusinessType.values[json['type'] as int],
        name: json['name'] as String,
        proposerId: json['proposerId'] as String,
        status: json['status'] as String,
        currentAssignmentIndex: json['currentAssignmentIndex'] as int? ?? 0,
        assignments: List<String>.from(json['assignments'] as List? ?? []),
        holdings: List<String>.from(json['holdings'] as List? ?? []),
        agreements: List<String>.from(json['agreements'] as List? ?? []),
        employeeIds: List<String>.from(json['employeeIds'] as List? ?? []),
        logs: List<String>.from(json['logs'] as List? ?? []),
        ledger: (json['ledger'] as List? ?? [])
            .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}
