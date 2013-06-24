# -*- coding: utf-8 -*-
class BackgroundBoard

  attr_accessor :grid

  def initialize(ui)
    @ui = ui
    @grid = []
    9.times { @grid << Array.new(9, nil) }
    mine_setup
    fringe_setup
  end

  def reveal(coordinates)
    case @grid[coordinates[0]][coordinates[1]]
    when :bomb
      @ui.display_bomb(coordinates)
    when nil
      @ui.add_number(coordinates)

      (coordinates[0] - 1).upto(coordinates[0] + 1) do |i|
        next if i < 0 || i > (@grid.count - 1)

        (coordinates[1] - 1).upto(coordinates[1] + 1) do |j|
          next if j < 0 || j > (@grid.count - 1)

          reveal([i,j]) if @ui.user_grid[i][j] == "*"
        end
      end
    else
      @ui.add_number(coordinates)
    end
  end

  def mine_setup
    10.times do
      bomb_space = 0
      while bomb_space do
        row, col = rand(9), rand(9)
        bomb_space = @grid[row][col]
      end
      @grid[row][col] = :bomb
    end

  end
  #gives number of bombs around a fringe space
  def fringe_setup
    @grid.each_with_index do |row, index1|
      row.each_with_index do |space, index2|
        next if space == :bomb

        @grid[index1][index2] = adjacent_bombs(index1, index2)
      end
    end

  end

  def adjacent_bombs(index1, index2)
    number_of_bombs = 0
    (index1 - 1).upto(index1 + 1) do |i|
      next if i < 0 || i > (@grid.count - 1)

      (index2 - 1).upto(index2 + 1) do |j|
        next if j < 0 || j > (@grid.count - 1)

        number_of_bombs += 1 if @grid[i][j] == :bomb
      end
    end
    return number_of_bombs.zero? ? nil : number_of_bombs
  end
end

class UI

  attr_accessor :user_grid

  def initialize
    @user_grid = []
    9.times { @user_grid << Array.new(9, "*") }
    @board = BackgroundBoard.new(self)
  end

  def run
    puts "Welcome to MineSweeper!"
    display_user_board

    until done?
      execute_entry(prompt_user) #prompt user returns valid_entry
      display_user_board
    end
    give_results #end game results
    display_user_board
    nil
  end

  def prompt_user
    valid_entry = nil
    until valid_entry
        puts "Input \"r\" to reveal or \"f\" to flag, " +
             "followed by coordinates (e.g. r 2 5)."
         valid_entry = gets_entry
    end
    valid_entry
  end

  def gets_entry
    entry = gets.chomp.downcase.split(/\s+/)
    if ["r","f"].include?(entry[0])
      if ("0".."8").cover?(entry[1]) && ("0".."8").cover?(entry[2])
        return entry
      else
        puts "Make sure coordinates are between 0 and 8."
      end
    else
      puts "Precede your coordinates with \"r\" to reveal or \"f\" to flag."
    end
    nil
  end

  def execute_entry(valid_entry)
    command = valid_entry[0]
    coordinates = valid_entry[1..2].reverse.map(&:to_i)
    if command[0] == "r"
      if @user_grid[coordinates[0]][coordinates[1]] == "F"
        puts "You must unflag this space before revealing it."
        prompt_user
      else
        @board.reveal(coordinates)
      end
    end

    flag(coordinates) if command[0] == "f"
  end

  def flag(coordinates)
    if @user_grid[coordinates[0]][coordinates[1]] == "F"
      @user_grid[coordinates[0]][coordinates[1]] = "*"
    else
      @user_grid[coordinates[0]][coordinates[1]] = "F"
    end
  end

  def display_bomb(coords)
    @user_grid[coords[0]][coords[1]] = "©"
  end

  def add_number(coords)
     if @board.grid[coords[0]][coords[1]].nil?
       @user_grid[coords[0]][coords[1]] = "_"
     else
       @user_grid[coords[0]][coords[1]] = @board.grid[coords[0]][coords[1]]
     end
  end

  def display_user_board
    puts "  " + (0..8).to_a.join(" ")
    @user_grid.each_with_index do |row, index|
      puts "#{index} #{row.join(" ")}"
    end
  end

  def done?
    won? || lost?
  end

  def won?
    unexpored_spaces = 0
    @user_grid.each do |row|
      row.each do |space|
        unexpored_spaces += 1 if space == "*" || space == "F"
      end
    end
    unexpored_spaces == 10
  end

  def lost?
    @user_grid.any?{|row| row.any?{|space| space == "©"}}
  end

  def give_results
    if lost?
      puts "You lost!"
      reveal_all_bombs
    else
      puts "You won!"
    end
  end

  def reveal_all_bombs
    @board.grid.each_with_index do |row, index1|
      row.each_with_index do |space, index2|
        @board.reveal([index1, index2]) if space == :bomb
      end
    end
  end
end
#for running from command line, not in irb
if __FILE__ == $PROGRAM_NAME
  game = UI.new
  game.run
end

