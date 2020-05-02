import boto3
import json
from multiprocessing import Process, Pipe
import os

def get_redirect(s3, key, conn):
    obj = s3.get_object(Bucket=os.getenv('BUCKET_NAME'),Key=key)
    if 'WebsiteRedirectLocation' in obj.keys():
        redirect = obj['WebsiteRedirectLocation']
        url = "https://" + os.getenv('BUCKET_NAME') + "/" + key
        conn.send([url, redirect])
    else:
        conn.send([])
    conn.close()

def lambda_handler(event, context):
    s3 = boto3.client('s3')

    processes = []
    parent_connections = []

    for key in s3.list_objects(Bucket=os.getenv('BUCKET_NAME'))['Contents']:
        parent_conn, child_conn = Pipe()
        parent_connections.append(parent_conn)
        process = Process(target=get_redirect, args=(s3,key['Key'], child_conn))
        processes.append(process)

    for process in processes:
        process.start()
    for process in processes:
        process.join()

    urls = {}
    for parent_connection in parent_connections:
        result = parent_connection.recv()
        if len(result) == 2:
            urls[result[0]] = result[1]

    body = {"urls": urls}
    return {'statusCode': 200,'body': json.dumps(body)}
