class Piece
  attr_accessor :position, :board
  attr_reader :color

  PIECE_STRINGS = {
    :pawn => "\u265F",
    :king => "\u265A",
    :queen => "\u265B",
    :rook => "\u265C",
    :bishop => "\u265D",
    :knight => "\u265E"
  }

  def initialize(board, position, color)
    @position = position
    @board = board
    @color = color
    @board[position] = self
  end

  def move_into_check?(position)
    new_board = @board.dup

    new_board.move!(@position, position)
    new_board.in_check?(@color)
  end

  def valid_moves
    moves.select do |position|
      !move_into_check?(position)
    end
  end

  def to_s
    PIECE_STRINGS[self.class.to_s.downcase.to_sym]
  end
end

class SlidingPiece < Piece
  STRAIGHTS = [[0, 1], [0, -1], [1, 0], [-1, 0]]
  DIAGONALS = [[1, 1], [-1, 1], [-1, -1], [1, -1]]

  def moves
    possible_moves = []

    move_dirs.each do |move|
      x, y = @position
      a, b = move

      loop do
        x += a
        y += b
        new_position = [x,y]

        break unless @board.is_valid?(new_position)

        if piece = @board[new_position]
          if piece.color != @color
            possible_moves << new_position
          end

          break
        end

        possible_moves << new_position
      end
    end

    possible_moves
  end
end

class Rook < SlidingPiece
  def move_dirs
    STRAIGHTS
  end
end

class Bishop < SlidingPiece
  def move_dirs
    DIAGONALS
  end
end

class Queen < SlidingPiece
  def move_dirs
    STRAIGHTS + DIAGONALS
  end
end

class SteppingPiece < Piece
  def moves
    possible_moves = []

    move_dirs.each do |move|
      new_move = [@position[0] + move[0], @position[1] + move[1]]

      next unless @board.is_valid?(new_move)

      if !@board[new_move].nil?
        possible_moves << new_move if @board[new_move].color != @color
      else
        possible_moves << new_move
      end
    end

    possible_moves
  end
end

class King < SteppingPiece
  def move_dirs
    [[0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1]]
  end
end

class Knight < SteppingPiece
  def move_dirs
    [[2, 1], [1, 2], [-1, 2], [2, -1], [-2, -1], [-2, 1], [-1, -2], [1, -2]]
  end
end

class Pawn < SteppingPiece
  def move_dirs
    color_modifier = (@color == :white) ? -1 : 1
    move_options = check_forward_squares([0, 1 * color_modifier])
    move_options + pawn_diagonals(color_modifier)
  end

  def check_forward_squares(move)
    a, b = @position
    x, y = move
    possible_moves = []

    if @board[[a, y + b]].nil?
      possible_moves << [0, y]

      return possible_moves if moved?

      possible_moves << [0, y * 2] if @board[[a, y * 2 + b]].nil?
    end

    possible_moves
  end

  def moved?
    @position[1] != (@color == :white ? 6 : 1)
  end

  def pawn_diagonals(color_modifier)
    diagonals = [[1, color_modifier], [-1, color_modifier]]
    possible_moves = []

    diagonals.each do |x, y|
      a, b = @position
      next if @board[[x + a, y + b]].nil?
      if @board[[x + a, y + b]].color != @color
        possible_moves << [x, y]
      end
    end

    possible_moves
  end
end