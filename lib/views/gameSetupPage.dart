// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:battleships/utils/auth.dart';
import 'package:battleships/views/gamesList.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:battleships/utils/constants.dart';


import 'package:shared_preferences/shared_preferences.dart';



class GameSetupPage extends StatefulWidget {
  const GameSetupPage({super.key});

  @override
  _GameSetupPageState createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage> {
  List<String> selectedShips = [];
  bool isGameStarted = false;

  void handleCellSelection(String cell) {
    setState(() {
      if (selectedShips.contains(cell)) {
        selectedShips.remove(cell);
      } else {
        selectedShips.add(cell);
      }
    });
  }

  Future<void> initiateGame() async {
    if (selectedShips.length != 5) {
      displayErrorDialog(
        context,
        'Error',
        'Please place exactly 5 ships to start the game.',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      displayErrorDialog(
        context,
        'Error',
        'No access token found. Please log in again.',
        additionalAction: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        },
      );
      return;
    }

    final requestBody = {'ships': selectedShips};

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint(
            'Game started! ID: ${responseData['id']}, Player: ${responseData['player']}, Matched: ${responseData['matched']}');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => GameList()),
        );
      } else {
        displayErrorDialog(
          context,
          'Error',
          'Failed to start the game. Please try again.',
        );
      }
    } catch (error) {
      debugPrint('Error starting game: $error');
      displayErrorDialog(
        context,
        'Error',
        'An unexpected error occurred. Please try again later.',
      );
    }
  }

  void displayErrorDialog(BuildContext context, String title, String content,
      {VoidCallback? additionalAction}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (additionalAction != null) additionalAction();
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
          title: Text('New Game'),
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Select cells to position your ships',
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
                    final cellId =
                        String.fromCharCode('A'.codeUnitAt(0) + row) +
                            (col + 1).toString();

                    return GestureDetector(
                      onTap: () {
                        if (!isGameStarted) {
                          handleCellSelection(cellId);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          color: selectedShips.contains(cellId)
                              ? Colors.blue
                              : Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            cellId,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: isGameStarted ? null : initiateGame,
                  child: Text('Start Game'),
                ),
              ],
            ),
          ),
        )));
  }
}
