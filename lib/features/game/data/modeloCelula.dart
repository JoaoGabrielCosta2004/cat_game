enum CellState { empty, blocked, cat }

class CellModel {
  final int row;
  final int col;

  CellState state;

  CellModel({
    required this.row,
    required this.col,
    this.state = CellState.empty,
  });

  @override
  String toString() => 'Cell($row, $col, $state)';

  bool get isEmpty => state == CellState.empty;

  void block() {
    state = CellState.blocked;
  }

  void markAsCat() {
    state = CellState.cat;
  }
}
