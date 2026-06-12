import 'package:chat_noir/features/game/logica/logicaJogo.dart';
import 'package:chat_noir/features/game/%20apresentacao/componentes/celula.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HexBoard extends StatelessWidget {
  const HexBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final gameLogic = context.read<GameLogic>();

    return Consumer<GameLogic>(
      builder: (context, game, child) {
        return FittedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(game.board.length, (rowIndex) {
              final row = game.board[rowIndex];

              return Padding(
                padding: EdgeInsets.only(left: rowIndex.isOdd ? 26.0 : 0.0),
                child: Row(
                  children: List.generate(row.length, (colIndex) {
                    final cell = row[colIndex];
                    return HexCell(
                      cell: cell,
                      onTap: () => gameLogic.handlePlayerClick(cell.row, cell.col),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
