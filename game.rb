require './board'
require './key_input'
require 'yaml'

class Game
  attr_reader :board, :cursor, :current_player

  def initialize(player1_name, player2_name, board = Board.new_game)
    @board = Board.new_game
    @messages = ""
    set_up_players(player1_name, player2_name)
  end

  def play
    inform_colors

    until game_over?
      begin
        start_position, end_position = get_move

        @board.move(start_position, end_position)
      rescue MoveError => e
        @messages += "There is no piece there!"
        retry
      rescue TypeError
        @messages += "That's not your piece!"
        retry
      end

      next_turn
    end

    puts @board
    end_game
  end

  private

  def set_up_players(player1_name, player2_name)
    colors = [:white, :black].shuffle
    @player1 = HumanPlayer.new(colors.first, player1_name)
    @player2 = HumanPlayer.new(colors.last, player2_name)
    @current_player = @player1.color == :white ? @player1 : @player2
  end

  def next_turn
    @current_player = (@current_player == @player1 ? @player2 : @player1)
  end

  def move_cursor(direction)
    case direction
    when :up
      if @board.cursor[1] > 0
        @board.cursor = [@board.cursor[0], @board.cursor[1] - 1]
      else
        @board.cursor = [@board.cursor[0], 7]
      end
    when :down
      if @board.cursor[1] < 7
        @board.cursor = [@board.cursor[0], @board.cursor[1] + 1]
      else
        @board.cursor = [@board.cursor[0], 0]
      end
    when :left
      if @board.cursor[0] > 0
        @board.cursor = [@board.cursor[0] - 1, @board.cursor[1]]
      else
        @board.cursor = [7, @board.cursor[1]]
      end
    when :right
      if @board.cursor[0] < 7
        @board.cursor = [@board.cursor[0] + 1, @board.cursor[1]]
      else
        @board.cursor = [0, @board.cursor[1]]
      end
    end
  end

  def game_over?
    @board.checkmate?(:white) || @board.checkmate?(:black)
  end

  def end_game
    winning_player = @player1.color == :white ? @player1 : @player2
    puts "Checkmate! #{winning_player} WINS!"
  end

  def winner
    @board.checkmate?(:black) ? :white : :black
  end

  def get_input
    input = read_char
    case input
    when "\e[A"     # up arrow
      return :up
    when "\e[B"     # down arrow
      return :down
    when "\e[D"     # left arrow
      return :left
    when "\e[C"     # right arrow
      return :right
    when " "        # select piece
      return :select
    when "q"
      return :quit
    when "s"
      return :save
    when "l"
      return :load
    else
      get_input
    end
  end

  def get_move
    @board.player_moves = []

    loop do
      display_board

      player_move = get_input

      case player_move
      when :select
        current_space = @board[@board.cursor]

        if @board.player_moves.empty?
          raise MoveError if current_space.nil?
          raise TypeError if current_space.color != @current_player.color
        end

        @board.player_moves << @board.cursor.dup
        return @board.player_moves if @board.player_moves.length == 2
      when :quit
        puts "\n#{@current_player} is a quitter."
        exit
      when :save
        save_game
      when :load
        load_game
      else
        move_cursor(player_move)
      end
    end
  end

  def save_game
    print "Enter file name: "
    File.open("#{gets.chomp}.txt", "w") do |f|
      f.puts self.to_yaml
    end

    @messages += "Game saved!"
  end

  def load_game
    print "Enter file name: "
    file_name = gets.chomp

    contents = File.read("#{file_name}.txt")
    loaded_game = YAML::load(contents)

    loaded_game.play

    exit
  end

  def inform_colors
    system "clear"
    puts "#{@player1} is playing as #{@player1.color}"
    puts "#{@player2} is playing as #{@player2.color}"
    puts "#{@current_player} will go first"

    puts "\nUse the cursor to navigate around the board, and"
    puts "use the space bar to select pieces and move them."
    puts "Press 'q' to quit, 's' to save, and 'l' to load."

    puts "\nPress the space bar to continue"
    get_input
  end

  def display_board
    system "clear"
    puts @board
    puts "It's #{@current_player}'s turn"
    print @messages

    @messages = ""
  end
end

class HumanPlayer
  attr_reader :color, :name

  def initialize(color, name)
    @color, @name = color, name
  end

  def to_s
    @name
  end

end

if __FILE__ == $PROGRAM_NAME
  game = Game.new("Kyle", "Xerxes")
  game.play
end