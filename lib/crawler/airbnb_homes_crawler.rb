class AirbnbHomesCrawler < Crawler
  AIRBNB_HOME = Crawler::AIRBNB_URL + 's/homes?refinement_paths[]=/homes&allow_override[]='
  AIRBNB_EXPLORE_API = Crawler::AIRBNB_URL + 'api/v2/explore_tabs'

  def initialize
    super
  end

  def get_homes(params = {})
    # checkin time is today
    checkin = Time.zone.now.strftime(EasySettings.datetime.date_format)
    # build conditions and redis_key
    new_params = build_conditions(checkin, params.as_json)
    # get all data via api & get search results
    airbnb_api_key = nil
    if params['key'].blank?
      @page = @agent.get("#{AIRBNB_HOME}&checkin=#{checkin}")
      airbnb_api_key = api_key_guest(@page)
    end
    homes_details = homes_detail(new_params, airbnb_api_key)
    # homes
    homes = explore_homes_details(homes_details)
    # pagination
    pagination = pagination(params, homes_details)
    # build json to render
    result = { "pagination" => pagination, "homes" => homes }
    # save data to redis
    return result
  end

  private

  def homes_detail(params, key)
    params.merge!({ 'key': key }) if key
    return get_data_api(AIRBNB_EXPLORE_API, params)
  end

  def explore_homes_details(homes_details)
    return [] unless homes_details
    homes = []
    homes_details['explore_tabs']&.first['sections'].each do |section|
      next if section['title'] && section['title'].downcase.include?('airbnb plus')
      next if section['listings'].blank?
      # listings_count
      section['listings'].each do |data|
        item = data['listing']
        homes <<  { "service_id" => item['id'],
                    "lat"        => item['lat'],
                    "lng"        => item['lng'],
                    "name"       => item['name'],
                    "url"        => "#{Crawler::AIRBNB_ROOM_URL}#{item['id']}",
                    "spec"       => "#{item['space_type']}　#{item['city']}",
                    "pictures"   => item['picture_urls'],
                    "price"      => ActionController::Base.helpers.number_to_currency(
                                        data['pricing_quote']['price']['total']['amount'],
                                        unit: data['pricing_quote']['price']['total']['currency'],
                                        precision: 0, format: '%n'),
                    "currency"   => data['pricing_quote']['price']['total']['currency']
                  }
      end
    end
    homes
  end

  def pagination(params, homes_details)
    return { "back_link" => '', "next_link" => '' } unless homes_details
    listing_count = homes_details['explore_tabs']&.first['home_tab_metadata']['listings_count']
    has_next_page = homes_details['explore_tabs']&.first['pagination_metadata']['has_next_page']

    section_offset = params[:section_offset] || 0
    back_link = if (section_offset.to_i != 0)
                  params[:section_offset] = section_offset.to_i - 1
                  build_link(params)
                end

    next_link = if (has_next_page)
                  params[:section_offset] = section_offset.to_i + 1
                  build_link(params)
                end

    { "back_link" => back_link || '', "next_link" => next_link || '' }
  end


  def build_conditions(checkin, params)
    new_params = ({
      'version': '1.3.4',
      '_format': 'for_explore_search_web',
      'experiences_per_grid': '20',
      'items_per_grid': '18',
      'guidebooks_per_grid': '20',
      'auto_ib': true,
      'fetch_filters': true,
      'has_zero_guest_treatment': false,
      'is_guided_search': true,
      'is_new_cards_experiment': true,
      'luxury_pre_launch': false,
      'query_understanding_enabled': true,
      'show_groupings': true,
      'supports_for_you_v3': true,
      'timezone_offset': '420',
      'metadata_only': false,
      'is_standard_search': true,
      'tab_id': 'home_tab',
      '_intents': 'p1',
      'refinement_paths[]': '/homes',
      'allow_override[]': '',
      'checkin': checkin
    }).merge(params.symbolize_keys)
    return new_params
  end

  def build_link(params)
    uri = URI(EasySettings.sokuhaku_url)
    uri.query = URI.encode_www_form(params.as_json)
    uri.to_s
  end

end
