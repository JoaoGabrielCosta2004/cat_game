import 'package:chat_noir/features/game/logica/logicaJogo.dart';
import 'package:chat_noir/features/game/%20apresentacao/componentes/tabuleiro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  void _gameStatusListener() {
    final game = context.read<GameLogic>();

    if (game.gameStatus != GameStatus.playing) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _showEndGameDialog(game.gameStatus);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<GameLogic>().addListener(_gameStatusListener);
  }

  @override
  void dispose() {
    context.read<GameLogic>().removeListener(_gameStatusListener);
    super.dispose();
  }

  void _showEndGameDialog(GameStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  status == GameStatus.playerWon ? 'Você Venceu!' : 'Você Perdeu!',
                  style: const TextStyle(fontFamily: 'Pacifico', fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Text(
                  status == GameStatus.playerWon
                      ? 'Você O Capturou'
                      : 'O Gato Escapou',
                  style: const TextStyle(fontFamily: 'Pacifico'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  child: const Text(
                    'Reiniciar',
                    style: TextStyle(fontFamily: 'Pacifico'),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<GameLogic>().resetGame();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gato Preto',
          style: TextStyle(fontFamily: 'Pacifico', fontSize: 26),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<GameLogic>(
                builder: (context, game, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Jogador: ${game.playerScore}',
                        style: const TextStyle(fontFamily: 'Pacifico'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.read<GameLogic>().resetAll();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 40), 
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text(
                          'Zerar Placar',
                          style: TextStyle(fontFamily: 'Pacifico'),
                        ),
                      ),
                      Text(
                        'Gato: ${game.cpuScore}',
                        style: const TextStyle(fontFamily: 'Pacifico'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const Expanded(
                child: Center(
                  child: HexBoard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
