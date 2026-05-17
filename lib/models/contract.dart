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

enum ContractType {
  employment,
  loan,
  service,
  deliverable,
}

extension ContractTypeExtension on ContractType {
  String get displayName {
    switch (this) {
      case ContractType.employment:
        return 'Employment Contract';
      case ContractType.loan:
        return 'Loan Agreement';
      case ContractType.service:
        return 'Service Agreement';
      case ContractType.deliverable:
        return 'Deliverables Contract';
    }
  }
}

class Contract {
  final String id;
  final String npcId; // The character interacting with the player
  final ContractType type;
  final String description;
  final Map<String, dynamic> terms; // e.g., {'salary': 20, 'rate': 10, 'amount': 200, 'item': 'cabbage'}
  final bool isActive;

  Contract({
    required this.id,
    required this.npcId,
    required this.type,
    required this.description,
    this.terms = const {},
    this.isActive = true,
  });

  Contract copyWith({
    String? id,
    String? npcId,
    ContractType? type,
    String? description,
    Map<String, dynamic>? terms,
    bool? isActive,
  }) {
    return Contract(
      id: id ?? this.id,
      npcId: npcId ?? this.npcId,
      type: type ?? this.type,
      description: description ?? this.description,
      terms: terms ?? Map<String, dynamic>.from(this.terms),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'npcId': npcId,
        'type': type.index,
        'description': description,
        'terms': terms,
        'isActive': isActive,
      };

  factory Contract.fromJson(Map<String, dynamic> json) => Contract(
        id: json['id'] as String,
        npcId: json['npcId'] as String,
        type: ContractType.values[json['type'] as int],
        description: json['description'] as String,
        terms: Map<String, dynamic>.from(json['terms'] as Map? ?? {}),
        isActive: json['isActive'] as bool? ?? true,
      );
}
