# -*- coding: utf-8 -*-
require "yaml"
class BackgroundBoard

  attr_accessor :grid

  def initialize(ui, mode)
    @ui = ui
    @grid = []
    build_grid(mode)
  end

  def build_grid(mode)
    mode[1].times { @grid << Array.new(mode[0], nil) }
    mine_setup(mode)
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

          reveal([i,j]) if @ui.user_grid[i][j] == "🐨"
        end
      end
    else
      @ui.add_number(coordinates)
    end
  end

  def mine_setup(mode)
    mode[2].times do
      bomb_space = 0
      while bomb_space do
        row, col = rand(mode[1]), rand(mode[0])
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
  end

  def run
    puts "Welcome to MineSweeper!"
    puts "Enter game mode: easy, medium, or expert"
    mode_hash = {"easy" => [9,9,10],
                 "medium" => [16,16,40],
                 "expert" => [30,16,99]}

    @mode = mode_hash[gets.downcase.strip]

    build_grid
    @board = BackgroundBoard.new(self, @mode)

    display_user_board

    until done?
      execute_entry(prompt_user) #prompt user returns valid_entry
      display_user_board
    end
    give_results #end game results
    display_user_board
    nil
  end

  def build_grid
    @mode[1].times { @user_grid << Array.new(@mode[0], "🐨") }
  end

  def prompt_user
    valid_entry = nil
    until valid_entry
      puts "Input \"r\" to reveal or \"f\" to flag, " +
           "followed by coordinates (e.g. r 2 5).\n"  +
           "Or type \"load\" to load a game file or \"save\" to save."
      valid_entry = gets_entry
    end
    valid_entry
  end

  def gets_entry
    entry = gets.chomp.downcase.split(/\s+/)
    return "save" if entry[0] == "save"
    return "load" if entry[0] == "load"

    if ["r","f"].include?(entry[0])
      if ("0"..((@mode[0]-1).to_s)).include?(entry[1]) &&
         ("0"..((@mode[1]-1).to_s)).include?(entry[2])
        return entry
      else
        puts "Make sure coordinates are between 0 and #{@mode[0]} or " +
              "0 and #{@mode[1]}."
      end
    else
      puts "Precede your coordinates with \"r\" to reveal or \"f\" to flag."
    end
    nil
  end

  def execute_entry(valid_entry)
    return save if valid_entry == "save"
    return load if valid_entry == "load"
    command = valid_entry[0]
    coordinates = valid_entry[1..2].reverse.map(&:to_i)
    if command[0] == "r"
      if @user_grid[coordinates[0]][coordinates[1]] == "📮"
        puts "You must unflag this space before revealing it."
        execute_entry(prompt_user)
      else
        @board.reveal(coordinates)
      end
    end

    flag(coordinates) if command[0] == "f"
  end

  def flag(coordinates)
    if @user_grid[coordinates[0]][coordinates[1]] == "📮"
      @user_grid[coordinates[0]][coordinates[1]] = "🐨"
    else
      @user_grid[coordinates[0]][coordinates[1]] = "📮"
    end
  end

  def display_bomb(coords)
    @user_grid[coords[0]][coords[1]] = "💣"
  end

  def add_number(coords)
     if @board.grid[coords[0]][coords[1]].nil?
       @user_grid[coords[0]][coords[1]] = "_"
     else
       @user_grid[coords[0]][coords[1]] = @board.grid[coords[0]][coords[1]]
     end
  end

  def display_user_board
    puts "   " + (0...9).to_a.join("  ") + "   " +
         (9...@user_grid[0].count).to_a.join(" ")

    @user_grid.each_with_index do |row, index|
      puts " #{index} #{row.join("  ")}" if index < 10
      puts "#{index} #{row.join("  ")}" if index >= 10
    end
  end

  def done?
    won? || lost?
  end

  def won?
    unexpored_spaces = 0
    @user_grid.each do |row|
      row.each do |space|
        unexpored_spaces += 1 if space == "🐨" || space == "📮"
      end
    end
    unexpored_spaces == @mode[2]
  end

  def lost?
    @user_grid.any?{|row| row.any?{|space| space == "💣"}}
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

  def save
    gamestate = [@board.grid, user_grid].to_yaml
    puts "You're saving your current game. Enter a file name (no extension):"
    filename = gets.chomp.downcase
    File.open("#{filename}.txt", "w") {|f| f.puts gamestate}
  end

  def load
    puts "Enter a filename from this directory (no extension):"
    filename = gets.chomp.downcase
    loaded_file = File.read("#{filename}.txt")
    object_array = YAML::load(loaded_file)
    @board.grid, @user_grid = object_array[0], object_array[1]
  end
end
#for running from command line, not in irb
if __FILE__ == $PROGRAM_NAME
  game = UI.new
  game.run
end

