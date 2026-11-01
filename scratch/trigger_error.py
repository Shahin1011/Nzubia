import urllib.request
import urllib.error
import json

token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTU2ODEyNy0xNjQ4LTRhMGEtYTQ2MC1iNTQyMDdmYmI4ZTAiLCJlbWFpbCI6ImNvdXJpZXIxMTIyQHlvcG1haWwuY29tIiwicm9sZSI6IkNPVVJJRVIiLCJpYXQiOjE3OTM0NjAzNDQsImV4cCI6MTgyOTQ3MDM0M30.smT-ftyGapJ_rxuiUqb3uyzGxMf1avBUDRWnIfLsH3Q'
user_id = '15568127-1648-4a0a-a460-b54207fbb8e0'
base = 'https://analyzed-newer-measured-achieve.trycloudflare.com/api/v1'

# Test sending invalid column to PATCH /users/:id to see TypeORM error with column names!
data = json.dumps({'invalid_column_name_xyz': 'test'}).encode('utf-8')
req = urllib.request.Request(f'{base}/users/{user_id}', data=data, method='PATCH', headers={
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
})
try:
    with urllib.request.urlopen(req) as resp:
        print('Resp:', resp.status, resp.read().decode())
except urllib.error.HTTPError as e:
    print('Err:', e.code, e.read().decode())
