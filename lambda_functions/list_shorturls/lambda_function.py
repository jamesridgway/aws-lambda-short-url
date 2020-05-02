import boto3
import json
import os

def lambda_handler(event, context):
    s3 = boto3.client('s3')

    urls = {}

    for key in s3.list_objects(Bucket=os.getenv('BUCKET_NAME'))['Contents']:
        obj = s3.get_object(Bucket=os.getenv('BUCKET_NAME'),Key=key['Key'])
        if 'WebsiteRedirectLocation' in obj.keys():
            redirect = obj['WebsiteRedirectLocation']
            urls["https://" + os.getenv('BUCKET_NAME') + "/" + key['Key']] = redirect
    
    body = {"urls": urls}
    return {'statusCode': 200,'body': json.dumps(body)}
