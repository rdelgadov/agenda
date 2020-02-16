from constants import *
import basicfunc as bf
import heapq as hq
from event import *

class Center:
    def __init__(self, ident, lat, lon, verbose=True):
        self.id = ident
        self.lat = lat
        self.lon = lon

        self.pickup_wait = [] # pacientes esperando ser recogidos
        self.dropoff_wait = [] # pacientes esperando ser llevados
        self.schedule_wait = [] # pacientes esperando ser agendados (sin transporte)
        self.at_center = [] # pacintes que estan en el centro
        self.pickup_pending = [] # pacientes que no alcanzan a ser recogidos a tiempo para su atencion
        self.dropoff_pending = [] # pacientes que no alcanzan a ser llevados a tiempo de regreso
        self.completed = [] # pacientes listos (llegaron al centro y volvieron a su domicilio)
        self.future_events = [] # eventos futuros (por ejecutar)

        self.clock = START_TIME

        if verbose:
            self.vprint = print
        else:
            self.vprint = lambda *args: None
        
    def __repr__(self):
        info_list = [
        f"Estado del centro {self.id}:",
        f"- Reloj: {bf.int2strtime(self.clock)}",
        f"- Espera pickup ({len(self.pickup_wait)}): {self.pickup_wait}",
        f"- Espera dropoff ({len(self.dropoff_wait)}): {self.dropoff_wait}",
        f"- Pacientes en el centro ({len(self.at_center)}): {self.at_center}",
        f"- Pendiente pickup ({len(self.pickup_pending)}): {self.pickup_pending}",
        f"- Pendiente dropoff ({len(self.dropoff_pending)}): {self.dropoff_pending}",
        f"- Espera agendamiento sin transporte ({len(self.schedule_wait)}): {self.schedule_wait}",
        f"- Pacientes completados: {len(self.completed)}"
        ]

        return "\n".join(info_list)
    
    def add_patients(self, patients_list):
        self.patients = {pat.id: pat for pat in patients_list} # diccionario de pacientes

        if len(self.patients) != len(patients_list):
            raise Exception("Hay pacientes duplicados!")
        
        for pat in self.patients.values():
            if pat.transport:
                self.pickup_wait.append(pat)

                # se guarda copia de la ventana de tiempo original de la orden de pickup
                # sera usada en calculos posteriores
                pat.pickup_order._window_start = pat.pickup_order.window_start
                pat.pickup_order._window_end = pat.pickup_order.window_end
   
            else:
                self.schedule_wait.append(pat)

        return self.patients

    def add_doctors(self, doctors_list):
        self.doctors = {doc.id: doc for doc in doctors_list}

        if len(self.doctors) != len(doctors_list):
            raise Exception("Hay doctores duplicados!")

        return self.doctors
        
    def add_vehicles(self, vehicles_list):
        self.vehicles = {veh.id: veh for veh in vehicles_list}

        if len(self.vehicles) != len(vehicles_list):
            raise Exception("Hay vehiculos duplicados!")

        self.taxis = {} # contenedor de taxis de emergencia que se llaman durante la ejecucion
            
        return self.vehicles

    def add_event(self, event):
        hq.heappush(self.future_events, event)

    def simulate_events(self):
        """Agenda pacientes que requieren transporte. Simula la operacion del sistema."""
        
        self.vprint(f"Simulando operacion del centro {self.id}...\n")

        # se agendan citas para las ordenes de atencion que requieren un horario definido
        for patient in self.patients.values():
            for att_order in patient.attention_orders:
                if att_order.required_time is not None:
                    next_appt = att_order.next_appointment(self.doctors, START_TIME)

                    if next_appt is None:
                        doctor_id = att_order.required_doctor_id
                        req_time = bf.int2strtime(att_order.required_time)
                        raise Exception(f"No es posible agendar cita requerida con '{doctor_id}' a las {req_time}.")

                    att_order.set_appointment(next_appt, fixed=True)

        # eventos iniciales
        RouteVehicles(START_TIME, self)
        for vehicle in self.vehicles.values():
            pass
            #ReleaseVehicle(vehicle.release_time, self, vehicle)
        
        last_event = None

        # simular mientras haya eventos futuros
        while self.future_events:
            next_event = hq.heappop(self.future_events) # evento inminente
            
            if isinstance(next_event, RouteVehicles):
                # eventos de ruteo duplicados se descartan
                if isinstance(last_event, RouteVehicles) and next_event.time == last_event.time:
                    continue
                # eventos de ruteo posteriores a la hora terminal se descartan
                elif next_event.time > END_TIME:
                    continue

            self.clock = next_event.time # avanza reloj de la simulacion
            self.vprint(next_event) # descripcion del evento
            next_event.execute() # ejecutar evento
            last_event = next_event

        # evento terminal
        SchedulePendingPatients(self.clock, self).execute()
        RoutePendingPickups(self.clock, self).execute()
        RoutePendingDropoffs(self.clock, self).execute()
            
        self.vprint("Fin de la simulacion!\n")