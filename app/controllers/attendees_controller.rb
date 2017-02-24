class AttendeesController < ApplicationController
  load_and_authorize_resource

  def create
    @attendee = Attendee.new attendee_params
    respond_to do |format|
      if @attendee.save!
        format.js{flash[:success] = t "events.attendee.success"}
      else
        format.js
      end
    end
  end

  def destroy
    respond_to do |format|
      if @attendee.destroy
        format.js do
          flash[:sucess] = t "events.flashs.delete_attendee"
          render action: :destroy
        end
      else
        format.js
      end
    end
  end

  private
  def attendee_params
    params.require(:attendee).permit Attendee::ATTRIBUTES_PARAMS
  end
end
