import os
import pandas as pd
import basicfunc as bf
from doctor import AttentionOrder
from vehicle import TransportationOrder
from constants import *

class Patient:
    def __init__(self, ident, repose, transport):
        
        self.id = ident
        self.repose = repose
        self.transport = transport
        self.pickup_order = None
        self.dropoff_order = None
        self.attention_orders = []
        self.batch = None
        
    @property
    def attention_time(self):
        return min((att_order.appointment.start_time for att_order in self.attention_orders
            if att_order.appointment is not None), default=None)

    @property
    def release_time(self):
        return max((att_order.appointment.end_time for att_order in self.attention_orders
            if att_order.appointment is not None), default=None)
    
    def __repr__(self):
        return f"Patient({self.id})"

    @staticmethod
    def from_csv(filepath, fecha, sep=","):
        df = pd.read_csv(os.path.join(os.getcwd(),filepath), sep=sep)
        df = df[df.date == fecha]
        
        pats = []

        for (ident, med_rest, tpt_type), df_attentions in df.groupby(["ident","medical_rest","transportation_type"]):
            
            # creacion paciente
            patient = Patient(str(ident), bool(med_rest), tpt_type=="pick_up-and-delivery")

            # creacion ordenes de atencion
            for _, row in df_attentions.iterrows():

                if pd.isna(row.reference_attention_time):
                    window_start = START_TIME
                    window_end = END_TIME
                else:
                    reference_attention_time = bf.strtime2int(row.reference_attention_time)
                    window_start = max(START_TIME, reference_attention_time - ATTENTION_WINDOW_DEVIATION)
                    window_end = min(END_TIME, reference_attention_time + ATTENTION_WINDOW_DEVIATION)

                if pd.isna(row.required_attention_time):
                    required_attention_time = None
                else:
                    required_attention_time = bf.strtime2int(row.required_attention_time)
                
                att_order = AttentionOrder(row.attention_type, str(row.doctor_id),
                    window_start=window_start,
                    window_end=window_end,
                    medical_rest=bool(row.medical_rest),
                    required_time=required_attention_time)

                patient.add_attorder(att_order)
                
            # creacion ordenes de transporte (si aplica)
            if patient.transport:
                if pd.isna(row.reference_pickup_time):
                    window_start = START_TIME
                    window_end = END_TIME
                else:
                    reference_pickup_time = bf.strtime2int(row.reference_pickup_time)
                    window_start = max(START_TIME, reference_pickup_time - TRANSPORTATION_WINDOW_DEVIATION)
                    window_end = min(END_TIME, reference_pickup_time + TRANSPORTATION_WINDOW_DEVIATION)  

                pickup_order = TransportationOrder(row.lat, row.lon, PICKUP,
                    window_start=window_start, window_end=window_end, companion=row.companion)
                
                dropoff_order = TransportationOrder(row.lat, row.lon, DROPOFF, companion=row.companion)
                
                # se agregan las ordenes de atencion al paciente
                patient.add_tptorders(pickup_order, dropoff_order)

            pats.append(patient)

        return pats

    def add_tptorders(self, pickup_order, dropoff_order):
        self.pickup_order = pickup_order
        self.dropoff_order = dropoff_order
        pickup_order._patient = self
        dropoff_order._patient = self

    def add_attorder(self, att_order):
        self.attention_orders.append(att_order)

        # ordenes de atencion listadas segun ranking (ej: atencion secundaria,
        # y luego primaria) y por hora (aplica para ordenes con atencion fija,
        # en cuyo caso siempre quedan primero)
        self.attention_orders.sort(key=lambda order: ATTENTION_RANK[order.attention_type])
        self.attention_orders.sort(key=lambda order: order.required_time if order.required_time is not None else END_TIME)

        att_order._patient = self

    def schedule_attorders(self, doctors_dict, min_time):

        for att_order in self.attention_orders:
            # si orden no posee cita agendada, se busca una
            if att_order.appointment is None:
                next_appt = att_order.next_appointment(doctors_dict, min_time)

                if next_appt is None:
                    continue  # si no hay citas disponibles, se continua con el siguiente tipo de atencion
                else:
                    att_order.set_appointment(next_appt)
            
            min_time = max(min_time, att_order.appointment.end_time)

    def cancel_attorders(self):
        for att_order in self.attention_orders:
            # solo se puede cancelar una cita si no esta fija
            if att_order.appointment is None or att_order.fixed_appointment:
                pass
            else:
                att_order.cancel_appointment()

    def get_stats(self):
        stats = {"id": self.id, "repose": self.repose, "transport": self.transport}

        stats["required_attentions"] = len(self.attention_orders)
        stats["given_attentions"] = sum(att_order.appointment is not None for att_order in self.attention_orders)
        stats["attention_time"] = self.attention_time
        stats["release_time"] = self.release_time
        stats["pickup_time"] = None
        stats["arrival_time"] = None
        stats["pickup_vehicle"] = None
        stats["departure_time"] = None
        stats["dropoff_time"] = None
        stats["dropoff_vehicle"] = None

        if self.transport:
            if self.pickup_order.trip is not None:
                stats["pickup_time"] = self.pickup_order.trip.start_time
                stats["arrival_time"] = self.pickup_order.trip.end_time
                stats["pickup_vehicle"] = self.pickup_order.trip.route.vehicle.id

            if self.dropoff_order.trip is not None:
                stats["departure_time"] = self.dropoff_order.trip.start_time
                stats["dropoff_time"] = self.dropoff_order.trip.end_time
                stats["dropoff_vehicle"] = self.dropoff_order.trip.route.vehicle.id

        return stats

class Batch:
    def __init__(self, patients):
        self.patients = patients
        for pat in self.patients:
            pat.batch = self

    def schedule_patients(self, doctors_dict, min_time):
        for pat in self.patients:
            pat.schedule_attorders(doctors_dict, min_time)

    def cancel_patients(self):
        for pat in self.patients:
            pat.cancel_attorders()

    def dissolve(self):
        for pat in self.patients:
            pat.batch = None

        self.patients = []