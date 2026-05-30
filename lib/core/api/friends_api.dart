import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friendship.dart';
import '../models/user.dart';
import 'api_client.dart';

class FriendsApi {
  final Dio _dio;

  FriendsApi(ApiClient client) : _dio = client.dio;

  Future<FriendsData> getFriends() async {
    final res = await _dio.get('/api/v1/friends');
    return FriendsData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<User>> searchUsers(String q) async {
    final res = await _dio.get('/api/v1/users', queryParameters: {'q': q});
    final list = res.data['users'] as List<dynamic>? ?? [];
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendRequest(String userId) async {
    await _dio.post('/api/v1/friends/request', data: {'user_id': userId});
  }

  Future<void> accept(String friendshipId) async {
    await _dio.patch('/api/v1/friends/$friendshipId/accept');
  }

  // Covers reject (incoming), cancel (outgoing), and unfriend (accepted).
  Future<void> remove(String friendshipId) async {
    await _dio.delete('/api/v1/friends/$friendshipId');
  }
}

final friendsApiProvider = Provider<FriendsApi>(
  (ref) => FriendsApi(ref.watch(apiClientProvider)),
);
