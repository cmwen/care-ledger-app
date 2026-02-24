/// A participant in a care ledger.
///
/// Stores display name and avatar initial for UI rendering.
class Participant {
  final String id;
  final String name;

  const Participant({required this.id, required this.name});

  /// First letter for avatar display.
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  Participant copyWith({String? id, String? name}) {
    return Participant(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  String toString() => 'Participant($id, $name)';
}
