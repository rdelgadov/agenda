class PersonsController < ApplicationController
  def create
    @person = Person.new(person_params)
    @person.save!
    redirect_to person_new_date_path(@person)
  end

  def index
    @persons = Person.all[1..-1]
  end

  def edit
    @person = Person.find(params[:id])
  end

  def new
    @person = Person.new
  end

  def new_date
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
    if Person.exists? bp: search_params[:bp]
      @person = Person.where(search_params).first
      redirect_to @person
    else
      flash[:error] = 'El usuario no existe.'
      redirect_to '/'
    end
  end

  def update
    @person = Person.find(params[:id])
    if @person.update_attributes(person_params)
      @person.dates = person_params[:dates]
      @person.save!
      redirect_to @person
    else
      render 'edit'
    end
  end

  def show
    @person = Person.find(params[:id])
    #TODO: replace the last date for next date.
    @last_date = PersonDate.where(person_id: params[:id]).last
  end

  private
  def person_params
    print(params)
    params.require(:person).permit(:name, :phone, :rut, :bp, :first_name, :second_name, :rest, :town, :address, :address_number, :number_of_days, :transportation, :latitude, :longitude, :vehicle_type, :accompanied, :travels_type, dates: [].to_yaml )
  end
  private
  def search_params
    params.require(:person).permit(:bp)
  end
end
