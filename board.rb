require './pieces'
require 'colorize'

class Board
  attr_accessor :cursor
  attr_reader :grid

  def initialize(grid)
    @grid = grid
    @cursor = [0, 0]
  end

  def [](position)
    x, y = position
    @grid[y][x]
  end

  def []=(position, piece)
    x, y = position
    @grid[y][x] = piece
  end

  def display
    system "clear"
    puts self
  end

  def to_s
    system "clear"
    board_str = ["   a  b  c  d  e  f  g  h\n".white]
    @grid.each_with_index do |row, row_idx|
      row_str = "#{row_idx + 1} ".white
      row.each_with_index do |col, col_idx|
        if self[[col_idx, row_idx]].nil?
          piece = "{ }" if @cursor == [col_idx, row_idx]
          piece = "   " if @cursor != [col_idx, row_idx]

          if row_idx % 2 == 0
            if col_idx % 2 == 0
              row_str += piece.black.on_white
            else
              row_str += piece.white.on_black
            end
          else
            if col_idx % 2 == 0
              row_str += piece.white.on_black
            else
              row_str += piece.black.on_white
            end
          end
        else
          piece = "{#{self[[col_idx, row_idx]]}}" if @cursor == [col_idx, row_idx]
          piece = " #{self[[col_idx, row_idx]]} " if @cursor != [col_idx, row_idx]

          if row_idx % 2 == 0
            if col_idx % 2 == 0
              row_str += piece.on_white.light_blue if self[[col_idx, row_idx]].color == :white
              row_str += piece.red.on_white if self[[col_idx, row_idx]].color == :black
            else
              row_str += piece.on_black.light_blue if self[[col_idx, row_idx]].color == :white
              row_str += piece.red.on_black if self[[col_idx, row_idx]].color == :black
            end
          else
            if col_idx % 2 == 0
              row_str += piece.on_black.light_blue if self[[col_idx, row_idx]].color == :white
              row_str += piece.red.on_black if self[[col_idx, row_idx]].color == :black
            else
              row_str += piece.on_white.light_blue if self[[col_idx, row_idx]].color == :white
              row_str += piece.red.on_white if self[[col_idx, row_idx]].color == :black
            end
          end
        end
      end

      board_str << row_str + "\n"
    end
    board_str.join("")
  end

  def is_valid?(position)
    x, y = position
    x.between?(0, 7) && y.between?(0, 7)
  end

  def in_check?(color)
    king = king(color)
    opp_pieces = pieces_for(other_color(color))

    opp_pieces.any? do |piece|
      piece.moves.include?(king.position)
    end
  end

  def pieces
    @grid.flatten.compact
  end

  def pieces_for(color)
    pieces.select { |piece| piece.color == color }
  end

  def other_color(color)
    color == :white ? :black : :white
  end

  def king(color)
    pieces.find { |piece| piece.is_a?(King) && piece.color == color }
  end

  def move(start_position, end_position)
    current_piece = self[start_position]

    raise MoveError.new("Invalid start position!") if current_piece.nil?

    unless current_piece.valid_moves.include?(end_position)
      raise MoveError.new("Invalid ending position!")
    end

    current_piece.position = end_position
    self[start_position] = nil

    #THIS IS FOR QUEENING YOUR PAWNS
    if current_piece.is_a?(Pawn) && end_position[1] == 0
      current_piece = Queen.new(self, end_position, current_piece.color)
    end
    if current_piece.is_a?(Pawn) && end_position[1] == 7
      current_piece = Queen.new(self, end_position, current_piece.color)
    end

    self[end_position] = current_piece
  end

  def move!(start_position, end_position)
    current_piece = self[start_position]

    raise MoveError.new("Invalid start position!") if current_piece.nil?

    if !current_piece.moves.include?(end_position)
      raise MoveError.new("Invalid ending position!")
    end

    current_piece.position = end_position
    self[start_position] = nil
    self[end_position] = current_piece
  end

  def dup
    new_grid = @grid.map do |row|
      row.map do |item|
        item.nil? ? nil : item.dup
      end
    end

    new_board = Board.new(new_grid)

    new_board.pieces.each do |piece|
      piece.board = new_board
    end

    new_board
  end

  def checkmate?(color)
    king = king(color)

    pieces_for(color).all? do |piece|
      piece.valid_moves.empty?
    end
  end

  def self.new_game(grid = Array.new(8) { Array.new(8, nil) })
    board = Board.new(grid)
    8.times do |idx|
      Pawn.new(board, [idx, 1], :black)
    end
    8.times do |idx|
      Pawn.new(board, [idx, 6], :white)
    end

    Rook.new(board, [0, 0], :black)
    Rook.new(board, [7, 0], :black)
    Rook.new(board, [0, 7], :white)
    Rook.new(board, [7, 7], :white)

    Knight.new(board, [1, 0], :black)
    Knight.new(board, [6, 0], :black)
    Knight.new(board, [1, 7], :white)
    Knight.new(board, [6, 7], :white)

    Bishop.new(board, [2, 0], :black)
    Bishop.new(board, [5, 0], :black)
    Bishop.new(board, [2, 7], :white)
    Bishop.new(board, [5, 7], :white)

    King.new(board, [4, 0], :black)
    King.new(board, [4, 7], :white)

    Queen.new(board, [3, 0], :black)
    Queen.new(board, [3, 7], :white)

    board
  end
end

class MoveError < ArgumentError; end

if __FILE__ == $PROGRAM_NAME
  # b = Board.new


end