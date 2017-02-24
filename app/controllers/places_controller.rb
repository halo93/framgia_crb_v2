class PlacesController < ApplicationController
  before_action :set_place, only: [:show, :edit, :update, :destroy]

  def index
    @places = current_user.places
  end

  def show
  end

  def new
    @place = Place.new
  end

  def edit
  end

  def create
    @place = Place.new place_params
    @place.user = current_user

    if @place.save
      redirect_to places_url, success: "Place was successfully created."
    else
      render :new
    end
  end

  def update
    if @place.update(place_params)
      redirect_to places_url, success: "Place was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @place.destroy
    redirect_to places_url, success: "Place was successfully destroyed."
  end

  private
  def set_place
    @place = Place.find params[:id]
  end

  def place_params
    params.require(:place).permit Place::ATTR_PARAMS
  end
end
