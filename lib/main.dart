import 'package:chat_noir/core/theme.dart';
import 'package:chat_noir/features/game/logica/logicaJogo.dart';
import 'package:chat_noir/features/game/%20apresentacao/telas/tela.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameLogic(),
      child: MaterialApp(
        title: 'Gato Preto',
        debugShowCheckedModeBanner: false,
        theme: appTheme, 
        home: const GameScreen(), 
      ),
    );
  }
}
