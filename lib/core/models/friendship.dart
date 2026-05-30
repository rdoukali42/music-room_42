import 'user.dart';

// An accepted friend — we keep friendshipId for unfriend calls.
class Friend {
  final String friendshipId;
  final User user;

  const Friend({required this.friendshipId, required this.user});

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        friendshipId: json['id'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}

// A pending friend request (incoming or outgoing).
class FriendRequest {
  final String id;
  final User user;

  const FriendRequest({required this.id, required this.user});

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: json['id'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class FriendsData {
  final List<Friend> accepted;
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;

  const FriendsData({
    this.accepted = const [],
    this.incoming = const [],
    this.outgoing = const [],
  });

  factory FriendsData.fromJson(Map<String, dynamic> json) => FriendsData(
        accepted: (json['accepted'] as List<dynamic>? ?? [])
            .map((e) => Friend.fromJson(e as Map<String, dynamic>))
            .toList(),
        incoming: (json['incoming'] as List<dynamic>? ?? [])
            .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
        outgoing: (json['outgoing'] as List<dynamic>? ?? [])
            .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  FriendsData copyWith({
    List<Friend>? accepted,
    List<FriendRequest>? incoming,
    List<FriendRequest>? outgoing,
  }) =>
      FriendsData(
        accepted: accepted ?? this.accepted,
        incoming: incoming ?? this.incoming,
        outgoing: outgoing ?? this.outgoing,
      );
}
