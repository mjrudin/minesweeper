# -*- coding: utf-8 -*-
require "yaml"
class BackEnd

  attr_accessor :background_array

  def initialize(difficulty_values)
    @background_array = []
    build_background_array(difficulty_values)
  end

  def iterate_on_fringe(coordinates, &prc)
    (coordinates[0] - 1).upto(coordinates[0] + 1) do |i|
      next if i < 0 || i > (@background_array.count - 1)
      (coordinates[1] - 1).upto(coordinates[1] + 1) do |j|
        next if j < 0 || j > (@background_array.count - 1)

        prc.call(i,j)
      end
    end
  end

  private

  def build_background_array(difficulty_values)
    difficulty_values[1].times do
       @background_array << Array.new(difficulty_values[0], nil)
    end

    setup_mines(difficulty_values)
    setup_fringe
  end

  def setup_mines(difficulty_values)
    difficulty[2].times do
      bomb_space = true
      while bomb_space do
        row, col = rand(difficulty_values[1]), rand(difficulty_values[0])
        bomb_space = @background_array[row][col]
      end

      @background_array[row][col] = :bomb
    end
  end

  #gives number of bombs around a fringe space
  def setup_fringe
    @background_array.each_with_index do |row, index1|
      row.each_with_index do |space, index2|
        next if space == :bomb

        @background_array[index1][index2] = count_adjacent_bombs(index1, index2)
      end
    end
  end

  def count_adjacent_bombs(index1, index2)
    number_of_bombs = 0

    iterate_on_fringe([index1, index2]) do |i, j|
      number_of_bombs += 1 if @background_array[i][j] == :bomb
    end

    number_of_bombs.zero? ? nil : number_of_bombs
  end
end

class UserInterface

  attr_accessor :foreground_array

  def initialize
    @foreground_array = []
  end

  def run
    starting_prompt
    build_foreground_array
    make_back_end
    display_user_board

    until done?
      execute_entry(prompt)
      display_user_board
    end

    give_results
    display_user_board
  end

  def starting_prompt
    puts "Welcome to MineSweeper!"
    puts "Enter game difficulty: easy, medium, or expert"

    #[width,height,number of bombs]
    difficulty_hash = {"easy" => [9,9,10],
                 "medium" => [16,16,40],
                 "expert" => [30,16,99]}

    @difficulty_values = difficulty_hash[gets.downcase.strip]
  end

  def make_back_end
    @back_end = BackEnd.new(self, @difficulty_values)
  end

  def reveal(coordinates)
    display_element(coordinates)

    if (@back_end.background_array[coordinates[0]][coordinates[1]]).nil?
      @back_end.iterate_on_fringe(coordinates) do |i, j|
        reveal([i,j]) if @foreground_array[i][j] == "🐨"
      end
    end
  end

  def build_foreground_array
    @difficulty_values[1].times do
      @foreground_array << Array.new(@difficulty_values[0], "🐨")
    end
  end

  def prompt
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
      if ("0"..((@difficulty_values[0]-1).to_s)).include?(entry[1]) &&
         ("0"..((@difficulty_values[1]-1).to_s)).include?(entry[2])
        return entry
      else
        puts "Make sure coordinates are between 0 and " +
             "#{@difficulty_values[0]} or 0 and #{@difficulty_values[1]}."
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
      if flagged?(coordinates)
        puts "You must unflag this space before revealing it."
        execute_entry(prompt)
      else
        reveal(coordinates)
      end
    end

    flag(coordinates) if command[0] == "f"
  end

  def flagged?(coordinates)
    @foreground_array[coordinates[0]][coordinates[1]] == "📮"
  end

  def flag(coordinates)
    if flagged?(coordinates)
      @foreground_array[coordinates[0]][coordinates[1]] = "🐨"
    else
      @foreground_array[coordinates[0]][coordinates[1]] = "📮"
    end
  end

  def display_element(coords)
    element_hash = {:bomb => "💣", nil => "_",
      1 => 1, 2 => 2, 3 => 3, 4 => 4,
      5 => 5, 6 => 6, 7 => 7, 8 => 8}

    key = @back_end.background_array[coords[0]][coords[1]]
    @foreground_array[coords[0]][coords[1]] = element_hash[key]
  end

  def display_user_board
    puts "   " + (0...9).to_a.join("  ") + "   " +
         (9...@foreground_array[0].count).to_a.join(" ")

    @foreground_array.each_with_index do |row, index|
      puts " #{index} #{row.join("  ")}" if index < 10
      puts "#{index} #{row.join("  ")}" if index >= 10
    end
  end

  def done?
    won? || lost?
  end

  def won?
    unexpored_spaces = 0
    @foreground_array.each do |row|
      row.each do |space|
        unexpored_spaces += 1 if space == "🐨" || space == "📮"
      end
    end
    unexpored_spaces == @difficulty_values[2]
  end

  def lost?
    @foreground_array.any?{|row| row.any?{|space| space == "💣"}}
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
    @back_end.background_array.each_with_index do |row, index1|
      row.each_with_index do |space, index2|
        reveal([index1, index2]) if space == :bomb
      end
    end
  end

  def save
    gamestate = [@back_end.background_array, @foreground_array].to_yaml
    puts "You're saving your current game. Enter a file name (no extension):"
    filename = gets.chomp.downcase
    File.open("#{filename}.txt", "w") {|f| f.puts gamestate}
  end

  def load
    puts "Enter a filename from this directory (no extension):"
    filename = gets.chomp.downcase
    loaded_file = File.read("#{filename}.txt")
    object_array = YAML::load(loaded_file)
    @back_end.background_array = object_array[0]
    @foreground_array = object_array[1]
  end
end

#for running from command line, not in irb
if __FILE__ == $PROGRAM_NAME
  game = UserInterface.new
  game.run
end

