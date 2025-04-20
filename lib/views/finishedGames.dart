// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:battleships/utils/constants.dart';

class FinishedGameList extends StatefulWidget {
  const FinishedGameList({super.key});

  @override
  _FinishedGameListState createState() => _FinishedGameListState();
}

class _FinishedGameListState extends State<FinishedGameList> {
  List<dynamic> completedGames = [];
  String? username;

  @override
  void initState() {
    super.initState();
    loadUserAndGames();
  }

  Future<void> loadUserAndGames() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
    });
    await fetchCompletedGames();
  }

  Future<void> fetchCompletedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) {
        debugPrint('Access token not found. Please log in.');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/games'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          completedGames = data['games'];
        });
      } else {
        debugPrint('Failed to fetch games: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error fetching game list: $error');
    }
  }

  String getPersonalizedResult(Map<String, dynamic> game) {
    if (username == null) return 'Unknown';

    int status = game['status'];
    String player1 = game['player1'] ?? '';
    String player2 = game['player2'] ?? '';

    if (status == 1) {
      return username == player1 ? 'GameWon' : 'GameLost';
    } else if (status == 2) {
      return username == player2 ? 'GameWon' : 'GameLost';
    } else {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.blue,
          title: Text('Completed Games'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: fetchCompletedGames,
            ),
          ],
        ),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: completedGames.length,
            itemBuilder: (context, index) {
              final game = completedGames[index];
              final gameStatus = game['status'];

              if (gameStatus == 1 || gameStatus == 2) {
                return ListTile(
                  title: Text('Game ID: ${game['id']}'),
                  subtitle: game['player1'] != null && game['player2'] != null
                      ? Text(
                          'Players: ${game['player1']} vs ${game['player2']}')
                      : Text('Matchmaking phase'),
                  trailing: Text(getPersonalizedResult(game)),
                  onTap: () {},
                  onLongPress: () {
                    showDeleteDialog(context, game);
                  },
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        )));
  }

  void showDeleteDialog(BuildContext context, dynamic game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Game'),
        content: Text('Are you sure you want to delete this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              debugPrint('Game deletion confirmed for ID: ${game['id']}');
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
