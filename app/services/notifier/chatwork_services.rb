module Notifier
  class ChatworkServices
    def initialize event
      @event = event
    end

    def perform
      send_messages
      create_tasks
    end

    private
    def send_messages
      time_at = @event.start_date.strftime Settings.event.format_datetime
      @event.attendees.each do |attendee|
        next if attendee.chatwork_id.blank?

        ChatWork::Message.create(room_id: "51184775",
          body: "[To:#{attendee.chatwork_id}] #{attendee.user_name}
          #{I18n.t('events.message.chatwork_create',
            event: @event.title, time: time_at)}")
      end
    end

    def create_tasks
      if @event.chatwork_room_id && @event.attendees
        unix_time_limit = Time.parse(@event.start_date.to_s).to_i
        ChatWork::Task.create(
          room_id: @event.chatwork_room_id,
          body: @event.task_content,
          to_ids: chatwork_ids,
          limit: unix_time_limit
        )
      end
    end

    def chatwork_ids
      @event.attendees.map(&:chatwork_id).join(", ")
    end
  end
end
