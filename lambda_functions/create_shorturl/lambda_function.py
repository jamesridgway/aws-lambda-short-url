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
    token = generate_token(url)

    s3 = boto3.client('s3')
    s3.put_object(ACL='public-read',Bucket=os.getenv('BUCKET_NAME'), Key=token, WebsiteRedirectLocation=url)

    return {'statusCode': 200,'body': json.dumps({'short_url' : 'https://' + os.getenv('BUCKET_NAME') + '/' + token, 'url': url, 'token': token})}

