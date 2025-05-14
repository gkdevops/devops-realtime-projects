## AWS Lambda Function with SQS Processing

Step 1: Create a Lambda Function with Python 3.12 and paste below code in Lambda Code section

```
import json

def lambda_handler(event, context):
    record = event['Records']

    for rec in record:
        body = rec['body']
        print(body)
        print(rec['attributes'])
```
