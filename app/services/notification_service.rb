class NotificationService
  def initialize event, event_fullcalendar = nil
    @event = event
    @event_fullcalendar = event_fullcalendar
    @delay_time = delay_time
    @notification_types = @event.notifications
                          .map{|notification| notification.notification_type.downcase.to_sym}
  end

  def perform
    perform_notification
  end

  private
  def perform_notification
    perform_chatwork_notification if @notification_types.include?(:chatwork)
    perform_email_notification if @notification_types.include?(:email)
    perform_desktop_notification if @notification_types.include?(:desktop)
  end

  def delay_time
    if @event_fullcalendar.present?
      @event_fullcalendar.start_date - Settings.thirty.minutes
    else
      @event.start_date - Settings.thirty.minutes
    end
  end

  def perform_chatwork_notification
    Notifier::ChatworkServices.new(@event).perform
    Delayed::Job.enqueue ChatworkJob.new(@event), 0, @delay_time
  end

  def perform_email_notification
    Delayed::Job.enqueue(NotificationEmailJob.new(@event.id,
      @event.attendee_ids, @event.user_id), 0, @delay_time)
  end

  def perform_desktop_notification
    NotificationDesktopJob.new(@event, Settings.start_event).perform
    Notifier::DesktopService.new(@event, Settings.create_event).perform
    Delayed::Job.enqueue NotificationDesktopJob.new(@event), 0, @delay_time
  end
end
