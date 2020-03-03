from constants import *
import basicfunc as bf
from patient import Batch
from vehicle import Vehicle, route_vehicles
from doctor import schedule_attention_orders

class Event:
    def __init__(self, time, center, rank=0, description=None):
        self.time = time
        self.center = center
        self.rank = rank
        self.description = description
        center.add_event(self)
        
    def __lt__(self, other):
        return (self.time, self.rank) < (other.time, other.rank)
    
    def __repr__(self):
        return f"({bf.int2strtime(self.time)}, {self.description})"

class ReleaseVehicle(Event):
    """
    Se libera vehiculo para realizar siguiente recorrido.
    """
    def __init__(self, time, center, vehicle):
        super().__init__(time, center, rank=-1, description="ReleaseVehicle")
        self.vehicle = vehicle

    def execute(self):
        RouteVehicles(self.time, self.center)
        self.center.vprint(f"---> {self.vehicle} disponible.\n")

class EnqueuePatientDep(Event):
    """
    Paciente listo para ser transportado.
    """
    def __init__(self, time, center, patient):
        super().__init__(time, center, rank=0, description="EnqueuePatientDep")
        self.patient = patient
        
    def execute(self):
        self.center.at_center.remove(self.patient)
        self.center.dropoff_wait.append(self.patient)

        PrioritizePatientDep(self.time + MAX_WAIT_DROPOFF, self.center, self.patient)
        RouteVehicles(self.time, self.center)
        self.center.vprint(f"---> {self.patient} listo para ser transportado de regreso.\n")

class PrioritizePatientDep(Event):
    """
    Se prioriza la orden de traslado de regreso del paciente.
    """
    def __init__(self, time, center, patient):
        super().__init__(time, center, rank=0, description="PrioritizePatientDep")
        self.patient = patient
        
    def execute(self):
        RouteVehicles(self.time, self.center)

        if self.patient in self.center.dropoff_wait:
            
            self.patient.dropoff_order.priority_level = 1
            CallTaxi(self.time, self.center, self.patient)
            self.center.vprint(f"---> Se prioriza el traslado de regreso de {self.patient}.\n")
        
        else:
            self.center.vprint(f"---> {self.patient} ya tuvo transporte de regreso.\n")

class CallTaxi(Event):
    """
    Se llama un taxi de emergencia si paciente sigue en el sistema luego del tiempo de espera máximo.
    """
    def __init__(self, time, center, patient):
        super().__init__(time, center, rank=3, description="CallTaxi")
        self.patient = patient
        
    def execute(self):
        if self.patient in self.center.dropoff_wait:

            id_taxi = f"{TAXI_ID}_{len(self.center.taxis)}"

            # vehiculo con largo tiempo de refill, para evitar que haga mas de un viaje
            taxi = Vehicle(id_taxi, TAXI_CAPACITY, START_TIME, END_TIME, refill=END_TIME-START_TIME)
             
            # se agrega taxi a la flota de vehiculos
            self.center.vehicles[id_taxi] = taxi

            # se guarda en el historial de taxis llamados
            self.center.taxis[id_taxi] = taxi

            # COMO GARANTIZAR QUE ESTE RUTEO SE LLEVE AL PACIENTE !?
            RouteVehicles(self.time, self.center)
            DisableTaxi(self.time, self.center, taxi)
            self.center.vprint(f"---> Se llama {taxi} para enviar a {self.patient} de regreso.\n")
        else:
            self.center.vprint(f"---> {self.patient} ya tuvo transporte de regreso.\n")

class DisableTaxi(Event):
    """
    Se deshabilita el taxi de emergencia indicado, lo quita de la flota de vehiculos.
    """
    def __init__(self, time, center, vehicle):
        super().__init__(time, center, rank=2, description="DisableTaxi")
        self.vehicle = vehicle
        
    def execute(self):
        self.center.vehicles.pop(self.vehicle.id)
        self.center.vprint(f"---> Se deshabilita {self.vehicle} para realizar mas viajes.\n")

