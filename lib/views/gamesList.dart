// ignore_for_file: prefer_const_constructors

import 'package:battleships/utils/auth.dart';
import 'package:battleships/views/GameSetupPage.dart';
import 'package:battleships/views/newgameai.dart';
import 'package:battleships/views/BattleScreen.dart';
import 'package:battleships/views/finishedGames.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battleships/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameList extends StatefulWidget {
  const GameList({super.key});

  @override
  _GameListState createState() => _GameListState();
}

class _GameListState extends State<GameList> {
  List<dynamic> availableGames = [];
  String? username;

  @override
  void initState() {
    super.initState();
    loadUsername();
    loadGames();
  }

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'User';
    });
  }

  Future<void> performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('tokenTimestamp');
    await prefs.remove('username');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> loadGames() async {
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
        final responseData = jsonDecode(response.body);
        setState(() {
          availableGames = responseData['games'];
        });
      } else {
        debugPrint('Failed to load games: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('Error loading games: $error');
    }
  }

  Future<void> removeGame(int gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/games/$gameId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        debugPrint('Game deleted successfully');
        loadGames();
      } else {
        debugPrint('Failed to delete game');
      }
    } catch (error) {
      debugPrint('Error deleting game: $error');
    }
  }

  String getTurnLabel(dynamic game) {
    if (game['status'] == 0) return 'matchmaking';
    if (game['status'] == 3) {
      return game['turn'] == game['position'] ? 'myTurn' : 'opponentTurn';
    }
    if (game['status'] == 1 && game['position'] == 1) return 'won';
    if (game['status'] == 2 && game['position'] == 2) return 'won';
    return 'lost';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF1F1F1F),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Game List',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            color: Colors.white,
            onPressed: loadGames,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Color(0xFF1F1F1F),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF333333),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Battleships',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Logged in as ${username ?? ""}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            buildDrawerItem(Icons.pan_tool_alt_rounded, 'New Game', () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => GameSetupPage()),
              );
            }),
            buildDrawerItem(Icons.gamepad, 'New Game (AI)', () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Choose AI Opponent'),
                    backgroundColor: Colors.grey[900],
                    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                    contentTextStyle: TextStyle(color: Colors.white70, fontSize: 16),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildAIOption('Random', 'random'),
                        buildAIOption('Perfect', 'perfect'),
                        buildAIOption('One Ship (A1)', 'oneship'),
                      ],
                    ),
                  );
                },
              );
            }),
            buildDrawerItem(Icons.view_compact_alt_rounded, 'Show Completed Games', () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => FinishedGameList()),
              );
            }),
            buildDrawerItem(Icons.logout, 'Logout', () => performLogout(context)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: availableGames.length,
            itemBuilder: (context, index) {
              final game = availableGames[index];
              final gameStatus = game['status'];

              if (gameStatus == 0 || gameStatus == 3) {
                return Card(
                  color: Color(0xFF1E1E1E),
                  child: ListTile(
                    title: Text(
                      'Game ID: ${game['id']}',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      game['player1'] != null && game['player2'] != null
                          ? '${game['player1']} vs ${game['player2']}'
                          : 'Waiting for opponent',
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: Text(
                      getTurnLabel(game),
                      style: TextStyle(
                        color: getTurnLabel(game) == 'myTurn'
                            ? Colors.green
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BattleScreen(gameId: game['id']),
                        ),
                      );
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Delete Game'),
                            content: Text('Are you sure you want to delete this game?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  removeGame(game['id']);
                                  Navigator.pop(context);
                                },
                                child: Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }

  ListTile buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }

  Widget buildAIOption(String label, String aiType) {
    return ListTile(
      title: Text(label, style: TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NewGamePageai(AiType: aiType),
          ),
        );
      },
    );
  }
}
