#require "project_metric_pivotal_tracker_velocity/version"
require "rest-client"
require "tracker_api"
require "rasem"
require "date"

class ProjectMetricPivotalTrackerVelocity
  attr_reader :raw_data

  DAYS_PER_ITERATION = 7
  def initialize(credentials, raw_data=nil)
    @project = credentials[:project]
    @api_token = credentials[:token]
    @client = TrackerApi::Client.new(token: @api_token)
    @raw_data = raw_data
  end

  def image
    refresh unless @raw_data

    max_y = 15
    min_y = 95
    countings = raw_data[:iteration_velocity]
    unless @image
      image = Rasem::SVGImage.new(120, 100) do
        group :class => "grid y-grid" do
          line(20, 0, 20, 95)
        end
        group :class => "grid x-grid" do
          line(20, 95, 120, 95)
        end
        group do
          text 0, max_y, "100", "font-size" => "10px"
          text 0, 35, "75", "font-size" => "10px"
          text 0, 55, "50", "font-size" => "10px"
          text 0, 75, "25", "font-size" => "10px"
          text 0, min_y, "0", "font-size" => "10px"
        end
        group do
          total_length = countings.length
          prev_loc_x, prev_loc_y = 20, 95
          countings.each do |ite|
            tmp_loc_x = 20 + (ite[:ite_number] * 100 / total_length).to_i
            tmp_loc_y = 95 - ite[:velocity] * 2
            line prev_loc_x, prev_loc_y, tmp_loc_x, tmp_loc_y
            circle tmp_loc_x, tmp_loc_y, 4, "fill" => "green"
            prev_loc_x, prev_loc_y = tmp_loc_x, tmp_loc_y
          end
        end
      end
    end
    return @image = image.output.lines.to_a[3..-1].join
  end

  def refresh

    project = @client.project(@project)
    # Delivered = Opentruct.new(:estimate, :time_delivered)
    lstEstimateAndTime = project.stories(with_state: :accepted||:delivered||:finished).map do |story|
      if story.estimate
        puts story.estimate
        puts (story.updated_at.to_date - story.created_at.to_date).round
        { :estimate => story.estimate, :time_difference => (story.updated_at.to_date - story.created_at.to_date).round }
      else
        { :estimate => 1, :time_delivered => (story.updated_at.to_date - story.created_at.to_date).round }
      end
    end

    # @countings = Array.new()
    lstEstimateAndTime.each do |story|
      points = story[:estimate]
      duration = story[:time_difference]
      if @time_estimates == nil
        @time_estimates = {points => [duration]}
      else
        if @time_estimates.key?(points)
          @time_estimates[points] += [duration]
        else
          @time_estimates[points] = [duration]
        end
      end
    puts @time_estimates
    puts @time_estimates[1.0]
    puts "break"
    end
    @raw_data = {iteration_velocity: @countings}
  end

  def raw_data= new
    @raw_data = new
    @score = @image = nil
  end

  def score
    refresh unless @raw_data
    @time_estimates[1.0].inject(0.0) { |sum, el| sum + el[1.0]} / @time_estimates[1.0].size
    puts @time_estimates
  end

  private
  def api_story_transactions
    response = RestClient.get(get_url("/projects/#{@project}/story_transitions"),
      headers = {X_TrackerToken: @api_token, content_type: :json})
    # NOT SAFE!
    JSON.parse(response.body)
  end

  def get_url(resource)
    "https://www.pivotaltracker.com/services/v5" + resource
  end

  def time_exceed?(time_end, time_start)
    time_limit = DAYS_PER_ITERATION
    (time_end - time_start).to_i > time_limit
  end

end

p = ProjectMetricPivotalTrackerVelocity.new({:project => 1546415, :token => 'c81465eccc3a3765f8974d7a3c3c95b9'})
p.refresh()
p.score()

json.load(response)