class RouteVehicles(Event):
    """
    Ruteo de vehiculos para llevar/traer pacientes del centro.
    """
    def __init__(self, time, center):
        super().__init__(time, center, rank=1, description="RouteVehicles")
        
    def execute(self):

        while True:

            # hora del proximo evento de actualizacion del sistema (identificados por rank=0)
            future_updates = [e.time for e in self.center.future_events if e.rank == 0]

            if len(future_updates) == 0:
                next_update = END_TIME
                self.center.vprint("---> No existe ningun evento futuro de actualizacion del sistema.")
            else:
                next_update = min(future_updates)
                self.center.vprint(f"---> Proximo evento de actualizacion del sistema es a las {bf.int2strtime(next_update)}.")

            # si no hay vehiculos disponibles antes del proximo evento, no se rutea
            available_vehicles = [v for v in self.center.vehicles.values() if max(v.release_time, self.time) < min(v.shift_end, next_update)]

            if len(available_vehicles) == 0:
                self.center.vprint("---> No hay vehiculos disponibles antes del proximo evento.\n")
                return

            self.center.vprint(f"---> Vehiculos disponibles antes del proximo evento: {available_vehicles}")

            transportation_orders = {}

            for pat in self.center.pickup_wait:

                # orden de transporte del paciente
                tpt_order = pat.pickup_order
                        
                # primera orden de atencion del paciente
                att_order = pat.attention_orders[0]

                # primera y ultima cita disponibles para la orden de atencion, a contar de la hora actual
                next_appt = att_order.next_appointment(self.center.doctors, self.time)
                last_appt = att_order.last_appointment(self.center.doctors, self.time)

                # si no hay citas disponibles, no se considera la orden de transporte en el ruteo
                if next_appt is None:
                    self.center.pickup_wait.remove(pat)
                    self.center.pickup_pending.append(pat)
                    continue

                # se sugiere ventana de tiempo de la orden de pickup, segun disponibilidad de citas
                suggested_window_start = max(START_TIME, next_appt.start_time - NEXT_APPT_BUFFER)
                suggested_window_end = max(START_TIME, last_appt.start_time - LAST_APPT_BUFFER)

                # si ventana de tiempo original caduca, se redefine a partir de la hora actual; de lo contrario se conserva
                if self.time > tpt_order._window_end:
                    current_window_start = self.time
                    current_window_end = self.time + TRANSPORTATION_WINDOW_DEVIATION
                else:
                    current_window_start = tpt_order._window_start
                    current_window_end = tpt_order._window_end

                # ventana para ruteo es la interseccion entre la original (o redefinida) y la sugerida
                window_start = max(current_window_start, suggested_window_start)
                window_end = min(current_window_end, suggested_window_end)

                # si interseccion es vacia, se usa la ventana sugerida
                if window_start > window_end:
                    tpt_order.window_start = suggested_window_start
                    tpt_order.window_end = suggested_window_end
                else:
                    tpt_order.window_start = window_start
                    tpt_order.window_end = window_end

                # se guarda la orden de transporte para considerarla en el ruteo
                transportation_orders[pat.id] = tpt_order

            for pat in self.center.dropoff_wait:

                # hora del proximo taxi (entre los pacientes del batch que estan esperando traslado de regreso)
                first_release = min([p.release_time for p in pat.batch.patients if p in self.center.dropoff_wait])
                next_taxi = first_release + DEPARTURE_DELAY + MAX_WAIT_DROPOFF

                # hora de la proxima liberacion (entre los pacientes del batch que aun siguen en el centro)
                next_release = min([p.release_time + DEPARTURE_DELAY for p in pat.batch.patients if p in self.center.at_center], default=None)

                # si la liberacion mas proxima ocurre antes del siguiente evento de taxi del batch, y hay
                # mas de un vehiculo potencialmente disponible previo a esa hora, con al menos uno de ellos
                # potencialmente disponible posterior a la primera liberacion, entonces se posterga el traslado 
                if next_release is not None and next_release <= next_taxi:
                    # el "+1" simboliza un epsilon de tiempo
                    potential_vehicles = [v for v in self.center.vehicles.values() if max(v.release_time, self.time) < min(v.shift_end, next_taxi + 1)]
                    
                    if len(potential_vehicles) > 1 and any(v.shift_end > next_release for v in potential_vehicles):
                        continue

                # orden de transporte del paciente
                tpt_order = pat.dropoff_order

                # se calcula ventana basado en tiempo de espera maximo para que paciente llegue a su domicilio 
                tpt_order.window_start = pat.release_time
                tpt_order.window_end = pat.release_time + DROPOFF_BUFFER

                # se guarda la orden de transporte para considerarla en el ruteo
                transportation_orders[pat.id] = tpt_order

            # si no hay ordenes que satisfacer, no se rutea
            if len(transportation_orders) == 0:
                self.center.vprint("---> No hay ordenes de transporte pendientes.\n")
                return

            n_orders = len(transportation_orders)
            n_pickup = len([tpt_order for tpt_order in transportation_orders.values() if tpt_order.type == PICKUP])
            n_dropoff = len([tpt_order for tpt_order in transportation_orders.values() if tpt_order.type == DROPOFF])

            self.center.vprint(f"---> Hay {n_orders} ordenes de transporte (pickup: {n_pickup}, dropoff: {n_dropoff}).")

            # se rutea considerando todos los vehiculos, incluso los no disponibles, pues su
            # disponibilidad se controla con los parametros "shift_start" y "shift_end" en el ruteador
            first_routes = route_vehicles(self.center.vehicles, transportation_orders,
                self.center.lat, self.center.lon, self.center.id, self.time)

            if len(first_routes) == 0:
                self.center.vprint("---> No hay rutas para planificar.\n")
                return

            # rutas previas a la proxima actualizacion
            imminent_routes = [r for r in first_routes if r.start_time < next_update]

            # ruta que primero llega al centro
            next_route = min(imminent_routes, key=lambda r: r.end_time, default=None)
            
            # se borran todas las rutas, excepto la que llega primero al centro
            for route in first_routes:
                if route != next_route:
                    route.delete()

            if next_route is None:
                self.center.vprint("---> No hay ninguna ruta inminente.\n")
                return

            route_start_time = bf.int2strtime(next_route.start_time)
            route_end_time = bf.int2strtime(next_route.end_time)
            self.center.vprint(f"---> Siguiente ruta es de {next_route.vehicle} entre {route_start_time}-{route_end_time}.")
        
            # se agenda batch de pacientes que llegan al centro
            batch = Batch([trip.transportation_order._patient for trip in next_route.trips if trip.type == PICKUP])
            batch.schedule_patients(self.center.doctors, next_route.end_time + ARRIVAL_DELAY)

            # si algun paciente del batch no logra atenderse (pues no
            # quedan citas disponibles, o no llega a alguna planificada):
            # se cancelan las atenciones del batch y se recalculan rutas,
            # excluyendo a los pacientes que no lograron atenderse
            if any([(pat.attention_time is None) or (pat.attention_time < next_route.end_time + ARRIVAL_DELAY)
                for pat in batch.patients]):

                self.center.vprint("---> Algunos pacientes no logran atenderse. Se recalcula ruta...")

                for pat in batch.patients:
                    if pat.attention_time is None or pat.attention_time < next_route.end_time + ARRIVAL_DELAY:
                        self.center.pickup_wait.remove(pat)
                        self.center.pickup_pending.append(pat)

                batch.cancel_patients()
                batch.dissolve()
                next_route.delete()

                continue

            # si todos se logran atender, se actualiza el estado del sistema     
            for trip in next_route.trips:
                patient = trip.transportation_order._patient

                if trip.type == PICKUP:
                    self.center.pickup_wait.remove(patient)
                    self.center.at_center.append(patient)

                    EnqueuePatientDep(patient.release_time + DEPARTURE_DELAY, self.center, patient)

                elif trip.type == DROPOFF:
                    self.center.dropoff_wait.remove(patient)
                    self.center.completed.append(patient)

            self.center.vprint(f"---> Se ejecuta la ruta de {next_route.vehicle}.\n")
            #ReleaseVehicle(next_route.vehicle.release_time, self.center, next_route.vehicle)

