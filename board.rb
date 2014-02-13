require './piece'
require 'colorize'

class Board
  attr_accessor :cursor, :move_stack

  def initialize(populate = true)
    @cursor = [0, 0]
    @move_stack = []
    @grid = Array.new(8) { Array.new(8, nil) }
    fill_board if populate
  end

  def fill_board
    (0...4).each do |tile|
      Piece.new([7, tile * 2], :red, self)
      Piece.new([5, tile * 2], :red, self)
      Piece.new([6, tile * 2 + 1], :red, self)
      Piece.new([1, tile * 2], :black, self)
      Piece.new([0, tile * 2 + 1], :black, self)
      Piece.new([2, tile * 2 + 1], :black, self)
    end
  end

  def [](position)
    @grid[position[0]][position[1]]
  end

  def []=(position, piece)
    @grid[position[0]][position[1]] = piece
  end

  def to_s
    color = :white
    board_str = ""
    @grid.each_with_index do |row, row_idx|
      row.each_with_index do |tile, col_idx|
        current_piece = self[[row_idx, col_idx]]
        if current_piece.nil?
          piece = " "
        elsif current_piece.color == :red
          piece = "\u2622".red
          piece = "\u2655".red if current_piece.king?
        else
          piece = "\u2622".light_white
          piece = "\u2655".light_white if current_piece.king?
        end

        if @cursor == [row_idx, col_idx]
          this_str = " " + piece + " "
          board_str += this_str.on_light_blue
        else
          if @move_stack.include?([row_idx, col_idx])
            idx = @move_stack.index([row_idx, col_idx])
            this_str = idx.to_s + piece + " "
            board_str += this_str.on_yellow
          else
            this_str = " " + piece + " "
            board_str += this_str.on_light_white if color == :white
            board_str += this_str.on_black if color == :black
          end
        end
        color = (color == :white ? :black : :white) unless col_idx == 7
      end
      board_str += "\n"
    end

    board_str
  end

  def display
    divider = "".tap { |divider| 12.times { divider << "\u2193 "} }
    puts "#{divider}\n#{self}"
  end

  def pieces
    @grid.flatten.compact
  end

  def dup
    new_board = Board.new(false)

    pieces.each { |piece| piece.dup_with_board(new_board) }

    new_board
  end
end

if __FILE__ == $PROGRAM_NAME
  board = Board.new(false)
  Piece.new([3, 2], :red, board, true)
  Piece.new([4, 3], :black, board)
  Piece.new([6, 3], :black, board)
  Piece.new([6, 1], :black, board)
  Piece.new([4, 1], :black, board)
  puts board
  board[[3, 2]].perform_moves([[5, 4], [7, 2], [5, 0], [3, 2]])
  # board[[5, 6]].perform_moves!([[4, 7]])
  # puts "========================"
  # puts board
end