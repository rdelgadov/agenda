from constants import *
import basicfunc as bf
import requests
import pandas as pd
import os
import json

class Vehicle:
    def __init__(self, ident, capacity, shift_start, shift_end, refill=SETUP_DURATION, veh_type=None):
        self.id = ident
        self.capacity = capacity
        self.shift_start = shift_start
        self.shift_end = shift_end
        self.refill = refill
        self.type = veh_type
        self.routes = []

    @property
    def release_time(self):
        if len(self.routes) > 0:
            return min(self.shift_end, max(r.end_time for r in self.routes) + self.refill)
        else:
            return self.shift_start

    def __repr__(self):
        return f"Vehicle({self.id})"

    @staticmethod
    def from_csv(filepath, fecha, sep=","):
        df = pd.read_csv(os.path.join(os.getcwd(),filepath), sep=sep)
        df = df[df.date == fecha]

        vehs=[]

        for index, row in df.iterrows():
            vehicle = Vehicle(str(row.ident), row.capacity, bf.strtime2int(row.shift_start), bf.strtime2int(row.shift_end))
            vehs.append(vehicle)
        
        return vehs

    def add_route(self, route):
        self.routes.append(route)

    def remove_route(self, route):
        """Solo remueve la ruta de la lista, pero no elimina las referencias existentes."""
        self.routes.remove(route)

    def get_stats(self):
        stats = {"id": self.id, "capacity": self.capacity}

        stats["n_routes"] = len(self.routes)
        stats["n_trips"] = sum(len(r.trips) for r in self.routes)
        stats["busy_time"] = sum(r.end_time - r.start_time for r in self.routes)
        stats["refill_time"] = self.refill * max(len(self.routes) - 1, 0)
        stats["total_time"] = self.shift_end - self.shift_start
        stats["idle_time"] = stats["total_time"] - stats["busy_time"] - stats["refill_time"]
        
        return stats

class Route:
    def __init__(self, vehicle, start_time, end_time):
        self.start_time = start_time
        self.end_time = end_time
        self.vehicle = vehicle
        self.trips = []
        vehicle.add_route(self)

    def add_trip(self, trip):
        self.trips.append(trip)

    def shift_route(self, delta_time):
        self.start_time += delta_time
        self.end_time += delta_time

        for trip in self.trips:
            trip.shift_trip(delta_time)

    def delete(self):
        for trip in self.trips:
            tpt_order = trip.transportation_order
            tpt_order.trip = None
        
        self.vehicle.remove_route(self)

class Trip:
    def __init__(self, trip_type, event_time, route, transportation_order):
        if trip_type == PICKUP:
            self.start_time = event_time
            self.end_time = route.end_time
        elif trip_type == DROPOFF:
            self.start_time = route.start_time
            self.end_time = event_time
        else:
            raise Exception(f'"{trip_type}" no es un tipo de viaje valido.')

        self.event_time = event_time
        self.type = trip_type
        self.route = route
        self.transportation_order = transportation_order
        transportation_order.trip = self
        route.add_trip(self)

    def shift_trip(self, delta_time):
        self.start_time += delta_time
        self.end_time += delta_time
        self.event_time += delta_time

    def __repr__(self):
        return f"({bf.int2strtime(self.event_time)}, {self.type})"

class TransportationOrder:
    def __init__(self, lat, lon, trip_type, vehicle_type=None, window_start=START_TIME, window_end=END_TIME, companion=0):
        if trip_type not in [PICKUP, DROPOFF]:
            raise Exception("Tipo de orden no valido.")

        self.lat = lat
        self.lon = lon
        self.type = trip_type
        self.vehicle_type = vehicle_type
        self.window_start = window_start
        self.window_end = window_end
        self.companion = companion
        self.priority_level = 3 if trip_type == DROPOFF else 5
        self.trip = None


# credenciales simpliroute
HEADERS = {
    "authorization": "Token 1a10aad5d0d4672ac09fba6f9de10fdac18f86d6",
    "content-type": "application/json"
}
OPT_URL = "https://optimizator.simpliroute.com/vrp/optimize/sync/"

# sesion para mantener la conexion activa
simpliroute_session = requests.Session()
simpliroute_session.headers.update(HEADERS)

def route_vehicles(vehicles_dict, tpt_orders_dict, lat_depot, lon_depot, name_depot, current_time):
    """
    Envia a SimpliRoute una solicitud de ruteo para las ordenes de transporte, utilizando los vehiculos indicados.
    Devuelve la primera ruta de cada vehiculo. Nota: las rutas entregadas no necesariamente comienzan en "current_time".
    ** Produce un resultado inesperado si no hay vehiculos ni ordenes.
    """

    vehicles = []
    nodes = []

    for veh_id, veh in vehicles_dict.items(): # agrega vehiculos
        vehicles.append({
            "ident": veh_id,
            "capacity": float(veh.capacity), # capacidad pickup
            "capacity_2": float(veh.capacity), # capacidad dropoff
            "shift_start": bf.int2strtime(min(END_TIME, max(veh.release_time, current_time))),
            "shift_end": bf.int2strtime(veh.shift_end),
            "refill": int(veh.refill),
            "location_start": {
                "ident": name_depot,
                "lat": float(lat_depot),
                "lon": float(lon_depot)
            }
        })

    for order_id, order in tpt_orders_dict.items(): # agrega nodos
        nodes.append({
            "ident": order_id,
            "lat": float(order.lat),
            "lon": float(order.lon),
            "window_start": bf.int2strtime(order.window_start), #if current_time < order.window_end else START_TIME),
            "window_end": bf.int2strtime(order.window_end), #if current_time < order.window_end else END_TIME),
            "duration": int(VISIT_DURATION),
            "load": int(1 + order.companion) if order.type == PICKUP else 0, # capacidad pickup
            "load_2": int(1 + order.companion) if order.type == DROPOFF else 0, # capacidad dropoff
            "priority_level": int(order.priority_level)
        })

    # input para simpliroute
    inputs = {
        "vehicles": vehicles,
        "nodes": nodes,
        "balance": False,
        "all_vehicles": False,
        "single_tour": False,
        "fmv": 2
    }
    
    #response = requests.post(OPT_URL, headers=HEADERS, json=inputs)
    response = simpliroute_session.post(OPT_URL, json=inputs)
    solution = response.json()

    #bf.jprint(inputs)
    #bf.jprint(solution)

    first_routes = []

    #if len(nodes) == 0 or len(vehicles) == 0:
    #    return first_routes

    if solution["num_vehicles_used"] == 0:
        return first_routes

    for veh in solution["vehicles"]:
        veh_id = veh["ident"]
        vehicle = vehicles_dict[veh_id]
        
        # si vehiculo posee alguna ruta, se extrae la primera
        if len(veh["tours"]) > 0:
            tour_nodes = veh["tours"][0]["nodes"] # nodos del primer tour
            departure_time = bf.strtime2int(tour_nodes[0]["departure"])
            arrival_time = bf.strtime2int(tour_nodes[-1]["arrival"])
        
            route = Route(vehicle, departure_time, arrival_time)
            first_routes.append(route)

            # nodos de visita
            for node in tour_nodes[1:-1]:
                order_id = node["ident"]
                tpt_order = tpt_orders_dict[order_id]
                event_time = bf.strtime2int(node["departure"] if tpt_order.type == PICKUP else node["arrival"])
                _ = Trip(tpt_order.type, event_time, route, tpt_order)

    return first_routes