class MedicsController < ApplicationController
  def calendar
    @medic_id = params[:id]
    @type = 'agendaDay'

    render 'layouts/calendar'
  end
  def create
    @medic = Medic.new(permit_params)
    @medic.save
    redirect_to @medic
  end

  def edit
    @medic = Medic.find(params[:id])
  end

  def index
    @medics = Medic.where(type: nil)
  end

  def new
    @medic = Medic.new
  end

  def show
    @medic = Medic.find(params[:id])
  end

  def update
    @medic = Medic.find(params[:id])
    if @medic.update(permit_params)
      redirect_to @medic
    else
      render 'edit'
    end
  end

  def next_dates
    medic = Medic.find(params[:id])
    @dates = medic.patients_for_today
    render 'person_dates/index',layout: false
  end

  private
  def permit_params
    params.require(:medic).permit(:name, :rut, :phone, :color, attention: {})
  end
end
