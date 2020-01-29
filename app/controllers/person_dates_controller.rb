class PersonDatesController < ApplicationController
  def create
    @date = PersonDate.new(permit_params)
    @date.save!
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
  private
  def permit_params
    params.require(:person_date).permit(:date, :time, :medic_id, :person_id)
  end
end
