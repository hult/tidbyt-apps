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
  percentage_cached = cache.get("percentage")
  if percentage_cached != None:
    print("Hit! Displaying cached data.")
    percentage = float(percentage_cached)
    date = cache.get("date")
    diff = float(cache.get("diff"))
  else:
    print("Miss! Calling API.")
    rep = http.get(URL)
    if rep.status_code != 200:
      fail("API request failed with status %d", rep.status_code)

    data = rep.json()["registrerade_vaccinationer_doses"][0]
    percentage = data["f_person_dose_1"] * 100
    diff = data["diff_f_person_dose_1"]
    date = "%s/%s" % (data["datum_day"], data["datum_month"])
    cache.set("percentage", str(percentage), ttl_seconds=TTL)
    cache.set("date", date, ttl_seconds=TTL)
    cache.set("diff", str(diff), ttl_seconds=TTL)

  return render.Root(
    render.Box(color="#222", child=
      render.Row(expanded=True, main_align="space_around", children=[
        render.Column(expanded=True, main_align="center", children=[
          render.Image(src=ICON)
        ]),
        render.Column(expanded=True, main_align="space_around", children=[
          render.Text(date),
          render.Text("%s%%" % one_decimal(percentage)),
          render.Text("(+%s%%)" % one_decimal(diff)),
        ])
      ])
    )
  )
