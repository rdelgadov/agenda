class PersonsController < ApplicationController
  def create
    @person = Person.new(person_params)
    @person.save!
    redirect_to person_new_date_path(@person)
  end

  def index
    @persons = Person.all[1..-1]
  end

  def new
  end

  def new_date
    print params
    render 'person_dates/new'
  end

  def calendar
    @person_dates = PersonDate.where(person_id: params[:id])
    if @person_dates.blank?
      @person_dates = Medic.all.flat_map{|medic| PersonDate.where(medic_id: medic.id)}
    end
    @medics = Medic.all
    @type = 'agendaWeek'
    render 'layouts/calendar'
  end

  def search
    print search_params
    if Person.exists? rut: search_params[:rut]
      @person = Person.where(search_params).first
      redirect_to @person
    else
      flash[:error] = 'El usuario no existe.'
      redirect_to '/'
    end
  end

  def show
    @person = Person.find(params[:id])
    @last_date = PersonDate.where(person_id: params[:id]).last
  end

  private
  def person_params
    print(params)
    params.require(:person).permit(:name, :phone, :rut, :bp, :first_name, :second_name, :rest, :town, :address, :address_number, :number_of_days, :transportation, :latitude, :longitude, :vehicle_type, :accompanied, :travels_type, :dates)
  end
  private
  def search_params
    params.require(:person).permit(:rut)
  end
end
