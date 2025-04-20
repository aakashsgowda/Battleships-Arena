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
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.blue,
          title: Text('Game List'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: loadGames,
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
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
              ListTile(
                leading: Icon(Icons.pan_tool_alt_rounded),
                title: Text('New Game'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => GameSetupPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.gamepad),
                title: Text('New Game (AI)'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Choose AI Opponent'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text('Random'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NewGamePageai(AiType: "random"),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              title: Text('Perfect'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NewGamePageai(AiType: "perfect"),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              title: Text('One Ship (A1)'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NewGamePageai(AiType: "oneship"),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.view_compact_alt_rounded),
                title: Text('Show Completed Games'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => FinishedGameList()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  performLogout(context);
                },
              ),
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
                return ListTile(
                  title: Text(game['id'].toString()),
                  subtitle: game['player1'] != null && game['player2'] != null
                      ? Text('${game['player1']} vs ${game['player2']}')
                      : Text('Waiting for opponent'),
                  trailing: Text(getTurnLabel(game)),
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
                          content: Text(
                              'Are you sure you want to delete this game?'),
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
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        )));
  }
}
