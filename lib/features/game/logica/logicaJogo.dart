import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:chat_noir/core/constants.dart';
import 'package:chat_noir/features/game/data/modeloCelula.dart';

enum GameStatus { playing, playerWon, catWon }

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

    const maxFenceDistance = 5;
    final shortestPath = _findShortestPathToEdge(catPosition);

    if (shortestPath == null) {
      _placeNearbyFence(maxFenceDistance);
    } else {
      final placed = _placeFenceAlongShortestPath(shortestPath, maxFenceDistance);
      if (!placed) {
        _placeNearbyFence(maxFenceDistance);
      }
    }

    if (_isSurrounded(catPosition)) {
      _gameStatus = GameStatus.catWon;
      _cpuScore++;
    }

    notifyListeners();
  }

  List<CellModel>? _findShortestPathToEdge(CellModel startPos) {
    final queue = Queue<List<CellModel>>()..add([startPos]);
    final visited = {startPos};

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final current = path.last;

      if (_isOnEdge(current) && current != startPos) {
        return path;
      }

      for (final neighbor in _getAvailableNeighbors(current)) {
        if (visited.contains(neighbor)) continue;
        visited.add(neighbor);
        queue.add([...path, neighbor]);
      }
    }

    return null;
  }

  bool _placeFenceAlongShortestPath(List<CellModel> path, int maxDistance) {
    if (path.length <= 1) return false;

    final candidates = <CellModel>[];
    final maxIndex = min(path.length - 1, maxDistance);

    for (var i = 1; i <= maxIndex; i++) {
      final cell = path[i];
      if (cell.state == CellState.empty) {
        candidates.add(cell);
      }
    }

    if (candidates.isEmpty) return false;

    CellModel? bestCell;
    int bestDistance = -1;
    int bestIndex = -1;

    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
      candidate.state = CellState.blocked;
      final newPath = _findShortestPathToEdge(catPosition);
      candidate.state = CellState.empty;

      if (newPath == null) {
        bestCell = candidate;
        break;
      }

      final distance = newPath.length - 1;
      if (distance > bestDistance || (distance == bestDistance && index > bestIndex)) {
        bestDistance = distance;
        bestCell = candidate;
        bestIndex = index;
      }
    }

    if (bestCell != null) {
      bestCell.state = CellState.blocked;
      return true;
    }

    return false;
  }

  void _placeNearbyFence(int maxDistance) {
    final nearbyEmpty = _getNearestEmptyCellsWithinDistance(catPosition, maxDistance);
    if (nearbyEmpty.isNotEmpty) {
      final random = Random();
      nearbyEmpty[random.nextInt(nearbyEmpty.length)].state = CellState.blocked;
      return;
    }

    final nearestEmpty = _getNearestEmptyCells(catPosition);
    if (nearestEmpty.isNotEmpty) {
      final random = Random();
      nearestEmpty[random.nextInt(nearestEmpty.length)].state = CellState.blocked;
    } else {
      _placeRandomFence();
    }
  }

  List<CellModel> _getNearestEmptyCellsWithinDistance(CellModel startPos, int maxDistance) {
    final queue = Queue<List<CellModel>>()..add([startPos]);
    final visited = {startPos};
    final found = <CellModel>[];
    int? foundDistance;

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final current = path.last;
      final currentDistance = path.length - 1;

      if (foundDistance != null && currentDistance > foundDistance) {
        continue;
      }
      if (currentDistance > maxDistance) {
        continue;
      }

      if (currentDistance > 0 && current.state == CellState.empty) {
        foundDistance ??= currentDistance;
        if (currentDistance == foundDistance) {
          found.add(current);
        }
        continue;
      }

      for (final neighbor in _getNeighbors(current)) {
        if (visited.contains(neighbor)) continue;
        visited.add(neighbor);
        queue.add([...path, neighbor]);
      }
    }

    return found;
  }

  List<CellModel> _getNearestEmptyCells(CellModel startPos) {
    final queue = Queue<List<CellModel>>()..add([startPos]);
    final visited = {startPos};
    final found = <CellModel>[];
    int? foundDistance;

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final current = path.last;
      final currentDistance = path.length - 1;

      if (foundDistance != null && currentDistance > foundDistance) {
        continue;
      }

      if (currentDistance > 0 && current.state == CellState.empty) {
        foundDistance ??= currentDistance;
        if (currentDistance == foundDistance) {
          found.add(current);
        }
        continue;
      }

      for (final neighbor in _getNeighbors(current)) {
        if (visited.contains(neighbor)) continue;
        visited.add(neighbor);
        queue.add([...path, neighbor]);
      }
    }

    return found;
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

  void _placeRandomFence() {
    final emptyCells = _getAllEmptyCells();
    if (emptyCells.isNotEmpty) {
      final random = Random();
      emptyCells[random.nextInt(emptyCells.length)].state = CellState.blocked;
    }
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

}
