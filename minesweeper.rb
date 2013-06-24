#require 'debugger'
class BackgroundBoard

  attr_accessor :grid

  def initialize(ui)
    @ui = ui
    @grid = []
    9.times { @grid << Array.new(9, nil) }
    mine_setup
    fringe_setup
  end

  # def flag(coordinates)
 #    if @grid[coordinates[0]][coordinates[1]] == :bomb
 #      @grid[coordinates[0]][coordinates[1]] = :flaggedbomb
 #    else
 #
 #    end
 #  end

  def reveal(coordinates)
    case @grid[coordinates[0]][coordinates[1]]
    when :bomb
      @grid[coordinates[0]][coordinates[1]] = :ex
    when 0
      #user_grid.add_number
      #recursively reveal 8 adjacent spaces
    else
      @ui.add_number(coordinates)
    end
  end

  def done?
    won? || lost?
  end

  def won?
    @grid.all?{|row| row.all? do
      #next if :bomb
    end
  end

  def lost?
    @grid.any?{|row| row.any?{|space| space == :ex}
  end

  def mine_setup
    10.times do
    #  debugger
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
    p @grid
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
    number_of_bombs
  end
end

class UI
  def initialize
    @user_grid = []
    9.times { @user_grid << Array.new(9, "*") }
    @board = BackgroundBoard.new(self)
  end

  def run
    puts "Welcome to MineSweeper!"

    until @board.done?
      execute_entry(prompt_user) #prompt user returns valid_entry
      update_user_board
      display_user_board
    end
    give_results #end game results
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
      if (0..8).cover(entry[1]) && (0..8).cover(entry[2])
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
    command = entry.scan(/\w/)
    coordinates = entry.scan(/\d+/).map{&:to_i}
    @board.reveal(coordinates) if command[0] == "r"
    @board.flag(coordinates) if command[0] == "f"
  end

  def add_number(coords)
    @user_grid[coords[0]][coords[1]] = @board.grid[coords[0]][coords[1]]
  end
end

