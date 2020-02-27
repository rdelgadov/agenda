from constants import *
import basicfunc as bf
import numpy as np
import pandas as pd
import os
from scipy.optimize import linear_sum_assignment

class Doctor:
    def __init__(self, ident, attention_type):

        if attention_type not in [PRIMARY_ATTENTION, SECONDARY_ATTENTION]:
            raise Exception(f'"{attention_type}" no es un tipo de atencion valido.')

        self.id = ident
        self.attention_type = attention_type
        self.agenda = []
        
    def __repr__(self):
        return f"Doctor({self.id}, {self.attention_type})"

    @staticmethod
    def from_csv(filepath, fecha, sep=","):
        df = pd.read_csv(os.path.join(os.getcwd(),filepath), sep=sep)
        df = df[df.date == fecha]

        docs = []

        for (ident, att_type), df_cap in df.groupby(["ident","attention_type"]):
            
            doctor = Doctor(str(ident), att_type)

            for _, row in df_cap.iterrows():
                start_time = bf.strtime2int(row.t_start)
                end_time = start_time + ATTENTION_DURATION[att_type]

                for i in range(row.capacity):
                    _ = Appointment(start_time, end_time, doctor)

            docs.append(doctor)

        return docs
            
    def add_appointment(self, appointment):
        self.agenda.append(appointment)

class Appointment:
    """Citas medicas. Componen la agenda de un doctor. Son asignadas a una orden de atencion."""
    def __init__(self, start_time, end_time, doctor):
        self.start_time = start_time
        self.end_time = end_time
        self.doctor = doctor
        self.attention_order = None
        doctor.add_appointment(self)

    @property
    def available(self):
        return (self.attention_order is None)

    def __repr__(self):
        return f"({bf.int2strtime(self.start_time)} - {bf.int2strtime(self.end_time)})"
    

class AttentionOrder:
    """Contiene las especificaciones de una solicitud de atencion."""
    def __init__(self, attention_type, required_doctor_id,
        window_start=START_TIME, window_end=END_TIME, medical_rest=True, required_time=None):
        
        if attention_type not in [PRIMARY_ATTENTION, SECONDARY_ATTENTION]:
            raise Exception(f'"{attention_type}" no es un tipo de atencion valido.')

        self.attention_type = attention_type
        self.required_doctor_id = required_doctor_id
        self.required_time = required_time
        self.medical_rest = medical_rest

        # franja horaria ideal de atencion
        self.window_start = window_start
        self.window_end = window_end
        
        self.appointment = None
        self.fixed_appointment = False

    def available_appointments(self, doctors_dict, min_time=START_TIME):
        """Entrega una lista con las citas disponibles para agendar la orden de atencion.
        Si la orden ya posee un cita agendada, entonces devuelve solo esta ultima.
        Opcionalmente se puede indicar una hora minima, la cual se usa para filtrar lo anterior.
        """
        if self.appointment is not None:
            if self.appointment.start_time >= min_time:
                return [self.appointment]
            else:
                return [ ]

        filt_function = lambda appt: appt.available and appt.start_time >= min_time
        required_doctor = doctors_dict[self.required_doctor_id]
        available_appts = filter(filt_function, required_doctor.agenda)
        
        if self.required_time is None:    
            return list(available_appts)
        else:
            return [appt for appt in available_appts if appt.start_time == self.required_time]
        
    def next_appointment(self, doctors_dict, current_time):
        available_appts = self.available_appointments(doctors_dict, min_time=current_time)
        next_appt = min(available_appts, key=lambda appt: appt.start_time, default=None)

        return next_appt

    def last_appointment(self, doctors_dict, current_time):
        available_appts = self.available_appointments(doctors_dict, min_time=current_time)
        last_appt = max(available_appts, key=lambda appt: appt.start_time, default=None)

        return last_appt
        
    def set_appointment(self, appointment, fixed=False):
        if not appointment.available:
            raise Exception(f"Cita de las {appointment.start_time} con {appointment.doctor} ya esta ocupada.")
        elif self.appointment is not None:
            raise Exception(f"Orden de atencion ya tiene cita agendada.")
        elif appointment.doctor.id != self.required_doctor_id:
            raise Exception(f"Orden de atencion requiere a doctor {self.required_doctor_id}.")
        elif self.required_time is not None and self.required_time != appointment.start_time:
            raise Exception(f"Orden de atencion requiere cita a las {bf.int2strtime(self.required_time)}")

        appointment.attention_order = self
        self.appointment = appointment
        self.fixed_appointment = fixed
        
    def cancel_appointment(self):
        if self.appointment is None:
            raise Exception("No es posible cancelar, pues no existe una cita agendada.")
        elif self.fixed_appointment:
            raise Exception("La cita es fija, no es posible cancelarla.")
        else:
            self.appointment.attention_order = None
            self.appointment = None

    def rate_appointments(self, available_appointments):
        """Evalua las citas, en el sentido de la preferencia de ventana de tiempo de la orden de atencion."""
        appointments_time = np.array([appt.start_time for appt in available_appointments])

        if self.medical_rest:
            time_deviation = np.maximum(self.window_start - appointments_time, appointments_time - self.window_end)
            time_deviation = np.maximum(time_deviation, 0)

        else:
            time_deviation = np.minimum((appointments_time - OPENING_TIME)**2, (appointments_time - CLOSING_TIME)**2)
            
        return time_deviation

def schedule_attention_orders(doctors_dict, att_orders):
    """
    Agenda las ordenes de atencion utilizando las citas disponibles de los doctores.

    Inputs:
    -- doctors_dict: diccionario de objetos de la clase Doctor, {id: doctor}
    -- att_orders: lista de objetos de la clase AttentionOrder

    Nota: en una version posterior, "att_orders" sera un diccionario de la forma
    {id: [att_order1, att_order2, ...]}, donde cada lista contendra las ordenes de un
    mismo paciente, y por lo tanto, los agendamientos no deben solaparse e idealmente
    no quedar muy espaciados.
    """

    for doc in doctors_dict.values():

        available_appointments = [appt for appt in doc.agenda if appt.available]

        # ordenes de atencion pendientes con el doctor
        pending_orders = [att_ord for att_ord in att_orders if att_ord.required_doctor_id == doc.id]
        
        # matriz de costos de asignacion
        deviations_matrix = np.empty((len(pending_orders),len(available_appointments)))
        
        for i, att_ord in enumerate(pending_orders):
            deviations_matrix[i, :] = att_ord.rate_appointments(available_appointments)

        # asignacion de citas a ordenes pendientes
        row_ind, col_ind = linear_sum_assignment(deviations_matrix)

        for i,j in zip(row_ind, col_ind):
            pending_orders[i].set_appointment(available_appointments[j])