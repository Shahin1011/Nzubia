import urllib.request
import urllib.error
import json

token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTU2ODEyNy0xNjQ4LTRhMGEtYTQ2MC1iNTQyMDdmYmI4ZTAiLCJlbWFpbCI6ImNvdXJpZXIxMTIyQHlvcG1haWwuY29tIiwicm9sZSI6IkNPVVJJRVIiLCJpYXQiOjE3OTM0NjAzNDQsImV4cCI6MTgyOTQ3MDM0M30.smT-ftyGapJ_rxuiUqb3uyzGxMf1avBUDRWnIfLsH3Q'
user_id = '15568127-1648-4a0a-a460-b54207fbb8e0'
base = 'https://analyzed-newer-measured-achieve.trycloudflare.com/api/v1'

# Let's test PATCH /users/profile with phone number
data = json.dumps({'phone': '+1987654321', 'fullName': 'Courier John'}).encode('utf-8')
req = urllib.request.Request(f'{base}/users/profile', data=data, method='PATCH', headers={
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
})
with urllib.request.urlopen(req) as resp:
    print('PATCH /users/profile resp:', resp.status)

# Check GET /users/profile
get_req = urllib.request.Request(f'{base}/users/profile', headers={'Authorization': 'Bearer ' + token})
with urllib.request.urlopen(get_req) as get_resp:
    res = json.loads(get_resp.read().decode())
    print('GET /users/profile phone:', res.get('phone'))

# Now test PATCH /users/:id with phone number
req2 = urllib.request.Request(f'{base}/users/{user_id}', data=data, method='PATCH', headers={
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
})
with urllib.request.urlopen(req2) as resp2:
    print('PATCH /users/:id resp:', resp2.status, resp2.read().decode())

# Check GET /users/profile again
get_req = urllib.request.Request(f'{base}/users/profile', headers={'Authorization': 'Bearer ' + token})
with urllib.request.urlopen(get_req) as get_resp:
    res = json.loads(get_resp.read().decode())
    print('GET /users/profile phone after /users/:id:', res.get('phone'))
