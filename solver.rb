class Cell
  attr_accessor :possible_values

  def initialize(int)
    self.possible_values =  case int
                            when Integer
                              int == 0 ? Board::AVAILABLE_NUMBERS.dup : [int]
                            else
                              int
                            end
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
  AVAILABLE_NUMBERS = Array.new(9) {|i| i + 1 }.freeze

  attr_writer :board_array
  attr_accessor :id

  def initialize(board_array = nil)
    @board_array = injest_board board_array if board_array
    reset_changed_marker!
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

  def with_each_cell
    @board_array.each_with_index.flat_map do |row, y|
      row.each_with_index.map do |cell, x|
        yield cell, x, y
      end
    end
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

  def set_cell(cell, possible_values)
    # Don't do anythingg unless possible values changes
    return unless cell.possible_values.sort != possible_values.sort

    @changed_marker = true
    cell.possible_values = possible_values
  end

  def changed?
    @changed_marker
  end

  def reset_changed_marker!
    @changed_marker = false
  end

  def pick_one!
    cell, x, y = decision_cell
    value = cell.possible_values.shift
    unless value
      puts "Ran out of values for #{x},#{y}. Broken board."
      raise Solver::BrokenBoard
    end
    new_board = deep_copy
    new_board_cell = new_board.at(x,y)
    new_board.set_cell(new_board_cell, [value])
    puts "picked #{value} for #{x},#{y}"
    new_board
  end

  def solved?
    results = with_each_cell do |cell, x, y|
      cell.solved?
    end.uniq

    results == [true]
  end

  def deep_copy
    board_array = []
    with_each_cell do |cell, x, y|
      board_array[y] ||= []
      board_array[y][x] = Cell.new(cell.possible_values)
    end

    board = self.class.new
    board.board_array = board_array
    board
  end

  private

  def decision_cell
    @decision_cell ||= unsolved_cells.min_by do |cell, x, y|
      cell.possible_values.length
    end
  end

  def unsolved_cells
    with_each_cell do |cell, x, y|
      next if cell.solved?

      [cell, x, y]
    end.compact
  end

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
  BrokenBoard     = Class.new(StandardError)
  UnsolvableBoard = Class.new(StandardError)

  def initialize(board)
    @board = board
    @board.id ||= "0"
  end

  def solve
    # solution.print!

    # puts "Picking one..."
    # @board.pick_one!
    # solution.print!

    # puts "Setting 2,0 to 4..."
    # @board.set_cell(@board.at(2,0), [4])
    # solution.print!
    solution(@board)
    puts "After first solution #{@board.id}"
    begin
      count = 0
      while !@board.solved?
        puts "Picking one... count #{@board.id}"
        new_board = @board.pick_one!
        new_board.id = "#{@board.id}.#{count}"
        begin
          puts "Inner solution #{new_board.id}"
          solution(new_board)
          if new_board.solved?
            @board = new_board
            @board.id = new_board.id[0,new_board.id.length - 2]
          else
            new_solver = self.class.new(new_board)
            new_solver_board = new_solver.solve
            @board = new_solver_board
            @board.id = new_solver_board.id[0,new_solver_board.id.length - 2]
          end
        rescue BrokenBoard
        end
        count += 1
      end
    rescue BrokenBoard
    end

    if @board.solved?
      puts "Solution: #{@board.id}"
      @board.print!
    end
    @board
  end

  private

  def solution(board)
    loop do
      board.print!
      puts
      board.reset_changed_marker!
      board.with_each_cell do |cell, x, y|
        next if cell.solved?

        possible_values = board.values_available_in_row(y) &
                          board.values_available_in_column(x) &
                          board.values_available_in_box(x, y)

        if possible_values.empty?
          puts "Printing broken board at #{x},#{y}:"
          board.print!
          raise BrokenBoard
        end

        board.set_cell(cell, possible_values)
      end

      break if board.solved?

      unless board.changed?
        puts "******* DEADLOCK!!! *******"
        break
      end
    end

    board
  end
end

# board_array = [
#   [5,3,0,  0,7,0,  0,0,0],
#   [6,0,0,  1,9,5,  0,0,0],
#   [0,9,8,  0,0,0,  0,6,0],

#   [8,0,0,  0,6,0,  0,0,3],
#   [4,0,0,  8,0,3,  0,0,1],
#   [7,0,0,  0,2,0,  0,0,6],

#   [0,6,0,  0,0,0,  2,8,0],
#   [0,0,0,  4,1,9,  0,0,5],
#   [0,0,0,  0,8,0,  0,7,9],
# ] # https://en.wikipedia.org/wiki/Sudoku#/media/File:Sudoku_Puzzle_by_L2G-20050714_standardized_layout.svg

board_array = [
  [5,3,0,  0,7,0,  0,2,0],
  [6,0,0,  1,9,5,  0,0,0],
  [0,9,8,  0,0,0,  0,6,0],

  [8,0,0,  0,6,0,  0,0,3],
  [4,0,0,  8,0,3,  0,0,1],
  [7,0,0,  0,2,0,  0,0,6],

  [0,6,0,  0,0,0,  2,0,0],
  [0,0,0,  4,1,9,  0,0,0],
  [0,0,0,  0,8,0,  0,0,0],
]
b = Board.new(board_array)

b.print!
s = Solver.new(b)
s.solve
