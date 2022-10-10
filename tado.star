# See http://blog.scphillips.com/posts/2017/01/the-tado-api-v2/
# and https://shkspr.mobi/blog/2019/02/tado-api-guide-updated-for-2019/

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("math.star", "math")

OAUTH2_CLIENT_SECRET = 'XXX'
EXAMPLE_PARAMS = '{ "client_id": "tado-web-app", "grant_type": "password", "scope": "home.user", "username": "XXX", "password": "XXX" }'
TADO_API_URL = 'https://my.tado.com/api'
TEMP_UNIT = 'celsius'

def tado_request(path, access_token):
    res = http.get(url = TADO_API_URL + path, headers = { 'Authorization': 'Bearer ' + access_token })
    if res.status_code != 200:
      fail("API request failed with status %d", res.status_code)
    data = res.body()
    json_data = json.decode(data)
    return json_data

def get_home_id(access_token):
    return tado_request('/v1/me', access_token)['homeId']

def get_home(home_id, access_token):
    return tado_request('/v2/homes/%s' % home_id, access_token)

def get_zones(home_id, access_token):
    return tado_request('/v2/homes/%s/zones' % home_id, access_token)

def get_zone_state(home_id, zone_id, access_token):
    return tado_request('/v2/homes/%s/zones/%s/state' % (home_id, zone_id), access_token)

def short_name(name):
    return name.upper()[0:3]

def extract_room(home_id, zone, access_token):
    state = get_zone_state(home_id, zone['id'], access_token)
    return {
        'name': short_name(zone['name']),
        'temperature': state['sensorDataPoints']['insideTemperature'][TEMP_UNIT],
        'humidity': state['sensorDataPoints']['humidity']['percentage'],
        'power': state['setting']['power'],
        'mode': state['setting']['type'],
        'desired_temperature': 'temperature' in state['setting'] and state['setting']['temperature'][TEMP_UNIT] or None
    }

def get_color(room):
    if room['power'] == 'OFF':
        return '#666'
    elif room['mode'] == 'HEATING':
        return '#ffa600'
    else:
        return '#1d9bf0'

def oauth_handler(params):
    params = json.decode(params)

    # exchange parameters and client secret for an access token
    res = http.post(
        url = "https://auth.tado.com/oauth/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            client_secret = OAUTH2_CLIENT_SECRET,
        ),
        form_encoding = "application/x-www-form-urlencoded",
    )
    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    return access_token

def desired_temperature(room):
    if room['power'] == 'OFF':
        return render.Circle(diameter=5, color=get_color(room))
    else:
        return render.Row(children=[
            render.Circle(diameter=5, color=get_color(room)),
            render.Padding(pad=(1, 0, 0, 0), child=
                render.Text("%d" % math.round(room['desired_temperature']), font="CG-pixel-3x5-mono")
            )
        ])

def main(config):
    access_token = oauth_handler(EXAMPLE_PARAMS)
    home_id = get_home_id(access_token)
    zones = get_zones(home_id, access_token)
    shown_zones = zones[0:4]
    rooms = [extract_room(home_id, zone, access_token) for zone in shown_zones]
    return render.Root(child=
        render.Box(color="#222", child=
            render.Row(expanded=True, main_align="space_around", cross_align="center", children=[
                render.Column(expanded=True, main_align="space_around", cross_align="center", children=[
                    render.Text(content=room['name'], color="#ff0", font="CG-pixel-3x5-mono"),
                    desired_temperature(room),
                    render.Text("%d" % math.round(room['temperature'])),
                    render.Text("%d%%" % math.round(room['humidity']), color="#1d9bf0", font="CG-pixel-3x5-mono")
                ])
            for room in rooms])
        )
    )
