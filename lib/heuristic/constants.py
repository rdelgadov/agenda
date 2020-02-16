PRIMARY_ATTENTION = "Primaria"
SECONDARY_ATTENTION = "Kinesiologia"

ATTENTION_RANK = {PRIMARY_ATTENTION: 1, SECONDARY_ATTENTION: 0} # orden agendamiento en caso de multiples atenciones 
ATTENTION_DURATION = {PRIMARY_ATTENTION: 15, SECONDARY_ATTENTION: 60} # duracion atencion (minutos)

# tiempos
NEXT_APPT_BUFFER = 120 # buffer de inicio de ventana de tiempo de pickup con respecto a primera cita disponible
LAST_APPT_BUFFER = 60 # buffer de termino de ventana de tiempo de pickup con respecto a ultima cita disponible
DROPOFF_BUFFER = 150 # ancho ventana de tiempo de dropoff a partir de la hora de liberacion del paciente

VISIT_DURATION = 5 # tiempo espera vehiculos en nodos
SETUP_DURATION = 30 # tiempo setup vehiculos en depot
MAX_WAIT_DROPOFF = 90 # maxima espera por traslado de ir a dejar
ARRIVAL_DELAY = 5 # tiempo traslado estacionamiento a sala de espera
DEPARTURE_DELAY = 5 # tiempo traslado sala de espera a estacionamiento

ATTENTION_WINDOW_DEVIATION = 30 # desviacion ventana con respecto a hora de atencion
TRANSPORTATION_WINDOW_DEVIATION = 60 # desviacion ventana con respecto a hora de recogida

# todas las horas se miden como minutos enteros desde las 00:00 
START_TIME = 0 # hora de inicio del dia
END_TIME = 60*24-1 # hora de termino del dia

OPENING_TIME = 60*8 # hora de inicio de la jornada (utilizada en el calculo de desviacion de pacientes sin reposo)
CLOSING_TIME = 60*18 # hora de termino de la jornada (utilizada en el calculo de desviacion de pacientes sin reposo)

TAXI_ID = "Taxi"
TAXI_CAPACITY = 3

PICKUP = "pickup"
DROPOFF = "dropoff"