class SchedulePendingPatients(Event):
    """
    Se agendan los pacientes que estan pendientes (que no necesitan transporte o no pudieron ser transportados).
    """
    def __init__(self, time, center, restless_only=False):
        super().__init__(time, center, rank=-1, description="SchedulePendingPatients")
        self.restless_only = restless_only

    def execute(self):

        if self.restless_only:
            self.center.vprint("---> Agendando pacientes sin reposo...")
        else:
            self.center.vprint("---> Agendando pacientes pendientes...")

        # ordenes de atencion que no tienen cita agendada aun
        pending_attorders = []

        for patient in (self.center.pickup_wait + self.center.pickup_pending + self.center.schedule_wait):
            if self.restless_only and (patient.repose or patient.transport):
                continue
            
            for att_order in patient.attention_orders:

                if att_order.appointment is None:
                    pending_attorders.append(att_order)
                
                # si el paciente tiene una orden de atencion con cita ya fija
                elif patient in self.center.schedule_wait:
                    self.center.schedule_wait.remove(patient)
                    self.center.completed.append(patient)

        schedule_attention_orders(self.center.doctors, pending_attorders)

        n_attorders = len(pending_attorders)
        n_scheduled = 0

        for att_order in pending_attorders:

            if att_order.appointment is not None:
                n_scheduled += 1
                patient = att_order._patient

                if patient in self.center.schedule_wait:
                    self.center.schedule_wait.remove(patient)
                    self.center.completed.append(patient)

        self.center.vprint(f"---> Se agendan {n_scheduled} de {n_attorders} ordenes de atencion.\n")

