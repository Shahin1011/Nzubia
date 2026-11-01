import urllib.request
import urllib.error
import json

token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxNTU2ODEyNy0xNjQ4LTRhMGEtYTQ2MC1iNTQyMDdmYmI4ZTAiLCJlbWFpbCI6ImNvdXJpZXIxMTIyQHlvcG1haWwuY29tIiwicm9sZSI6IkNPVVJJRVIiLCJpYXQiOjE3OTM0NjAzNDQsImV4cCI6MTgyOTQ3MDM0M30.smT-ftyGapJ_rxuiUqb3uyzGxMf1avBUDRWnIfLsH3Q'
user_id = '15568127-1648-4a0a-a460-b54207fbb8e0'
base = 'https://analyzed-newer-measured-achieve.trycloudflare.com/api/v1'

test_fields = [
    'phone', 'fullName', 'full_name', 'first_name', 'last_name', 
    'profile_picture_url', 'profile_image_url', 'profilePictureUrl', 'profileImageUrl',
    'avatar', 'avatar_url', 'image', 'picture', 'photo', 'photo_url'
]

# Send non-string (e.g. array or int) to see if validation pipe accepts the field
for field in test_fields:
    data = json.dumps({field: 99999}).encode('utf-8')
    for endpoint in [f'{base}/users/profile', f'{base}/users/{user_id}']:
        req = urllib.request.Request(endpoint, data=data, method='PATCH', headers={
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + token
        })
        try:
            with urllib.request.urlopen(req) as resp:
                pass
        except urllib.error.HTTPError as e:
            if e.code == 400:
                print(f'400 on {endpoint} for {field}: {e.read().decode()}')
