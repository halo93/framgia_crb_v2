class ParticularCalendarsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :load_calendar

  def show
    @status = @calendar.status
    @user_calendar = UserCalendar.find_by user_id: current_user.id,
      calendar_id: @calendar.id if user_signed_in?
  end

  def update
    @user_calendar = UserCalendar.find_by user_id: current_user.id,
      calendar_id: params[:id]
    respond_to do |format|
      if @user_calendar.update_attributes user_calendar_params
        format.json{render json: @user_calendar}
      else
        format.json{render json: {}}
      end
      format.html{redirect_to root_path}
    end
  end

  private
  def load_calendar
    @calendar = Calendar.find_by id: params[:id]
  end

  def user_calendar_params
    params.require(:user_calendar).permit UserCalendar::ATTR_PARAMS
  end
end
