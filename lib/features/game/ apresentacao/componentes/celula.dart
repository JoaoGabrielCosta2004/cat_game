import 'package:chat_noir/core/styles/cor.dart';
import 'package:chat_noir/features/game/data/modeloCelula.dart';
import 'package:chat_noir/features/game/%20apresentacao/componentes/formato.dart';
import 'package:flutter/material.dart';

class HexCell extends StatelessWidget {
  final CellModel cell;
  final VoidCallback onTap;
  final bool isValidMove;

  const HexCell({
    super.key,
    required this.cell,
    required this.onTap,
    this.isValidMove = false,
  });

  Color _getColorForState(CellState state) {
    if (isValidMove && state == CellState.empty) {
      return Color.fromARGB(255, 144, 238, 144); // Verde mais brilhante
    }

    switch (state) {
      case CellState.empty: return AppColors.cell; 
      case CellState.blocked: return AppColors.cellBlocked;
      case CellState.cat: return AppColors.cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: HexClipper(),
        child: Container(
          color: _getColorForState(cell.state), 
          width: 80, 
          height: 80, 
          ),
        ),
      );
    }
  }
