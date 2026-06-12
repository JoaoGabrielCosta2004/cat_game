import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:chat_noir/core/constants.dart';
import 'package:chat_noir/features/game/data/modeloCelula.dart';

enum GameStatus { playing, playerWon, catWon }

class _MinimaxResult {
  final double score;
  final CellModel? move;
  _MinimaxResult(this.score, this.move);
}

class GameLogic extends ChangeNotifier {
  int _playerScore = 0;
  int _cpuScore = 0;
  GameStatus _gameStatus = GameStatus.playing;

  late List<List<CellModel>> board;
  late CellModel catPosition;

  final Set<CellModel> _catVisited = {};

  int get playerScore => _playerScore;
  int get cpuScore => _cpuScore;
  GameStatus get gameStatus => _gameStatus;

  GameLogic() {
    _initializeGame();
  }

  void resetGame() {
    _gameStatus = GameStatus.playing;
    _catVisited.clear();
    _initializeBoard();
    _placeInitialFences();
    notifyListeners();
  }

  void resetAll() {
    _playerScore = 0;
    _cpuScore = 0;
    resetGame();
  }

  void _initializeGame() {
    resetGame();
  }

  void _initializeBoard() {
    board = List.generate(
      kNumRows,
      (row) => List.generate(
        kNumCols,
        (col) => CellModel(row: row, col: col),
      ),
    );

    catPosition = board[5][5];
    catPosition.state = CellState.cat;
  }

  void _placeInitialFences() {
    final random = Random();
    final fenceCount = random.nextInt(7) + 12;
    int placed = 0;

    while (placed < fenceCount) {
      final row = random.nextInt(kNumRows);
      final col = random.nextInt(kNumCols);
      final cell = board[row][col];

      if (cell.state == CellState.empty) {
        cell.state = CellState.blocked;
        placed++;
      }
    }
  }

  void handlePlayerClick(int row, int col) {
    if (_gameStatus != GameStatus.playing) return;

    final cell = board[row][col];
    if (cell.state != CellState.empty) return;

    cell.state = CellState.blocked;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 300), _cpuMove);
  }

  void _cpuMove() {
    if (_gameStatus != GameStatus.playing) return;

    const baseDepth = 3;
    final depth = (_distanceToEdge(catPosition) <= 3) ? 5 : baseDepth;

    final bestMove = _minimax(catPosition, depth, true, -double.infinity, double.infinity);

    if (bestMove.move != null) {
      _catVisited.add(catPosition); 
      catPosition.state = CellState.empty;
      catPosition = bestMove.move!;
      catPosition.state = CellState.cat;

      if (_isOnEdge(catPosition)) {
        _gameStatus = GameStatus.catWon;
        _cpuScore++;
      }
    } else {
      _gameStatus = GameStatus.playerWon;
      _playerScore++;
    }

    notifyListeners();
  }

  _MinimaxResult _minimax(CellModel position, int depth, bool isMaximizing, double alpha, double beta) {
    if (depth == 0 || _isOnEdge(position) || _isSurrounded(position)) {
      return _MinimaxResult(_evaluateBoard(position), null);
    }

    final neighbors = _getAvailableNeighbors(position);

    if (isMaximizing) {
      double maxEval = -double.infinity;
      CellModel? bestMove;

      for (final neighbor in neighbors) {
        final eval = _minimax(neighbor, depth - 1, false, alpha, beta);

        if (eval.score > maxEval) {
          maxEval = eval.score;
          bestMove = neighbor;
        }
        else if (eval.score == maxEval && bestMove != null) {
          if (_distanceToEdge(neighbor) < _distanceToEdge(bestMove)) {
            bestMove = neighbor;
          }
        }

        alpha = max(alpha, maxEval);
        if (beta <= alpha) break;
      }

      return _MinimaxResult(maxEval, bestMove);
    } else {
      double minEval = double.infinity;

      for (final neighbor in neighbors) {
        final eval = _minimax(neighbor, depth - 1, true, alpha, beta);
        minEval = min(minEval, eval.score);
        beta = min(beta, minEval);
        if (beta <= alpha) break;
      }

      return _MinimaxResult(minEval, null);
    }
  }

  double _evaluateBoard(CellModel position) {
    if (_isOnEdge(position)) return 100.0;
    if (_isSurrounded(position)) return -100.0;

    if (_catVisited.contains(position)) {
      return -200.0;
    }

    final queue = Queue<List<CellModel>>()..add([position]);
    final visited = {position};

    int distance = 0;

    while (queue.isNotEmpty) {
      distance++;
      final path = queue.removeFirst();
      final current = path.last;

      for (final neighbor in _getAvailableNeighbors(current)) {
        if (!visited.contains(neighbor)) {
          if (_isOnEdge(neighbor)) return 50.0 - distance;
          visited.add(neighbor);
          queue.add([...path, neighbor]);
        }
      }
    }

    return -50.0;
  }

  bool _isOnEdge(CellModel cell) {
    return cell.row == 0 || cell.row == kNumRows - 1 || cell.col == 0 || cell.col == kNumCols - 1;
  }

  bool _isSurrounded(CellModel cell) {
    return _getAvailableNeighbors(cell).isEmpty;
  }

  List<CellModel> _getAvailableNeighbors(CellModel cell) {
    return _getNeighbors(cell).where((n) => n.state != CellState.blocked).toList();
  }

  List<CellModel> _getNeighbors(CellModel cell) {
    final r = cell.row;
    final c = cell.col;
    final isEvenRow = r % 2 == 0;

    final directions = isEvenRow
        ? [[-1, 0], [-1, -1], [0, -1], [0, 1], [1, 0], [1, -1]]
        : [[-1, 1], [-1, 0], [0, -1], [0, 1], [1, 1], [1, 0]];

    final neighbors = <CellModel>[];

    for (final dir in directions) {
      final newRow = r + dir[0];
      final newCol = c + dir[1];

      if (newRow >= 0 && newRow < kNumRows && newCol >= 0 && newCol < kNumCols) {
        neighbors.add(board[newRow][newCol]);
      }
    }

    return neighbors;
  }

  int _distanceToEdge(CellModel cell) {
    final top = cell.row;
    final bottom = kNumRows - 1 - cell.row;
    final left = cell.col;
    final right = kNumCols - 1 - cell.col;
    return min(min(top, bottom), min(left, right));
  }
}
