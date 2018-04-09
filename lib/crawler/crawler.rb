require 'mechanize'

class Crawler
  AIRBNB_URL = 'https://www.airbnb.com/'
  AIRBNB_API = Crawler::AIRBNB_URL + 'api/v2/'

  AIRBNB_ROOM_URL = Crawler::AIRBNB_URL + 'rooms/'
  AIRBNB_COST_URL = Crawler::AIRBNB_API + 'pdp_listing_booking_details'

  def initialize
    @agent = Mechanize.new
  end

  protected
    
    def api_key_guest(page)
      meta = page.search(".//meta[@id='_bootstrap-layout-init']")
      json = JSON.parse(meta&.first&.attributes['content']&.value)
      json['api_config']['key']
    end

    def parse_content_data(page)
      contents = page.search('.//script[@data-hypernova-key="spaspabundlejs"]')
      contents = contents.first.children.first.content.gsub('<!--', '').gsub('-->', '')
      JSON.parse(contents)
    end

    def get_data_api(api_url, params)
      uri = URI(api_url)
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
      JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
    end
end
