import boto3
import os
def lambda_handler(event, context):
    token = event['pathParameters']['token']

    s3 = boto3.client('s3')
    s3.delete_object(Bucket=os.getenv('BUCKET_NAME'), Key=token)

    return {'statusCode': 200,'body': '{}'}