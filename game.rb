require './board'
require 'yaml'
require 'io/console'

class Game
  attr_reader :player1, :player2, :board, :turn

  def initialize(player1, player2)
    @player1 = player1
    @player2 = player2
    @player1.color = :red
    @player2.color = :black
    @board = Board.new
    @turn = @player1
    @message = ""
  end

  def play

    until won?
      begin
        piece_pos, move_seq = get_input
        raise InvalidMoveError if @board[piece_pos].nil? ||
                                  @board[piece_pos].color != @turn.color ||
                                  !@board[piece_pos].perform_moves(move_seq)
      rescue InvalidMoveError
        @message = "That is an invalid move, #{@turn}. Please, make a better move."
        retry
      rescue TypeError
        print "You screwed up, #{@turn}.\nPlease, learn how to type: "
        retry
      end
      switch_turn
    end

    winner = @player1 if @board.pieces.none? { |piece| piece.color == @player2.color }
    winner = @player2 if @board.pieces.none? { |piece| piece.color == @player1.color }

    puts "#{winner} wins!!!"
  end

  def display
    divider = "".tap { |divider| 12.times { divider << "\u2193 "} }
    puts "#{divider}\n#{@board}"
    puts "It is #{@turn}'s turn, make a move"
  end

  private

  def switch_turn
    @turn = (@turn == @player1 ? @player2 : @player1)
  end

  def won?
    # @board.pieces.map(&:color).uniq.length == 1
    @board.pieces.none? { |piece| piece.color == :black} ||
    @board.pieces.none? { |piece| piece.color == :red}
  end

  def get_input

    @board.move_stack = []
    move_stack = @board.move_stack

    action = ""
    until action == "\r"
      system "clear"
      self.display
      puts @message unless @message.empty?
      puts "Moving from: #{move_stack.first}" unless move_stack.empty?
      puts "Moving to: #{move_stack.drop(1)}" unless move_stack.length < 2

      action = STDIN.getch
      case action
      when "A"
        @board.cursor[0] -= 1 if @board.cursor[0] > 0
      when "B"
        @board.cursor[0] += 1 if @board.cursor[0] < 7
      when "C"
        @board.cursor[1] += 1 if @board.cursor[1] < 7
      when "D"
        @board.cursor[1] -= 1 if @board.cursor[1] > 0
      when " "
        move_stack << @board.cursor.dup
      when "s"
        print "Please enter a save game name: "
        save_game(gets.chomp)
      when "l"
        print "Please enter a save game name to load: "
        load_game(gets.chomp)
      when "q"
        puts "#{@turn} is a quitter."
        exit
      end
    end

    @message = ""
    raise InvalidMoveError if move_stack.length < 2
    [move_stack.shift, move_stack]
  end

  def save_game(file_name)
    File.open("#{file_name}.txt", "w") do |f|
      f.puts self.to_yaml
    end
  end

  def load_game(file_name)
    loaded_game = YAML::load(File.read("#{file_name}.txt"))
    @player1, @player2 = loaded_game.player1, loaded_game.player2
    @board = loaded_game.board
    @turn = loaded_game.turn
  end
end

class HumanPlayer
  attr_accessor :color

  def initialize(name = "Xerxes")
    @name = name
  end

  def parse(input, game)
    if input == "quit"
      puts "#{@name} is a quitter."
      exit
    elsif input == "save"
      print "Please enter a saved game name: "
      return save_game(gets.chomp, game)
    elsif input == "load"
      print "Please enter a saved game name: "
      return load_game(gets.chomp)
    end
    raise TypeError if input !~ /(\d,\d\s?){2,}/
    moves = input.split(" ")
    piece_pos = moves.shift.split(",").map(&:to_i)
    moves.map! { |position| position.split(",").map(&:to_i) }
    [piece_pos, moves]
  end

  def to_s
    @name
  end

end

if __FILE__ == $PROGRAM_NAME
  game = Game.new(HumanPlayer.new("Kyle"), HumanPlayer.new)
  game.play
end
