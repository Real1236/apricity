class RelationshipState {
  final Set<String> friends;
  final Set<String> outgoingPending;
  final Set<String> incomingPending;
  const RelationshipState({
    required this.friends,
    required this.outgoingPending,
    required this.incomingPending,
  });
}
