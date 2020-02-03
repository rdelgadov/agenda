class PersonDatesController < ApplicationController
  def create
    @date = PersonDate.take(permit_params)
    redirect_to action: :index
  end

  def index
    @person_dates = PersonDate.all
    @medics = Medic.all
    @type = 'agendaWeek'
    render 'layouts/calendar'
  end

  def show
    @date = PersonDate.find(params[:id])
  end

  def new
    @medics = Medic.all.map(&:name)
  end

  def create_medics_dates
    params.permit(:date)
    Medic.where(type: nil).all.each do |medic|
      medic.create_dates params[:date].to_date
    end
  end

  def create_kinesiologist_dates
    params.permit(:date)
    Kinesiologist.all.each do |kine|
      kine.create_dates params[:date].to_date
    end
  end

  def available_dates
    params.permit(:medic_id, :date)
    @dates = Medic.find(params[:medic_id]).available_dates params[:date].to_date
    respond_to do |format|
      format.json { render json: @dates }
    end
  end

  private
  def permit_params
    params.require(:person_date).permit(:date, :time, :medic_id, :person_id)
  end
end
