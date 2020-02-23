import pandas as pd
import datetime as dt
import argparse
import time
import os
import basicfunc as bf
from center import Center
from vehicle import Vehicle
from patient import Patient
from doctor import Doctor
from constants import *

if __name__ == "__main__":

    start_time = time.time()
    
    parser = argparse.ArgumentParser()
    parser.add_argument('inputs', type=str)
    parser.add_argument('date', type=str)
    parser.add_argument('--verbose', type=bool, default=False)
    
    args = parser.parse_args()
    
    folder = args.inputs
    date = args.date
    verbose = args.verbose

    print(f"\nCalculando para {date}...")

    doctors_filepath = folder + "/attention_capacity.csv"
    doctors = Doctor.from_csv(doctors_filepath, date)

    vehicles_filepath = folder + "/vehicles.csv"
    vehicles = Vehicle.from_csv(vehicles_filepath, date)

    patients_filepath = folder + "/patients.csv"
    patients = Patient.from_csv(patients_filepath, date)

    # se muestra la oferta y demanda de atenciones de cada doctor
    for doc in doctors:
        count = 0
        for pat in patients:
            for att in pat.attention_orders:
                if att.required_doctor_id == doc.id:
                    count+=1

        print(f"{doc}: se demandan {count} de {len(doc.agenda)} citas")
            
    # se crea y simula el sistema
    c = Center("SanMiguel", -33.487056, -70.647836, verbose=verbose)
    _ = c.add_patients(patients)
    _ = c.add_doctors(doctors)
    _ = c.add_vehicles(vehicles)

    c.simulate_events()
    print(c)

    # se guarda, estadisticas, agendamiento y horas de referencia
    patients_stats = []
    vehicles_stats = []
    schedule_stats = []
    windows_stats = []

    file_time = dt.datetime.now().strftime("%Y_%m_%d_%H_%M_%S")

    for veh in list(c.vehicles.values()) + list(c.taxis.values()):
        dict_stats = veh.get_stats()
        dict_stats["date"] = date
        vehicles_stats.append(dict_stats)
    
    for pat in c.patients.values():
        dict_stats = pat.get_stats()
        dict_stats["date"] = date
        patients_stats.append(dict_stats)

        if pat.transport:
            pickup_time = bf.int2strtime(pat.pickup_order.trip.start_time)
        else:
            pickup_time = None

        attention_time = bf.int2strtime(pat.attention_time)
        windows_stats.append((pat.id, attention_time, pickup_time))

    for doc in c.doctors.values():
        for appt in doc.agenda:
            if not appt.available:
                appt_begin = bf.int2strtime(appt.start_time)
                schedule_stats.append((doc.id, appt_begin, date, appt.attention_order._patient.id))

    df_patients = pd.DataFrame(patients_stats)
    df_vehicles = pd.DataFrame(vehicles_stats)
    df_schedule = pd.DataFrame(schedule_stats, columns=["doctor_id","t_start","date","patient_id"])
    df_windows = pd.DataFrame(windows_stats, columns=["patient_id","attention_time","pickup_time"])

    df_patients.to_csv(f"{folder}/output_patients_{file_time}.csv", index=False)
    df_vehicles.to_csv(f"{folder}/output_vehicles_{file_time}.csv", index=False)
    df_schedule.to_csv(f"{folder}/output_schedule_{file_time}.csv", index=False)
    df_windows.to_csv(f"{folder}/output_windows_{file_time}.csv", index=False)

    elapsed_time = time.time() - start_time
    print(f"Tiempo ejecucion: {elapsed_time:.1f} segundos")