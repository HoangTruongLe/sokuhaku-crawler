class RoomsCrawler < Crawler
  def initialize
    super
  end

  def get_service(id)
    @id = id
    @page = @agent.get("#{AIRBNB_ROOM_URL}#{@id}")
    @contents = parse_content_data(@page)
    @api_key = api_key_guest(@page)
  end

  def get_type_service
    type_service = @page.search(".//a[@class='link-reset']")
    EasySettings.crawler.room.type_service.level.times do |variable|
      type_service = type_service.children
    end
    type_service.text
  end

  def get_price_service
    api_price_service
  end

  def get_name_service
    begin
      key = @contents['bootstrapData']['reduxData'].keys.first
      name_service = @contents['bootstrapData']['reduxData'][key]['listingInfo']['listing']['p3_summary_title']
    rescue Exception => e
      name_service = ""
    end
  end

  def get_img_service
    begin
      key = @contents['bootstrapData']['reduxData'].keys.first
      image_services = @contents['bootstrapData']['reduxData'][key]['listingInfo']['listing']['photos']
    rescue Exception => e
      image_services = []
    end
  end

  private
    def api_price_service
      params = {
        force_boost_unc_priority_message_type: '', show_smart_promotion: 0, key: @api_key,
        guests: 1, listing_id: @id, _format: 'for_web_dateless', _interaction_type: 'pageload', _intents: 'p3_book_it',
        number_of_adults: 1, number_of_children: 0, number_of_infants: 0, currency: 'JPY', locale: 'en'
      }

      result = get_data_api(AIRBNB_COST_URL, params)
      begin
        @price_service = result['pdp_listing_booking_details'].first['p3_display_rate']['amount_formatted']
      rescue Exception => e
        @price_service = ""
      end
    end
end
