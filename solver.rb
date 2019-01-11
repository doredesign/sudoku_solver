class Cell
  attr_accessor :possible_values

  def initialize(int)
    self.possible_values = int == 0 ? Board::AVAILABLE_NUMBERS.dup : [int]
  end

  def to_s
    solved? ? first_value.to_s : " "
  end

  def to_i
    solved? ? first_value : nil
  end

  def solved?
    possible_values.length == 1
  end

  private

  def first_value
    possible_values.first
  end
end

class Board
  AVAILABLE_NUMBERS = Array.new(9) {|i| i+1 }.freeze

  def initialize(board_array)
    @board_array = injest_board board_array
  end

  def print!
    with_each_cell do |cell, x, y|
      print "| " if x % 3 == 0 && x > 0
      print "#{cell} "
      if x == 8
        puts
        puts "------|-------|------" if y % 3 == 2 && y < 8
      end
    end
  end

  def with_each_cell(&block)
    @board_array.each_with_index.map do |row, y|
      row.each_with_index.map do |cell, x|
        block.call(cell, x, y)
      end
    end.flatten
  end

  def values_available_in_row(y)
    AVAILABLE_NUMBERS - values_in_row(y)
  end

  def values_available_in_column(x)
    AVAILABLE_NUMBERS - values_in_column(x)
  end

  def values_available_in_box(x, y)
    AVAILABLE_NUMBERS - values_in_box(x, y)
  end

  def at(x, y)
    @board_array[y][x]
  end

  def solved?
    results = with_each_cell do |cell, x, y|
      cell.solved?
    end.uniq

    results == [true]
  end

  private

  def values_in_row(y)
    @board_array[y].map(&:to_i).compact
  end

  def values_in_column(x)
    @board_array.map do |row|
      row[x].to_i
    end.compact
  end

  def values_in_box(x, y)
    (0..2).each.map do |i|
      adjusted_y = box_boundary_for y, i
      (0..2).each.map do |j|
        adjusted_x = box_boundary_for x, j
        at(adjusted_x, adjusted_y).to_i
      end
    end.flatten.compact
  end

  def injest_board(board)
    board.map do |row|
      row.map do |int|
        Cell.new int
      end
    end
  end

  def box_boundary_for(n, i)
    i % 3 + (3 * (n / 3))
  end
end

class Solver
  def initialize(board)
    @board = board
  end

  def solve
    solution.print!
  end

  private

  def solution
    while !@board.solved? do
      @board.print!
      puts
      @board.with_each_cell do |cell, x, y|
        next if cell.solved?

        possible_values = @board.values_available_in_row(y) &
                          @board.values_available_in_column(x) &
                          @board.values_available_in_box(x, y)

        cell.possible_values = possible_values
      end
    end

    @board
  end
end

board_array = [
  [5,3,0,  0,7,0,  0,0,0],
  [6,0,0,  1,9,5,  0,0,0],
  [0,9,8,  0,0,0,  0,6,0],

  [8,0,0,  0,6,0,  0,0,3],
  [4,0,0,  8,0,3,  0,0,1],
  [7,0,0,  0,2,0,  0,0,6],

  [0,6,0,  0,0,0,  2,8,0],
  [0,0,0,  4,1,9,  0,0,5],
  [0,0,0,  0,8,0,  0,7,9],
] # https://en.wikipedia.org/wiki/Sudoku#/media/File:Sudoku_Puzzle_by_L2G-20050714_standardized_layout.svg
b = Board.new(board_array)
# b.print!
s = Solver.new(b)
s.solve
