class UserMailer < ApplicationMailer
  default from: "no_reply@framgia.com"

  def request_to_share_calendar user_id, current_user_id
    @user = User.find_by id: user_id
    @current_user = User.find_by id: current_user_id
    mail to: @user.email, subject: t("calendars.flashs.request_to_share_calendar")
  end

  def send_email_notify_event event_id, user_id, current_user_id
    @event = Event.find_by id: event_id
    @user = User.find_by id: user_id
    @current_user = User.find_by id: current_user_id
    mail to: @user.email, subject: t("events.mailer.join_event")
  end

  def send_email_notify_delay event_id, user_id, current_user_id
    @event = Event.find_by id: event_id
    @user = User.find_by id: user_id
    @current_user = User.find_by id: current_user_id
    mail to: @user.email, subject: "[#{@event.title}]"
  end

  def send_email_after_event_update event_before_update_id, event_after_update_id,
    start_date_before, finish_date_before
    @event_before_update = Event.find_by id: event_before_update_id
    @event_after_update = Event.find_by id: event_after_update_id
    if @event_after_update.start_date != start_date_before ||
       @event_after_update.finish_date != finish_date_before
      send_email_after_event_update_to_attendees start_date_before, finish_date_before
    end
  end

  def send_email_after_delete_event user_id, event_title, event_start_date,
    event_finish_date, event_exception_type
    @user = User.find_by id: user_id
    @event_title = event_title
    @event_start_date = event_start_date
    @event_finish_date = event_finish_date
    @event_exception_type = event_exception_type
    mail to: @user.email, subject: t("calendars.mailer.delete_event.subject")
  end

  def send_email_invite_to_join_organization user_id, organization_id
    @user = User.find_by id: user_id
    @organization = Organization.find_by id: organization_id
    mail to: @user.email, subject: t(".invitation")
  end

  private
  def send_email_after_event_update_to_attendees start_date_before, finish_date_before
    @start_date_before = DateTime.parse start_date_before
    @finish_date_before = DateTime.parse finish_date_before
    if @event_before_update.parent_id.nil?
      parent = @event_before_update
    else
      parent = @event_before_update.event_parent
    end
    parent.attendees.each do |attendee|
      @user = attendee.user
      if @user.email_require
        mail to: @user.email, subject: t("calendars.mailer.event_update.subject")
      end
    end
  end
end
