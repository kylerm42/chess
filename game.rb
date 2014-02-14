require './board'
require './key_input'
require 'yaml'

class Game
  attr_reader :board, :cursor, :current_player

  def initialize
    @board = Board.new_game
    set_up_players
  end

  def next_turn
    @current_player = (@current_player == @player1 ? @player2 : @player1)
  end

  def play
    until game_over?
      begin
        puts @board
        puts "It's #{@current_player}'s turn"
        start_position, end_position = get_move

        raise MoveError.new("You selected an emtpy space, idiot.") if @board[start_position].nil?
        raise TypeError if @board[start_position].color != @current_player.color

        @board.move(start_position, end_position)
      rescue MoveError => e
        puts e.message
        retry
      rescue TypeError
        puts "That's not your piece!"
        retry
      end

      next_turn
    end

    puts @board
    end_game
  end

  def move_cursor(direction)
    if direction == :up
      if @board.cursor[1] > 0
        @board.cursor = [@board.cursor[0], @board.cursor[1] - 1]
      else
        @board.cursor = [@board.cursor[0], 7]
      end
    elsif direction == :down
      if @board.cursor[1] < 7
        @board.cursor = [@board.cursor[0], @board.cursor[1] + 1]
      else
        @board.cursor = [@board.cursor[0], 0]
      end
    elsif direction == :left
      if @board.cursor[0] > 0
        @board.cursor = [@board.cursor[0] - 1, @board.cursor[1]]
      else
        @board.cursor = [7, @board.cursor[1]]
      end
    elsif direction == :right
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
    color = winner
    puts "Checkmate! #{color.upcase} WINS!"
  end

  def winner
    @board.checkmate?(:black) ? :white : :black
  end

  def get_input
    input = read_char
    case input
    when "\e[A"
      #up arrow
      return :up
    when "\e[B"
      #down arrow
      return :down
    when "\e[D"
      #left arrow
      return :left
    when "\e[C"
      #right arrow
      return :right
    when " "
      #select piece
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
    player_moves = []

    loop do
      player_move = get_input
      if player_move == :select
        #do some selecting
        player_moves << @board.cursor.dup
        return player_moves if player_moves.length == 2
      elsif player_move == :quit
        puts "You're a quitter."
        exit
      elsif player_move == :save
        print "Enter file name: "
        file_name = gets.chomp
        File.open("#{file_name}.txt", "w") do |f|
          f.puts self.to_yaml
        end
      elsif player_move == :load
        print "Enter file name: "
        file_name = gets.chomp
        contents = File.read("#{file_name}.txt")
        loaded_game = YAML::load(contents)
        loaded_game.play
        exit
      else
        #move the cursor
        move_cursor(player_move)
        puts @board
        puts "It's #{@current_player}'s turn"
      end
    end
  end


  def set_up_players
    if rand(100) > 49
      @player1 = HumanPlayer.new(:white)
      @player2 = HumanPlayer.new(:black)
      @current_player = @player1
    else
      @player2 = HumanPlayer.new(:white)
      @player1 = HumanPlayer.new(:black)
      @current_player = @player2
    end
  end

end

class HumanPlayer
  attr_reader :color

  def initialize(color)
    @color = color
    inform_color(color)
  end

  def inform_color(color)
    puts "You are #{color}!"
  end

  def play_turn
    begin
      puts "Where would you like to go? eg a1, a4"
      move = gets.chomp.split(", ")
      positions = move.select { |position| position[/[a-h][1-8]/] }
      raise TypeError.new("Invalid input.") if positions.length != 2
    rescue TypeError => e
      puts e.message
      retry
    end
    return positions
  end

  def parse(move)
    choices = []
    letters = %w{a b c d e f g h}

    move.each do |coord|
      x,y = coord.split(//)
      choices << [letters.index(x), (8 - y.to_i)]
    end

    choices
  end

  def to_s
    @color.to_s
  end

end


game = Game.new
game.play
# game.board.move([5, 6], [5, 5])
# puts game.board
# game.board.move([4, 1], [4, 3])
# puts game.board
# game.board.move([6, 6], [6, 4])
# puts game.board
# game.board.move([3, 0], [7, 4])
# puts game.board
# p game.board.checkmate?(:white)

