import json

def jprint(obj):
    # create a formatted string of the Python JSON object
    text = json.dumps(obj, sort_keys=True, indent=4)
    print(text)

def pretty(d, indent=0):
   for key, value in d.items():
      print('\t' * indent + str(key))
      if isinstance(value, dict):
         pretty(value, indent+1)
      else:
         print('\t' * (indent+1) + str(value))

def int2strtime(t):
    """Convierte entero a string con formato de hora. El cero corresponde a las 00:00."""
    if t >= 0:
        return "{:02d}:{:02d}".format(*divmod(t, 60))
    else:
        return "-{:02d}:{:02d}".format(*divmod(-t, 60))
    
def strtime2int(t):
    """Convierte string con formato de hora a entero. El cero corresponde a las 00:00."""
    hour, minute = t.split(":")
    return int(hour) * 60 + int(minute)