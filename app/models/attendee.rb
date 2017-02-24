class Attendee < ActiveRecord::Base
  ATTRIBUTES_PARAMS = [:user_id, :event_id]

  belongs_to :user
  belongs_to :event

  delegate :name, :email, to: :user, prefix: :user, allow_nil: :true
  delegate :id, to: :user, prefix: :attendee
  delegate :chatwork_id, to: :user, allow_nil: :true

  def attendee_email
    user.present? ? user_email : email
  end
end
