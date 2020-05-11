module Pylon
  class SurveyPlatform
    # todo: explain this or turn it dynamic
    PUBLISHER_USER_UUID = "07bfe320-86d2-0131-c9aa-0a424708edaa"

    def initialize(**args)
      @env = args[:env] || :development
      @survey_uuid = args[:survey_uuid] || "702d4dc9-be4f-46ca-a1a4-025e5995fa6e" # todo: what is this hard coding dude
      @completion_uuid = nil
    end

    def initialize_completion
      url = url_for(:show_surveys).gsub(":survey_uuid", survey_uuid)
      params = {
        panel_user_id: "PYLON_USER_ID",
        panel_user_id_kind: "PYLON_USER_ID_KIND",
        offer_click_uuid: "PYLON_OFFER_CLICK_UUID"
      }
      response = HTTParty.get(url, headers: headers, query: params)
      @completion_uuid = response.parsed_response["completion_uuid"]
      return @completion_uuid.present?
    end

    def fake_completion!(env: :development)
      return "Call initialize_completion first to get a completion_uuid" unless @completion_uuid

      params = {
        panel_user_id: "PYLON_USER_ID",
        panel_user_id_kind: "PYLON_USER_ID_KIND",
        pparam_offer_click_id: "PYLON_OFFER_CLICK_ID",
        pparam_provider_user_id: "[provider_user_uuid]",
        completion_uuid: @completion_uuid,
        partial_update: false,
        terminated: false
      }

      # todo: some hardcoded date in here
      body = '{"answers_ids":[{"question_id":"social_login_question_id","value":"richard.gould@daliaresearch.com","exposed_at":"2020-04-07T09:03:14.672Z","is_real_answer_question":false}],"variables":{}}'

      url = url_for(:create_completion).gsub(":survey_uuid", survey_uuid)
      return HTTParty.post(url, headers: headers, query: params, body: body)
    end

    def url_for(endpoint)
      endpoint_url = case endpoint
                     when :show_surveys
                       "/api/publisher/publisher_users/#{PUBLISHER_USER_UUID}/surveys/:survey_uuid"
                     when :create_completion 
                       "/api/publisher/publisher_users/#{PUBLISHER_USER_UUID}/surveys/:survey_uuid/completions"
                     else
                       raise StandardError.new("Endpoint doesn't exist: #{endpoint}")
                     end
      base_url + endpoint_url
    end

    def base_url
      case env
      when :development
        "http://surveyplatform.daliaresearch.com.pizza"
      when :staging
        "https://surveyplatform.staging.daliaresearch.com"
      when :production
        raise StandardError.new "You're in production? Sorry dude, I'm cutting you off."
      end
    end

    def survey_uuid; @survey_uuid or raise StandardError.new("No survey_uuid given"); end

    def env
      @env
    end

    def headers
      {
        "Content-Type": "application/json;charset=UTF-8",
        Authorization: "Dalia c024b6864fd3f985048b9c44c21fbb90fb4d7da36be8a6326286a85173a00efca26eab98279ba7c7746fab47a2175afaeef259ce994e73130d573f10ed36a3b8"
      }
    end
  end

  def generate_survey
    survey = OpenStruct.new

    survey.title = "Random title"
    survey.title_internal = "Random internal title" # Dont know the difference from title
    survey.kind = "prng_survey"
    survey.control_panel_user_id = "1" # need an Entity
    survey.researcher_user_id = "Thyago" # dont know if needs an Entity
    survey.active = false
    survey.is_completion_speed_control_active = true

    survey.body = parse_survey_body(fetch_news)
    survey.pseudo_body = survey.body

    survey
  end

  def fetch_news
    reuters_url = "http://feeds.reuters.com/reuters/AFRICAWorldNews"

    questions = []

    open(reuters_url) do |rss|
      feed = RSS::Parser.parse(rss)
      puts feed.channel.title
      questions = feed.items.map do |item|
        { title: item.title, url: item.link, description: ActionView::Base.full_sanitizer.sanitize(item.description) }
      end
    end

    questions
  end

  def parse_survey_body(questions)
    {
      locale: "en",
      screens: generate_survey_screens(questions)
    }
  end

  def generate_survey_screens(questions)
    questions.map do |question|
      question_id = SecureRandom.hex

      {
        id: SecureRandom.hex,
        questions: [
          id: question_id,
          kind: "multiple_sole",
          title: question[:title],
          report_title: "report_#{question_id}",
          report_info: "INFO - #{question[:title]}",
          body: {
            "options": [
              {
                "id": "O0010",
                "text": "Yes"
              },
              {
                "id": "O0020",
                "text": "No"
              },
              {
                "id": "O0030",
                "text": "Don’t know"
              }
            ]
          }
        ]
      }
    end
  end
end
