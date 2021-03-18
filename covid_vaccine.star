load("render.star", "render")
load("http.star", "http")

URL = "https://www.svt.se/special/articledata/3362/fohm_tabeller.json"

def main(config):
  rep = http.get(URL)
  if rep.status_code != 200:
    fail("API request failed with status %d", rep.status_code)

  data = rep.json()["registrerade_vaccinationer_doses"][0]

  return render.Root(
    child = render.Row(
      children = [
        render.Text(data["datum_str"]),
        render.Text("%f" % (data["f_person_dose_1"] * 100))
      ]
    )
  )
