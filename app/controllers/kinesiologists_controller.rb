class KinesiologistsController < ApplicationController
  def calendar
    @medic_id = params[:id]
    @type = 'agendaDay'

    render 'layouts/calendar'
  end

  def create
    @kine = Kinesiologist.new(permit_params)
    @kine.save!
    redirect_to @kine
  end

  def edit
    @kine = Kinesiologist.find(params[:id])
  end

  def index
    @kinesiologists = Kinesiologist.all
  end

  def new
    @kine = Kinesiologist.new
  end

  def show
    @kine = Kinesiologist.find(params[:id])
  end

  def update
    @kine = Kinesiologist.find(params[:id])
    if @kine.update(permit_params)
      redirect_to @kine
    else
      render 'edit'
    end
  end

  private
  def permit_params
    params.require(:kinesiologist).permit(:name, :rut, :phone, :color, attention: {})
  end
end
