load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("math.star", "math")

# Shows the nearest ship if there is one, fails otherwise
# Depends on https://github.com/transparency-everywhere/ais-api running
# locally to get ship data

EARTH_RADIUS = 6373.0
TTL = 3600

def pow(n, p):
  # Return n to the p:th power
  r = 1
  for i in range(p):
    r *= n
  return r

def distance(lat1, lon1, lat2, lon2):
  # Naïve sphere distane between two geocoordinates
  lat1 = math.radians(lat1)
  lon1 = math.radians(lon1)
  lat2 = math.radians(lat2)
  lon2 = math.radians(lon2)
  dlon = lon2 - lon1
  dlat = lat2 - lat1
  a = pow(math.sin(dlat / 2), 2) + math.cos(lat1) * math.cos(lat2) * pow(math.sin(dlon / 2), 2)
  c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
  return EARTH_RADIUS * c

def main(config):
  area = config.get("area") or "BALTIC"
  lat = config.get("lat") and float(config.get("lat")) or 59.3198746
  lon = config.get("lon") and float(config.get("lon")) or 18.0135445
  data = cache.get("data")
  if data != None:
    print("Hit! Displaying cached data.")
  else:
    print("Miss! Calling API.")
    resp = http.get("http://localhost:5000/getVesselsInArea/%s" % area)
    if resp.status_code != 200:
      fail("API request failed with status %d", resp.status_code)

    data = resp.body()
    cache.set("data", data, ttl_seconds=TTL)

  json_data = json.loads(data)
  min_distance = None
  nearest_ship = None
  for ship in json_data:
    if ship["lat"] and ship["lon"] and ship["speed"] > 0:
      d = distance(lat, lon, ship["lat"], ship["lon"])
      if min_distance == None or d < min_distance:
        print(d, ship["name"])
        min_distance = d
        nearest_ship = ship

  if nearest_ship == None:
    fail("No ships found")

  return render.Root(
    delay=5000,
    child=render.Box(color="#222", child=
      render.Column(expanded=True, main_align="space_around", children=[
        render.Text(nearest_ship["name"], color="#55c"),
        render.Text("%d m" % int(min_distance * 1000)),
        # render.Text("(+%s%%)" % decimal(diff_percentage)),
      ])
    )
  )
