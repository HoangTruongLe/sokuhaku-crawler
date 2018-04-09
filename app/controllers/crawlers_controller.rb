class CrawlersController < ApplicationController
  def homes
    airbnb_crawler = AirbnbHomesCrawler.new
    result = airbnb_crawler.get_homes(home_params)
    render json: result
  end

  def rooms
    room_crawler = RoomsCrawler.new
    rooms = []
    rooms_params.each do |room_param|
      room_crawler.get_service(room_param[:id])
      room = parse_data(room_param[:id], 
                        room_crawler.get_name_service,
                        room_crawler.get_type_service,
                        room_crawler.get_img_service,
                        room_crawler.get_price_service)
      rooms << room
    end
    render json: rooms
  end

  private

  def home_params
    params.permit(:adults, :children, :infants, :price_min,
                  :price_max, :min_beds,:min_bedrooms,
                  :search_by_map, :ne_lat, :ne_lng, :sw_lat, :sw_lng, :zoom, 
                  :min_bathrooms, :query, :show_details,
                  :section_offset, :checkin, :currency, :locale, :key, :room_types => []
                 )
  end

  def rooms_params
    params.require(:room_ids).map { |m| m.permit(:id) }
  end

  def parse_data(service_id, name, type, img, price)
    {
      id_service: service_id,
      name_service: name,
      type_service: type,
      img_service: img,
      price_service: price
    }
  end
end
