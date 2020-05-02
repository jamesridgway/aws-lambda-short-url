import json
import random
import boto3
import os
def generate_token(value, length = 6):
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    random.seed(value)
    return ''.join(random.choice(chars) for _ in range(length))

def lambda_handler(event, context):
    if 'url' not in event['body']:
        return {'statusCode': 400,'body': json.dumps({'error': "No 'url' provided has been provided."})}
    url = json.loads(event['body'])['url']

    if 'custom_url' not in event['body']:
        token = generate_token(url)
    else:
        custom_url = json.loads(event['body'])['custom_url']
        if custom_url == "":
            token = generate_token(url)
        else:
            token = custom_url

    s3 = boto3.client('s3')

    objs = s3.list_objects(Bucket=os.getenv('BUCKET_NAME'),Prefix=token)

    if 'Contents' in objs.keys() and len(objs['Contents']) > 0 and objs['Contents'][0]['Key'] == token:
        return {'statusCode': 409, 'body': json.dumps({"error": "The token has already been taken"})}

    s3.put_object(ACL='public-read',Bucket=os.getenv('BUCKET_NAME'), Key=token, WebsiteRedirectLocation=url)
    return {'statusCode': 200,'body': json.dumps({'short_url' : 'https://' + os.getenv('BUCKET_NAME') + '/' + token, 'url': url, 'token': token})}
