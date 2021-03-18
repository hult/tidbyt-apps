load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")

URL = "https://www.svt.se/special/articledata/3362/fohm_tabeller.json"
ICON = base64.decode("iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAAyElEQVRIS9WVQRKAIAhF9X4t6qS16H42OOGQIgK6yVVi/tcXgxjkkUIIcfCOuNzbDMI4lgJqYZy7IXRjT2wKgoDekdA4HJnZCQXAsyTocsJ9USO0nXuO3cdlTnwP8IkjwAORrmmkwvSyW5xISUvbuRddEK3n76KY+NGtyJBaHKkaJyMAaE050QAKxONEC3A7MQGAwuWE5KL52y2A7AIh2kRbAQXCNAFWywOgkLpYNnpeANfF2GK4EsA5s9d3RX/+9PHVDhr+/wEP4zBOGb2R0KMAAAAASUVORK5CYII=")

def one_decimal(f):
  s = "%f" % f
  a, b = s.split(".")
  return "%s.%s" % (a, b[0])

def main(config):
  rep = http.get(URL)
  if rep.status_code != 200:
    fail("API request failed with status %d", rep.status_code)

  data = rep.json()["registrerade_vaccinationer_doses"][0]
  percentage = data["f_person_dose_1"] * 100

  return render.Root(
    render.Box(color="#222", child=
      render.Row(expanded=True, main_align="space_around", children=[
        render.Column(expanded=True, main_align="center", children=[
          render.Image(src=ICON)
        ]),
        render.Column(expanded=True, main_align="space_around", children=[
          render.Text(data["datum_str"]),
          render.Text("%s%%" % one_decimal(percentage))
        ])
      ])
    )
  )
