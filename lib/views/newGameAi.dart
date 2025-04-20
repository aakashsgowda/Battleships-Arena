// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:battleships/utils/auth.dart';
import 'package:battleships/views/gamesList.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:battleships/utils/constants.dart';


import 'package:shared_preferences/shared_preferences.dart';



class NewGamePageai extends StatefulWidget {
  final String AiType;

  const NewGamePageai({super.key, required this.AiType});

  @override
  _NewGamePageaiState createState() => _NewGamePageaiState();
}

class _NewGamePageaiState extends State<NewGamePageai> {
  List<String> selectedShips = [];
  bool isGameStarted = false;

  Future<void> startGame() async {
    if (selectedShips.length != 5) {
      showErrorDialog(
          context, 'Error', 'Please place exactly 5 ships to start the game.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      showErrorDialog(
        context,
        'Error',
        'No access token found. Please login again.',
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        },
      );
      return;
    }

    final body = {'ships': selectedShips, 'ai': widget.AiType};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint(
            'Game started! ID: ${data['id']}, Player: ${data['player']}, Matched: ${data['matched']}');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => GameList()),
        );
      } else {
        showErrorDialog(
            context, 'Error', 'Failed to start the game. Please try again.');
      }
    } catch (error) {
      debugPrint('Error starting game: $error');
      showErrorDialog(
          context, 'Error', 'An unexpected error occurred. Please try again.');
    }
  }

  void toggleShip(String cell) {
    setState(() {
      if (selectedShips.contains(cell)) {
        selectedShips.remove(cell);
      } else {
        selectedShips.add(cell);
      }
    });
  }

  void showErrorDialog(BuildContext context, String title, String message,
      {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (onOk != null) onOk();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.blue,
          title: Text('New AI Game'),
        ),
        body: SingleChildScrollView(
            child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tap on the cells to place your ships',
                  style: TextStyle(fontSize: 18.0),
                ),
                SizedBox(height: 16.0),
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                  ),
                  itemCount: 25,
                  itemBuilder: (context, index) {
                    final row = index ~/ 5;
                    final col = index % 5;
                    final cell = String.fromCharCode('A'.codeUnitAt(0) + row) +
                        (col + 1).toString();
                    return GestureDetector(
                      onTap: () {
                        if (!isGameStarted) {
                          toggleShip(cell);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          color: selectedShips.contains(cell)
                              ? Colors.blue
                              : Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            cell,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: isGameStarted ? null : startGame,
                  child: Text('Start Game'),
                ),
              ],
            ),
          ),
        )));
  }
}
