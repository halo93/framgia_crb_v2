class NotificationEmailJob < Struct.new(:event_id, :attendee_ids, :current_user_id)
  def perform
    attendees = Attendee.joins(:user).where id: attendee_ids

    attendees.each do |attendee|
      UserMailer.send_email_notify_delay(event_id, attendee.user_id,
        current_user_id).deliver
    end
  end
end
