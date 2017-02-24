module Events
  class CreateService
    attr_accessor :is_overlap, :event

    def initialize user, params
      @user = user
      @params = params
    end

    def perform
      modify_repeat_params if @params[:repeat].blank?
      @event = @user.events.build event_params
      return false if is_overlap? && not_allow_overlap?

      NotificationWorker.perform_async @event.id if status = @event.save
      status
    end

    private
    def event_params
      @params.require(:event).permit Event::ATTRIBUTES_PARAMS
    end

    def modify_repeat_params
      Event::REPEAT_PARAMS.each{|attribute| @params[:event].delete attribute}
    end

    def is_overlap?
      overlap_handler = OverlapHandler.new @event
      self.is_overlap = overlap_handler.overlap?
    end

    def not_allow_overlap?
      @params["allow_overlap"] != "true"
    end
  end
end
