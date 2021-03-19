load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("cache.star", "cache")

URL = "https://www.svt.se/special/articledata/3362/fohm_tabeller.json"
ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAyElEQVRIS9WVQRKAIAhF9X4t6qS16H42OOGQIgK6yVVi/tcXgxjkkUIIcfCOuNzbDMI4lgJqYZy7IXRjT2wKgoDekdA4HJnZCQXAsyTocsJ9USO0nXuO3cdlTnwP8IkjwAORrmmkwvSyW5xISUvbuRddEK3n76KY+NGtyJBaHKkaJyMAaE050QAKxONEC3A7MQGAwuWE5KL52y2A7AIh2kRbAQXCNAFWywOgkLpYNnpeANfF2GK4EsA5s9d3RX/+9PHVDhr+/wEP4zBOGb2R0KMAAAAASUVORK5CYII=")
TTL = 3600

def one_decimal(f):
  s = "%f" % f
  a, b = s.split(".")
  return "%s.%s" % (a, b[0])

def main(config):
  number_cached = cache.get("number")
  if number_cached != None:
    print("Hit! Displaying cached data.")
    number = float(number_cached)
    diff_number = int(cache.get("diff_number"))
    percentage = float(cache.get("percentage"))
    diff_percentage = float(cache.get("diff_percentage"))
    date = cache.get("date")
  else:
    print("Miss! Calling API.")
    rep = http.get(URL)
    if rep.status_code != 200:
      fail("API request failed with status %d", rep.status_code)

    data = rep.json()["registrerade_vaccinationer_doses"][0]
    date = "%s/%s" % (data["datum_day"], data["datum_month"])
    number = data["n_person_dose_1"]
    diff_number = data["diff_n_person_dose_1"]
    percentage = data["f_person_dose_1"] * 100
    diff_percentage = data["diff_f_person_dose_1"]

    cache.set("number", str(number), ttl_seconds=TTL)
    cache.set("diff_number", str(diff_number), ttl_seconds=TTL)
    cache.set("percentage", str(percentage), ttl_seconds=TTL)
    cache.set("diff_percentage", str(diff_percentage), ttl_seconds=TTL)
    cache.set("date", date, ttl_seconds=TTL)

  return render.Root(
    delay=5000,
    child=render.Box(color="#222", child=
      render.Row(expanded=True, main_align="start", children=[
        render.Column(expanded=True, main_align="center", children=[
          render.Image(src=ICON)
        ]),
        render.Animation(
          children=[
            render.Column(expanded=True, main_align="space_around", children=[
              render.Text(date, color="#55c"),
              render.Text("%s%%" % one_decimal(percentage)),
              render.Text("(+%s%%)" % one_decimal(diff_percentage)),
            ]),
            render.Column(expanded=True, main_align="space_around", children=[
              render.Text(date, color="#55c"),
              render.Text("%s" % number),
              render.Text("(+%s)" % diff_number),
            ]),
          ]
        )
      ])
    )
  )
