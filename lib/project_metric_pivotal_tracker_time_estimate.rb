require "project_metric_pivotal_tracker_time_estimate/version"
require "rest-client"
require "tracker_api"
require "rasem"

class ProjectMetricPivotalTrackerTimeEstimate
  attr_reader :raw_data

  DAYS_PER_ITERATION = 7
  def initialize(credentials, raw_data=nil)
    @project = credentials[:project]
    @api_token = credentials[:token]
    @client = TrackerApi::Client.new(token: @api_token)
    @raw_data = raw_data
  end

  def refresh
  	project = @client.project(@project)
    lstEstimateAndTime = project.stories(with_state: :accepted||:delivered||:finished).map do |story|
      if story.estimate
        { :estimate => story.estimate, :time_delivered => story.updated_at }
      else
        { :estimate => 1, :time_delivered => story.updated_at }
      end
    end
    @times = Array.new()
    @raw_data = {iteration_time: @countings}
  end

  private 
  def api_story_transactions
  	response = RestClient.get("https://www.pivotaltracker.com/services/v5/projects/#{@project}/iterations",
  		headers = {X_TrackerToken: @api_token, content_type: :json})
	JSON.parse(response.body)
  end

end

json.load(response)

p = ProjectMetricPivotalTrackerVelocity.new({:project => 1546107, :token => 'c81465eccc3a3765f8974d7a3c3c95b9'})
