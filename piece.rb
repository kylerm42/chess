class Piece
  attr_accessor :color, :position, :board
  attr_reader :king

  SLIDES = [[1, 1], [1, -1], [-1, -1], [-1, 1]]
  JUMPS = [[2, 2], [2, -2], [-2, -2], [-2, 2]]

  def initialize(position, color, board, king = false)
    @position = position
    @color = color
    @board = board
    @king = king
    place_piece_on_board(@position)
  end

  def king?
    @king
  end

  def perform_moves(move_seq)
    if move_seq.count == 1
      return perform_slide(move_seq.first) || perform_jump(move_seq.first)
    end

    raise InvalidMoveError unless valid_move_seq?(move_seq)
    perform_moves!(move_seq)

    true
  end

  def perform_slide(end_pos)
    return false unless valid_slides.include?(move_diff(end_pos))

    move!(end_pos)
    check_promotion

    true
  end

  def perform_jump(end_pos)
    return false unless valid_jumps.include?(move_diff(end_pos))

    remove_piece(end_pos)
    move!(end_pos)
    check_promotion

    true
  end

  def dup_with_board(board)
    new_piece = self.dup
    new_piece.board = board
    new_piece.place_piece_on_board(@position)
  end

  def place_piece_on_board(position)
    @board[position] = self
  end


  private

  def perform_moves!(move_seq)
    move_seq.each do |jump|
      self.perform_jump(jump)
    end
  end

  def valid_move_seq?(move_seq)
    duped_board = @board.dup
    piece = duped_board[@position]

    move_seq.all? do |jump|
      piece.perform_jump(jump)
    end
  end

  def move!(end_pos)
    @board[@position] = nil
    @position = end_pos
    @board[@position] = self
  end

  def remove_piece(end_pos)
    jumped_diff = move_diff(end_pos).map { |coord| coord / 2 }
    jumped_space = [@position[0] + jumped_diff[0], @position[1] + jumped_diff[1]]
    @board[jumped_space] = nil # removing jumped piece
  end

  def check_promotion
    @king = true if on_back_row?
  end

  def on_back_row?
    (@color == :red && @position[0] == 0) || (@color == :black && @position[0] == 7)
  end

  def move_diff(end_pos)
    [end_pos[0] - @position[0], end_pos[1] - @position[1]]
  end

  def valid_slides
    possible_slides.select do |slide|
      check_space(slide).nil?
    end
  end

  def valid_jumps
    possible_jumps.select do |end_space|
      jumped_space = [end_space[0] / 2, end_space[1] / 2]
      jumped_piece = check_space(jumped_space)

      jumped_piece                  &&
      jumped_piece.color != @color  &&
      check_space(end_space).nil?
    end
  end

  def possible_slides
    select_moves_for_color(@color, SLIDES)
  end

  def possible_jumps
    select_moves_for_color(@color, JUMPS).reject do |move|
      @position[0] + move[0] > 7 || @position[1] + move[1] > 7
    end
  end

  def on_board?(position)
    (@position[0] + move[0]).between?(0, 7) || (@position[1] + move[1]).between?(0, 7)
  end

  def check_space(delta)
    @board[[@position[0] + delta[0], @position[1] + delta[1]]]
  end

  def select_moves_for_color(color, moves)
    return moves if @king

    if color == :black
      moves[0..1]
    else
      moves[2..3]
    end
  end
end

class InvalidMoveError < IOError; end