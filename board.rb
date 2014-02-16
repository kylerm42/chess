require './pieces'
require 'colorize'

class Board
  attr_accessor :cursor, :player_moves
  attr_reader :grid

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

  def initialize(grid)
    @grid, @cursor, @player_moves = grid, [0, 0], []
  end

  def [](position)
    x, y = position
    @grid[y][x]
  end

  def []=(position, piece)
    x, y = position
    @grid[y][x] = piece
  end

  def to_s
    color = :white
    board_str = Array.new(8) { Array.new(8, "   ") }

    pieces.each do |piece|
      x, y = piece.position
      board_str[y][x] = " #{piece} ".blue if piece.color == :white
      board_str[y][x] = " #{piece} ".red if piece.color == :black
    end

    @grid.each_with_index do |row, row_idx|
      row.each_with_index do |tile, col_idx|
        piece = board_str[row_idx][col_idx]

        piece = piece.on_light_white if color == :white
        piece = piece.on_black if color == :black

        board_str[row_idx][col_idx] = piece

        color = color == :white ? :black : :white unless col_idx == 7
      end
    end

    if !@player_moves.empty?
      selected_tile = board_str[@player_moves.first[1]][@player_moves.first[0]]
      selected_tile = selected_tile.on_green
      board_str[@player_moves.first[1]][@player_moves.first[0]] = selected_tile

      valid_moves = self[@player_moves.first].valid_moves
      valid_moves.each do |move|
        x, y = move
        board_str[y][x] = board_str[y][x].on_yellow
      end
    end

    board_str.each_with_index { |row, idx| row << (" #{idx + 1}")}
    board_str << (' a '..' h ').to_a

    board_str[@cursor[1]][@cursor[0]] = board_str[@cursor[1]][@cursor[0]].on_cyan

    board_str.map { |row| row.join("") }.join("\n")
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

    check_for_queen_status(current_piece, end_position)

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

    check_for_queen_status(current_piece, end_position)

    self[end_position] = current_piece
  end

  def checkmate?(color)
    pieces_for(color).all? do |piece|
      piece.valid_moves.empty?
    end
  end

  def check_for_queen_status(current_piece, end_position)
    if current_piece.is_a?(Pawn) &&
       (end_position[1] == 0 ||
       end_position[1] == 7)
      current_piece = Queen.new(self, end_position, current_piece.color)
    end
  end

  def dup
    new_grid = @grid.map do |row|
      row.map { |item| item.nil? ? nil : item.dup }
    end

    new_board = Board.new(new_grid)

    new_board.pieces.each { |piece| piece.board = new_board }

    new_board
  end
end

class MoveError < ArgumentError; end