class RoutePendingPickups(Event):
    """
    Ruteo de recogidas pendientes.
    """
    def __init__(self, time, center):
        super().__init__(time, center, rank=1, description="RoutePendingPickups")
        
    def execute(self):

        self.center.vprint("---> Ruteando ordenes de pickup pendientes...")

        taxis_tocall = {}
        pending_orders = {}

        for i, pat in enumerate(self.center.pickup_pending + self.center.pickup_wait):

            if pat.attention_time is None:
                self.center.vprint(f"---> {pat} no se rutea, pues no posee hora de atencion.")
                continue

            # se redefine la compania del paciente a 0 para no tener que definir
            # taxis de capacidad mayor, lo que haria posible que un taxi se lleve
            # a mas de un paciente con menor compania
            pat.pickup_order.companion = 0
            
            pending_orders[pat.id] = pat.pickup_order

            id_taxi = f"{TAXI_ID}_PU_{i}"
            capacity_taxi = 1
            taxi = Vehicle(id_taxi, capacity_taxi, START_TIME, END_TIME, refill=END_TIME-START_TIME)
            taxis_tocall[id_taxi] = taxi
            self.center.taxis[id_taxi] = taxi

        if len(pending_orders) == 0:
            self.center.vprint("---> No hay ordenes pendientes.\n")
            return

        first_routes = route_vehicles(taxis_tocall, pending_orders, self.center.lat, self.center.lon, self.center.id, START_TIME)

        for route in first_routes:
            trip = route.trips[0]
            pat = trip.transportation_order._patient
            delay = pat.attention_time - (trip.end_time + ARRIVAL_DELAY)
            route.shift_route(delay)

            if pat in self.center.pickup_pending:
                self.center.pickup_pending.remove(pat)
            elif pat in self.center.pickup_wait:
                self.center.pickup_wait.remove(pat)

            self.center.dropoff_pending.append(pat)

        self.center.vprint(f"---> Se rutean {len(first_routes)} de {len(pending_orders)} ordenes pendientes.\n")

class RoutePendingDropoffs(Event):
    """
    Ruteo de dejadas pendientes.
    """
    def __init__(self, time, center):
        super().__init__(time, center, rank=2, description="RoutePendingDropoffs")
        
    def execute(self):

        self.center.vprint("---> Ruteando ordenes de dropoff pendientes...")

        taxis_tocall = {}
        pending_orders = {}

        for i, pat in enumerate(self.center.dropoff_pending + self.center.dropoff_wait):

            if pat.release_time is None:
                self.center.vprint(f"---> {pat} no se rutea, pues no posee hora de liberacion.")
                continue

            # se redefine la compania del paciente a 0 para no tener que definir
            # taxis de capacidad mayor, lo que haria posible que un taxi se lleve
            # a mas de un paciente con menor compania
            pat.dropoff_order.companion = 0

            pending_orders[pat.id] = pat.dropoff_order

            id_taxi = f"{TAXI_ID}_DO_{i}"
            capacity_taxi = 1
            taxi = Vehicle(id_taxi, capacity_taxi, START_TIME, END_TIME, refill=END_TIME-START_TIME)
            taxis_tocall[id_taxi] = taxi
            self.center.taxis[id_taxi] = taxi

        if len(pending_orders) == 0:
            self.center.vprint("---> No hay ordenes pendientes.\n")
            return

        first_routes = route_vehicles(taxis_tocall, pending_orders, self.center.lat, self.center.lon, self.center.id, START_TIME)

        for route in first_routes:
            trip = route.trips[0]
            pat = trip.transportation_order._patient
            delay = pat.release_time + DEPARTURE_DELAY - trip.start_time 
            route.shift_route(delay)

            if pat in self.center.dropoff_pending:
                self.center.dropoff_pending.remove(pat)
            elif pat in self.center.dropoff_wait:
                self.center.dropoff_wait.remove(pat)

            self.center.completed.append(pat)

        self.center.vprint(f"---> Se rutean {len(first_routes)} de {len(pending_orders)} ordenes pendientes.\n")



class ScheduleFixedPatients(Event):
    """
    Agendamiento de citas fija.
    """
    def __init__(self, time, center):
        super().__init__(time, center, rank=-2, description="ScheduleFixedPatients")
        
    def execute(self):

        self.center.vprint("---> Agendando citas con hora fija...")

        count = 0
        for patient in self.center.patients.values():
            for att_order in patient.attention_orders:
                if att_order.required_time is not None:
                    next_appt = att_order.next_appointment(self.center.doctors, START_TIME)

                    if next_appt is None:
                        doctor_id = att_order.required_doctor_id
                        req_time = bf.int2strtime(att_order.required_time)
                        raise Exception(f"No es posible agendar cita requerida con '{doctor_id}' a las {req_time}.")

                    att_order.set_appointment(next_appt, fixed=True)
                    count += 1

        self.center.vprint(f"---> Se agendan todas las citas ({count}).\n")