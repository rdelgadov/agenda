class PersonsController < ApplicationController
  def create
    @person = Person.new(person_params)
    @person.save!
    @person.take_buckets person_params

    redirect_to person_new_date_path(@person)
  end

  def index
    @persons = Person.all[1..-1]
  end

  def edit
    @person = Person.find(params[:id])
  end

  def new
    @person = Person.new(kine: Kinesiologist.first.id, medic: Medic.first.id)

  end

  def new_date
    @person = Person.find(params[:id])
    render 'person_dates/new'
  end

  def calendar_edit
    @dates = PersonDate.where('date>=?',Date.today).where(person_id: params[:id])
    @person = Person.find(params[:id])
    render 'person_dates/person_list'
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
      @person = Person.find_by_bp(search_params[:bp])
      redirect_to @person
    else
      flash[:error] = 'El usuario no existe.'
      redirect_to '/'
    end
  end

  def update
    @person = Person.find(params[:id])
    if @person.update_attributes(person_params)
      @person.take_buckets person_params
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

  def destroy
    @person = Person.find(params[:id])
    PersonDate.where(person_id: params[:id]).each(&:untake)
    @person.destroy

    redirect_to persons_path
  end

  private
  def person_params
    print(params)
    params.require(:person).permit(:name, :phone, :rut, :bp, :first_name, :second_name, :rest, :town, :address, :address_number, :number_of_days, :transportation, :latitude, :longitude, :vehicle_type, :accompanied, :travels_type, :kine, :medic, dates: [], ap_dates: [])
  end
  private
  def search_params
    params.require(:person).permit(:bp)
  end
end
