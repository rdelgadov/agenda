class PersonDatesController < ApplicationController
  def create
    @date = PersonDate.take(permit_params)
    redirect_to action: :index
  end

  def index
    @medics = Medic.all
    respond_to do |format|
      format.json {
        if params[:medic_id].blank?
          render json: PersonDate.where(date: params[:from].to_date..params[:to].to_date).map { |person_date|
            {title: person_date.person_id != 1 ? person_date.person.bp.to_s + ' con ' + person_date.medic.name : 'Disponible con ' + person_date.medic.name,
             start: person_date.start_time,
             color: person_date.color,
             resourceId: person_date.medic.id,
             taked: person_date.taked?
            }
          }
        else
          render json: PersonDate.where(date: params[:from].to_date..params[:to].to_date, medic_id: params[:medic_id].to_i).map { |person_date|
            {title: person_date.person_id != 1 ? person_date.person.bp.to_s + ' con ' + person_date.medic.name : 'Disponible con ' + person_date.medic.name,
             start: person_date.start_time,
             color: person_date.color,
             resourceId: person_date.medic.id,
             taked: person_date.taked?
            }
          }
        end
      }

      format.html { @type = 'settimana'
      render 'layouts/calendar' }
    end
  end

  def show
    @date = PersonDate.find(params[:id])
  end

  def new
    @medics = Medic.all.map(&:name)
    @person_date = PersonDate.new
  end

  def create_medics_dates
    params.permit(:date)
    Medic.where(type: nil).all.each do |medic|
      medic.create_dates params[:date].to_date
    end
    redirect_to action: :index
  end

  def untake
    pd = PersonDate.find(params[:id])
    person = Person.find(pd.person_id)
    pd.untake
    redirect_to person_calendar_edit_path(person)
  end

  def create_kinesiologist_dates
    params.permit(:date)
    Kinesiologist.all.each do |kine|
      kine.create_dates params[:date].to_date
    end
    redirect_to action: :index
  end

  def available_dates
    params.permit(:medic_id, :date)
    @dates = Medic.find(params[:medic_id]).available_dates params[:date].to_date
    respond_to do |format|
      format.json { render json: @dates }
    end
  end

  def next_date_for_patients
    date = params[:date].blank? ? date.Today : params[:date].to_date
    @dates = Medic.find(params[:id]).next_dates_for_my_patients date
    render 'person_dates/index',layout: false
  end

  private

  def permit_params
    params.require(:person_date).permit(:date, :time, :medic_id, :person_id)
  end
end
