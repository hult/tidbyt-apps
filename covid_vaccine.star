load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")
load("encoding/json.star", "json")

URL = "https://www.svt.se/special/articledata/3362/owid_vax.json"
ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAyElEQVRIS9WVQRKAIAhF9X4t6qS16H42OOGQIgK6yVVi/tcXgxjkkUIIcfCOuNzbDMI4lgJqYZy7IXRjT2wKgoDekdA4HJnZCQXAsyTocsJ9USO0nXuO3cdlTnwP8IkjwAORrmmkwvSyW5xISUvbuRddEK3n76KY+NGtyJBaHKkaJyMAaE050QAKxONEC3A7MQGAwuWE5KL52y2A7AIh2kRbAQXCNAFWywOgkLpYNnpeANfF2GK4EsA5s9d3RX/+9PHVDhr+/wEP4zBOGb2R0KMAAAAASUVORK5CYII=")
TTL = 3600

def one_decimal(f):
  s = "%f" % f
  a, b = s.split(".")
  return "%s.%s" % (a, b[0])

def main(config):
  data = cache.get("data")
  if data != None:
    print("Hit! Displaying cached data.")
  else:
    print("Miss! Calling API.")
    resp = http.get(URL)
    if resp.status_code != 200:
      fail("API request failed with status %d", resp.status_code)

    data = resp.body()
    cache.set("data", data, ttl_seconds=TTL)

  json_data = json.loads(data)
  country = config.get("country") or "SWE"
  country_data = None
  for row in json_data:
    if row["code"] == country:
      # We want the last row, so don't break loop
      country_data = row

  if country_data == None:
    fail("No data for country %s" % country)

  date = country_data["datestr"]
  year, month, day = date.split("-")
  if country == "USA":
    # Poor man's date formatting
    date_string = "%s/%s" % (month.strip("0"), day.strip("0"))
  else:
    date_string = "%s/%s" % (day.strip("0"), month.strip("0"))
  number = country_data["n_total"]
  diff_number = country_data["n_diff7"]
  percentage = country_data["f_total"] * 100
  diff_percentage = country_data["f_diff7"] * 100

  return render.Root(
    delay=5000,
    child=render.Box(color="#222", child=
      render.Row(expanded=True, main_align="start", children=[
        render.Column(expanded=True, main_align="center", cross_align="center", children=[
          render.Image(src=ICON)
        ]),
        render.Animation(
          children=[
            render.Column(expanded=True, main_align="space_around", children=[
              render.Text("%s %s" % (country, date_string), color="#55c"),
              render.Text("%s%%" % one_decimal(percentage)),
              render.Text("(+%s%%)" % one_decimal(diff_percentage)),
            ]),
            render.Column(expanded=True, main_align="space_around", children=[
              render.Text("%s %s" % (country, date_string), color="#55c"),
              render.Text("%d" % number),
              render.Text("(+%d)" % diff_number),
            ]),
          ]
        )
      ])
    )
  )
