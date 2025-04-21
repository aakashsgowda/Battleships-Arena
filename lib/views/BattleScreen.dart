// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:battleships/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BattleScreen extends StatefulWidget {
  final int gameId;

  const BattleScreen({super.key, required this.gameId});

  @override
  _BattleScreenState createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  Map<String, dynamic>? gameInfo;
  String? selectedBlock;
  String? username;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchGameDetails();
  }

  Future<void> fetchUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
    });
  }

  Widget buildCellContent(String cellId) {
    final shots = gameInfo!['shots'];
    final sunk = gameInfo!['sunk'];
    final wrecks = gameInfo!['wrecks'];
    final ships = gameInfo!['ships'];

    List<String> emojis = [];

    if (ships.contains(cellId)) {
      emojis.add("🛳️");
    }
    if (wrecks.contains(cellId)) {
      emojis.add("🫧");
    }
    if (shots.contains(cellId)) {
      if (sunk.contains(cellId)) {
        emojis.add("💥");
      } else {
        emojis.add("💣");
      }
    }

    return Text(
      emojis.join(" "),
      style: TextStyle(fontSize: 20),
      textAlign: TextAlign.center,
    );
  }

  String fetchStatusDescription(int status) {
    switch (status) {
      case 0:
        return 'Matchmaking phase';
      case 1:
        return 'Game won by player 1';
      case 2:
        return 'Game won by player 2';
      case 3:
        return 'Game in progress';
      default:
        return 'Unknown status';
    }
  }

  Future<void> fetchGameDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final response = await http.get(
        Uri.parse('$baseUrl/games/${widget.gameId}'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          gameInfo = data;
        });
        checkGameOver(data);
      } else {
        debugPrint('Failed to fetch game details');
      }
    } catch (error) {
      debugPrint('Error fetching game details: $error');
    }
  }

  void checkGameOver(Map<String, dynamic> data) {
    final status = data['status'];
    if (status == 1 || status == 2) {
      final isPlayer1 = data['player1'] == username;
      final isWinner = (status == 1 && isPlayer1) || (status == 2 && !isPlayer1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Game over'),
            content: Text(isWinner ? 'You won!' : 'You lost!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> submitPlayerShot(String targetCell) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final response = await http.put(
        Uri.parse('$baseUrl/games/${widget.gameId}'),
        body: jsonEncode({'shot': targetCell}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          fetchGameDetails();
        });
      } else {
        final errorResponse = jsonDecode(response.body);
        displayErrorDialog(errorResponse['error']);
      }
    } catch (error) {
      debugPrint('Error submitting shot: $error');
    }
  }

  Future<void> submitAIShot(String targetCell) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final response = await http.put(
        Uri.parse('$baseUrl/games/${widget.gameId}'),
        body: jsonEncode({'shot': targetCell, 'ai': 'random'}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          fetchGameDetails();
        });
      } else {
        final errorResponse = jsonDecode(response.body);
        displayErrorDialog(errorResponse['error']);
      }
    } catch (error) {
      debugPrint('Error submitting AI shot: $error');
    }
  }

  void displayErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Color(0xFF1F1F1F),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('💣 Battleship Game', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: gameInfo != null
          ? buildGameDetails()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget buildGameDetails() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: Radius.circular(8),
      trackVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Text('Game ID: ${gameInfo!['id']}', style: TextStyle(color: Colors.white)),
              Text('Status: ${fetchStatusDescription(gameInfo!['status'])}', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 20),
              buildGameBoard(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (selectedBlock != null) {
                    if (gameInfo!['player2'] == 'AI-perfect' ||
                        gameInfo!['player2'] == 'AI-random' ||
                        gameInfo!['player2'] == 'AI-oneship') {
                      submitAIShot(selectedBlock!);
                    } else {
                      submitPlayerShot(selectedBlock!);
                    }
                  } else {
                    displayErrorDialog('Please select a block on the game board.');
                  }
                },
                child: Text('Play Shot'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGameBoard() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
      ),
      itemCount: 25,
      itemBuilder: (context, index) {
        int row = index ~/ 5;
        int col = index % 5;
        String cellId = String.fromCharCode('A'.codeUnitAt(0) + row) + (col + 1).toString();

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedBlock = cellId;
            });
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              color: selectedBlock == cellId ? Colors.green[800] : Color(0xFF1F1F1F),
            ),
            child: Center(
              child: buildCellContent(cellId),
            ),
          ),
        );
      },
    );
  }
}
