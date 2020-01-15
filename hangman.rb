require "colorize"
require "json"

class GameScreen
  attr_reader :has_lost, :has_won, :tries, :word

  def initialize(word, has_lost = false, has_won = false, user_char_list = [], tries = 6)
    @word = word
    @has_lost = has_lost
    @has_won = has_won
    @char_list = @word.split("")
    @user_char_list = user_char_list
    if user_char_list.length == 0
      @char_list.each do
        @user_char_list.push("_")
      end
    end
    @tries = tries
  end

  def to_json
    dict = {}
    instance_variables.each do |instance_var|
      dict[instance_var.to_sym] = instance_variable_get(instance_var)
    end
    dict
  end

  def self.from_json my_dict
    #{"@has_lost":false,"@has_won":false,"@word":"hokku","@char_list":["h","o","k","k","u"],"@user_char_list":["_","o","_","_","_"],"@tries":3}
    GameScreen.new my_dict["@word"], my_dict["@has_lost"], my_dict["@has_won"], my_dict["@user_char_list"], my_dict["@tries"]
  end

  def display
    puts "Tries: #{@tries}"
    puts
    @user_char_list.each do |char|
      print char + " "
    end
    puts
  end

  def guess!
    puts
    puts "Enter your guess character"
    guess = gets.chomp
    if @user_char_list.include? guess
      puts
      puts "Already guessed!".yellow
      puts
      return ""
    end
    if @char_list.include? guess
      puts
      puts "Correct guess!".green
      puts
      @char_list.each_with_index do |char, idx|
        if char == guess
          @user_char_list[idx] = guess
        end
      end

    elsif guess != "/e"
      puts
      puts "Wrong guess!".red
      puts
      @tries -= 1
    end
    @has_lost = true if @tries == 0
    @has_won  = true if !@user_char_list.include? "_"
    guess
  end
end

class MainLoop
  def get_word (filename, filelines)
    word = ""
    File.open(filename) do |file|
      while word.length < 5 || word.length > 12
        pos = rand(filelines)
        counter = 0
        while counter <= pos
          word = file.gets.chomp
          counter += 1
        end
        file.rewind
      end
    end
    word
  end

  def run
    ids = []
    ids << 1 if File.exist? "save1.txt"
    ids << 2 if File.exist? "save2.txt"
    ids << 3 if File.exist? "save3.txt"
    puts "Following game slots are saved"
    ids.each do |i|
      puts "Game: #{i}"
    end
    puts "Would you like to load a game? y/n"
    if gets.chomp == "y"
      puts"What game number would you like to load?"
      initChoice = gets.chomp
      puts
      my_dict = JSON::load(File.read "save#{initChoice}.txt")
      game_screen = GameScreen.from_json(my_dict)
    else
      puts "Starting new game..."
      puts
      game_screen = GameScreen.new get_word("5desk.txt", 61406)
    end
    guess = ""
    while !game_screen.has_won && !game_screen.has_lost && guess != "/e"
      puts "Type and enter '/e' to exit or save"
      puts
      game_screen.display
      guess = game_screen.guess!
    end
    if guess == "/e"
      puts
      puts "Do you want to save game? y/n"
      choice = gets.chomp
      if choice == "y"
        serialized_text = JSON::dump(game_screen.to_json)
        puts serialized_text
        puts "Choose slot 1, 2, or 3"
        choice = gets.chomp
        if choice == "1" || choice == "2" || choice == "3"
          File.open("save#{choice}.txt", 'w') do |file|
            file.puts serialized_text
          end
          puts "File saved!"
        else
          puts "Invalid slot"
        end
      else
        puts "Goodbye!"
      end
    end
    if game_screen.has_won
      puts "You win! The word was #{game_screen.word}"
    end
    if game_screen.has_lost
      puts "You lost, the word was #{game_screen.word}"
    end
  end
end

mainLoop = MainLoop.new
puts mainLoop.run
