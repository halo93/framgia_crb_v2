class Place < ActiveRecord::Base
  belongs_to :user

  validates :name, presence: true

  scope :search_name, ->(name, user_id) do
    where "name LIKE '%#{name}%' AND user_id = #{user_id} OR user_id is null"
  end
  scope :search_address, ->(address){where "address LIKE '%#{address}%'"}
  scope :order_by_name, ->{order name: :asc}
  scope :order_by_address, ->{order address: :asc}

  ATTR_PARAMS = [:name, :address]

  class << self
    def existed_place? place
      Place.pluck(:name).include? place
    end
  end
end
