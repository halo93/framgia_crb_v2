class Api::ParticularEventsController < Api::BaseController
  respond_to :json

  def index
    calendar = Calendar.find_by id: params[:calendar_id]
    events = calendar.events
    if calendar.no_public? && (!user_signed_in? || current_user.id != calendar.user_id)
      render text: t("events.popup.fail")
    else
      render json: events
    end
  end

  def show
    @event = Event.find_by id: params[:id]
    locals = {
      start_date: params[:start],
      finish_date: params[:end]
    }.to_json

    respond_to do |format|
      format.html do
        render partial: "events/popup",
          locals: {
            user: current_user,
            title: @event.title,
            event: @event,
            name_place: @event.name_place,
            place_id: @event.place_id,
            start_date: params[:start],
            finish_date: params[:end],
            fdata: Base64.urlsafe_encode64(locals)
          }
      end
    end
  end
end
