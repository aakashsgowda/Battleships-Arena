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

  Widget getPersonalizedBadge(Map<String, dynamic> game) {
    if (username == null) return Text('Unknown');

    int status = game['status'];
    String player1 = game['player1'] ?? '';
    String player2 = game['player2'] ?? '';

    if (status == 1) {
      return username == player1
          ? Badge(text: 'You won', color: Colors.green)
          : Badge(text: 'You lost', color: Colors.red);
    } else if (status == 2) {
      return username == player2
          ? Badge(text: 'You won', color: Colors.green)
          : Badge(text: 'You lost', color: Colors.red);
    } else {
      return Badge(text: 'Unknown', color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
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
                return Card(
                  color: Colors.grey[850],
                  child: ListTile(
                    title: Text(
                      'Game ID: ${game['id']}',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: game['player1'] != null &&
                            game['player2'] != null
                        ? Text(
                            'Players: ${game['player1']} vs ${game['player2']}',
                            style: TextStyle(color: Colors.white70),
                          )
                        : Text('Matchmaking phase',
                            style: TextStyle(color: Colors.white54)),
                    trailing: getPersonalizedBadge(game),
                    onLongPress: () {
                      showDeleteDialog(context, game);
                    },
                  ),
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
        backgroundColor: Colors.grey[900],
        title: Text('Delete Game', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete this game?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              debugPrint('Game deletion confirmed for ID: ${game['id']}');
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class Badge extends StatelessWidget {
  final String text;
  final Color color;

  const Badge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: Colors.white)),
    );
  }
}
