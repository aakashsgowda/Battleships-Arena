# MP Report

## Student information

- Name: Aakash Shivanandappa Gowda
- AID: A20548984

## Self-Evaluation Checklist

Tick the boxes (i.e., fill them with 'X's) that apply to your submission:

- [X] The app builds without error
- [X] I tested the app in at least one of the following platforms (check all
      that apply):
  - [X] iOS simulator / MacOS
  - [X] Android emulator
- [X] Users can register and log in to the server via the app
- [X] Session management works correctly; i.e., the user stays logged in after
      closing and reopening the app, and token expiration necessitates re-login
- [X] The game list displays required information accurately (for both active
      and completed games), and can be manually refreshed
- [X] A game can be started correctly (by placing ships, and sending an
      appropriate request to the server)
- [X] The game board is responsive to changes in screen size
- [X] Games can be started with human and all supported AI opponents
- [X] Gameplay works correctly (including ship placement, attacking, and game
      completion)

## Summary and Reflection

This project was implemented from the ground up using Flutter, focusing on creating a fully functional and visually engaging Battleships game. I implemented all core features including user authentication, game creation against human and AI players, ship placement, shooting mechanics, turn tracking, and game completion handling. A consistent dark theme was applied throughout the app to give it a modern, game-like look. Emojis were used for grid feedback—🛳️ for ships, 💥 for hits, 💣 for misses, and 🫧 for sunk ships—making the game state more intuitive and visually appealing. I also ensured personalized game status messages like “myTurn”, “opponentTurn”, “You won!”, and “You lost!” were displayed clearly based on the logged-in user.

One of the more challenging aspects was managing the game board UI and hover-based scroll behavior, particularly with custom dark backgrounds. Another tricky part was maintaining user state across sessions using SharedPreferences and keeping the UI responsive and accessible.

Overall, I really enjoyed building this project end-to-end. It was a great exercise in applying Flutter concepts, managing state, and integrating a REST API in a clean and user-friendly way. It also helped me improve my UI design skills and understand how to structure a multi-screen app efficiently.
