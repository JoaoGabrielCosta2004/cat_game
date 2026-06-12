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

  List<CellModel> getAvailableMovesForCat() {
    return _getAvailableNeighbors(catPosition);
  }

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

  void handlePlayerMove(int row, int col) {
    if (_gameStatus != GameStatus.playing) return;

    final cell = board[row][col];
    
    if (!_isValidPlayerMove(cell)) return;

    catPosition.state = CellState.empty;
    catPosition = cell;
    catPosition.state = CellState.cat;

    if (_isOnEdge(catPosition)) {
      _gameStatus = GameStatus.playerWon;
      _playerScore++;
      notifyListeners();
      return;
    }

    if (_isSurrounded(catPosition)) {
      _gameStatus = GameStatus.catWon;
      _cpuScore++;
      notifyListeners();
      return;
    }

    notifyListeners();

    Future.delayed(const Duration(milliseconds: 300), _cpuPlaceFence);
  }

  bool _isValidPlayerMove(CellModel cell) {
    if (cell.state != CellState.empty) return false;

    final neighbors = _getAvailableNeighbors(catPosition);
    return neighbors.contains(cell);
  }

  void _cpuPlaceFence() {
    if (_gameStatus != GameStatus.playing) return;

    const baseDepth = 3;
    final depth = (_distanceToEdge(catPosition) <= 3) ? 5 : baseDepth;

    final bestMove = _minimaxForFence(catPosition, depth, true, -double.infinity, double.infinity);

    if (bestMove.move != null) {
      bestMove.move!.state = CellState.blocked;

      if (_isSurrounded(catPosition)) {
        _gameStatus = GameStatus.catWon;
        _cpuScore++;
      }
    }

    notifyListeners();
  }

  _MinimaxResult _minimaxForFence(CellModel catPos, int depth, bool isMaximizing, double alpha, double beta) {
    if (depth == 0 || _isSurrounded(catPos)) {
      return _MinimaxResult(_evaluateFencePosition(catPos), null);
    }

    final emptyCells = _getAllEmptyCells();

    if (isMaximizing) {
      double maxEval = -double.infinity;
      CellModel? bestMove;

      for (final emptyCell in emptyCells) {
        emptyCell.state = CellState.blocked;

        final eval = _minimaxForFence(catPos, depth - 1, false, alpha, beta);

        emptyCell.state = CellState.empty;

        if (eval.score > maxEval) {
          maxEval = eval.score;
          bestMove = emptyCell;
        }

        alpha = max(alpha, maxEval);
        if (beta <= alpha) break;
      }

      return _MinimaxResult(maxEval, bestMove);
    } else {
      double minEval = double.infinity;
      CellModel? bestMove;

      final availableMoves = _getAvailableNeighbors(catPos);

      for (final move in availableMoves) {
        final oldPos = catPos;
        catPos = move;

        final eval = _minimaxForFence(catPos, depth - 1, true, alpha, beta);

        catPos = oldPos;

        if (eval.score < minEval) {
          minEval = eval.score;
          bestMove = move;
        }

        beta = min(beta, minEval);
        if (beta <= alpha) break;
      }

      return _MinimaxResult(minEval, bestMove);
    }
  }

  List<CellModel> _getAllEmptyCells() {
    final emptyCells = <CellModel>[];
    for (var row in board) {
      for (var cell in row) {
        if (cell.state == CellState.empty) {
          emptyCells.add(cell);
        }
      }
    }
    return emptyCells;
  }

  double _evaluateFencePosition(CellModel catPos) {
    if (_isSurrounded(catPos)) return 100.0;

    if (_isOnEdge(catPos)) return -100.0;

    final queue = Queue<List<CellModel>>()..add([catPos]);
    final visited = {catPos};
    int distance = 0;

    while (queue.isNotEmpty) {
      distance++;
      final path = queue.removeFirst();
      final current = path.last;

      for (final neighbor in _getAvailableNeighbors(current)) {
        if (!visited.contains(neighbor)) {
          if (_isOnEdge(neighbor)) {
            return -(50.0 - distance);
          }
          visited.add(neighbor);
          queue.add([...path, neighbor]);
        }
      }
    }

    return 50.0;
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
