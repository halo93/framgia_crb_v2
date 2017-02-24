module Events
  class DeleteService
    def initialize event, params
      @event = event
      @params = params
    end

    def perform
      if delete_all?
        event = @event
        if @event.exception_type.present? && !@event.parent?
          event = @event.event_parent
        end
        event.destroy
      else
        perform_repeat_event
      end
    end

    private
    def perform_repeat_event
      exception_type = @params[:exception_type]
      exception_time = @params[:exception_time]
      start_date_before_delete = @params[:start_date_before_delete]
      finish_date_before_delete = @params[:finish_date_before_delete]

      if unpersisted_event?
        parent = @event.parent_id.present? ? @event.event_parent : @event
        dup_event = parent.dup
        dup_event.exception_type = exception_type
        dup_event.exception_time = exception_time
        dup_event.parent_id = parent.id
        parent.attendees.each do |attendee|
          dup_event.attendees.new(user_id: attendee.user_id,
            event_id: dup_event.id)
        end

        if @event.all_day?
          dup_event.start_date = exception_time.to_datetime.beginning_of_day
          dup_event.finish_date = exception_time.to_datetime.end_of_day
        else
          dup_event.start_date = start_date_before_delete
          dup_event.finish_date = finish_date_before_delete
        end

        if delete_all_follow?
          event_exception_pre_nearest(parent, exception_time)
            .update(end_repeat: (exception_time.to_date - 1.day))
        end
        dup_event.save
      elsif delete_only? && (@event.edit_all_follow? || @event.parent?)
        @event.old_exception_type = Event.exception_types[:edit_all_follow]
      end
      @event.exception_type = exception_type
      @event.exception_time = exception_time
      @event.save
    end

    def unpersisted_event?
      @params[:persisted].to_i == 0
    end

    def event_exception_pre_nearest parent, exception_time
      events = parent.event_exceptions
               .follow_pre_nearest(exception_time).order(start_date: :desc)
      events.size > 0 ? events.first : parent
    end

    %w(delete_all delete_all_follow delete_only).each do |action_name|
      define_method "#{action_name}?" do
        action_name == @params[:exception_type]
      end
    end
  end
end
