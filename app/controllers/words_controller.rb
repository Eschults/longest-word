require 'open-uri'
require 'json'

class WordsController < ApplicationController
  def game
    @grid = generate_grid(8).join(" - ")
    @start_time = Time.now.to_f
    session[:nb_games] ? session[:nb_games] += 1 : session[:nb_games] = 1
  end

  def score
    start_time = params[:start_time]
    grid = params[:grid]
    end_time = Time.now.to_f
    attempt = params[:attempt]
    @output = run_game(attempt, grid, start_time, end_time)
    session[:aggr_score] ? session[:aggr_score] += @output[:score] : session[:aggr_score] = @output[:score]
    session[:avge_score] = session[:aggr_score].fdiv(session[:nb_games]).to_i
  end

  def generate_grid(grid_size)
    grid = []
    (0..grid_size - 1).each { |i| grid[i] = ('A'..'Z').to_a[rand 0..25] }
    grid
  end

  def run_game(attempt, grid, start_time, end_time)
    output = { time: (end_time.to_i - start_time.to_i), translation: "", score: 100, message: "" }
    check(attempt, grid, output)
    parse(attempt, output)
    unless output[:score] == 0
      output[:score] -= 8 * (8 - attempt.size) + 4 * output[:time]
      output[:message] = "Well done!"
    end
    return output
  end

  def parse(attempt, output)
    parse = ""
    api_url = "http://api.wordreference.com/0.8/80143/json/enfr/#{attempt}"
    open(api_url) { |stream| parse = JSON.parse(stream.read) }
    if parse["term0"].nil?
      output[:translation] = nil
      output[:message] = "not an english word"
      output[:score] = 0
    else
      output[:translation] = parse["term0"]["PrincipalTranslations"]["0"]["FirstTranslation"]["term"]
    end
  end

  def check(attempt, grid, output)
    attempt.split("").each do |letter|
      if attempt.split("").count(letter) > grid.count(letter.upcase)
        output[:score] = 0
        output[:message] = "not in the grid"
      end
    end
  end
end
