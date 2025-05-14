# AWS Lambda Function with SQS Processing

## Step-by-step Guide on how to set up AWS SQS (Simple Queue Service) with AWS Lambda. 

This setup allows you to decouple services, where messages are sent to an SQS queue, and a Lambda function is automatically triggered to process those messages.

**Conceptual Overview:**

**SQS Queue:** Think of this as a digital mailbox. Applications that need to send information to be processed later drop their messages into this mailbox.

**Lambda Function:** This is like a worker that's ready to pick up and process the messages from the SQS queue. It contains the specific instructions (code) on what to do with each message. It automatically starts working when new messages arrive.

**Event Source Mapping:** This is the crucial link that tells AWS Lambda to keep an eye on the SQS queue. When new messages appear in the queue, the event source mapping acts like a trigger, automatically waking up the Lambda function and feeding it the messages to process.

**IAM Roles & Permissions:** These are like security passes and rules. The Lambda function needs a "pass" (IAM role with the right permissions) to be allowed to "read" the messages from the SQS queue. Similarly, SQS needs permission to "tell" (invoke) the Lambda function when there are messages to be processed. IAM roles and permissions ensure that only authorized services can interact with each other.

### Step-by-Step Instructions:

This guide provides step-by-step instructions on how to set up an AWS Simple Queue Service (SQS) queue and configure an AWS Lambda function to process messages from it.

### Step 1: Create an SQS Queue

1.  **Navigate to the SQS Console:**
    Open the [AWS Management Console](https://aws.amazon.com/console/).
    In the search bar, type "SQS" and select **Simple Queue Service**.

2.  **Create a New Queue:**
    Click on **Create queue**.

3.  **Choose Queue Type:**
    * **Type:** Choose between **Standard** (default, offers at-least-once delivery and best-effort ordering) or **FIFO** (First-In, First-Out, guarantees order and exactly-once processing, but has lower throughput). For most general use cases, **Standard** is sufficient. If you choose FIFO, your queue name must end with `.fifo`.
    * **Name:** Give your queue a descriptive name (e.g., `MyApplicationQueue` or `MyApplicationQueue.fifo`).

4.  **Configure Queue Settings (Defaults are often a good start):**
    * **Visibility timeout:** The period during which a message, after being read by a consumer (your Lambda), remains invisible to other consumers. If your Lambda processes the message successfully, it should delete the message from the queue. If it fails or the timeout expires before deletion, the message becomes visible again for another attempt. Set this based on your expected processing time.
    * **Message retention period:** How long SQS will keep a message if it's not deleted (default is 4 days, can be up to 14 days).
    * **Delivery delay:** Time to delay the first delivery of new messages to the queue.
    * **Receive message wait time:** Enables long polling. Setting this to a value greater than 0 (e.g., 20 seconds) reduces the number of empty responses and can lower costs.
    * **Dead-letter queue (DLQ):** Highly recommended for production. This is a separate SQS queue where messages that fail processing multiple times are sent. This helps in debugging and prevents "poison pill" messages (messages that consistently cause errors) from blocking the queue.
        * To set up a DLQ, you'll first need to create another SQS queue (e.g., `MyApplicationDLQ`) and then configure it in the main queue's settings under the "Redrive policy (optional)" section.

5.  **Click "Create queue."**

6.  **Note the Queue ARN:**
    Once created, select your queue and find its **ARN (Amazon Resource Name)** in the **Details** tab. You'll need this later.

### Step 2: Create an IAM Role for the Lambda Function

Your Lambda function needs permission to interact with SQS and CloudWatch Logs (for logging).

1.  **Navigate to the IAM Console:**
    In the [AWS Management Console](https://aws.amazon.com/console/), search for "IAM" and select it.

2.  **Create a New Role:**
    Go to **Roles** in the left navigation pane and click **Create role**.

3.  **Select Trusted Entity Type:**
    Select **AWS service**.

4.  **Choose Use Case:**
    Choose **Lambda** and click **Next**.

5.  **Add Permissions:**
    Search for and select the policy **AWSLambdaSQSQueueExecutionRole**. This managed policy grants permissions to poll messages from SQS and write logs to CloudWatch.
    * If you need more specific permissions (e.g., sending messages to another SQS queue, interacting with other AWS services), you can add more policies or create a custom policy. For basic SQS processing, this policy is a good starting point.

6.  **Click "Next."**

7.  **Name and Create Role:**
    * **Role name:** Give it a descriptive name (e.g., `MyLambdaSQSProcessorRole`).
    * Review the settings and click **Create role**.

## Step 3: Create the Lambda Function

1.  **Navigate to the Lambda Console:**
    In the [AWS Management Console](https://aws.amazon.com/console/), search for "Lambda" and select it.

2.  **Create a New Function:**
    Click on **Create function**.

3.  **Choose Author from Scratch:**
    Select this option.

4.  **Configure Basic Function Settings:**
    * **Function name:** Give your Lambda function a name (e.g., `MySQSMessageProcessor`).
    * **Runtime:** Choose your preferred programming language and version (e.g., Python 3.x, Node.js 18.x, Java 11, etc.).
    * **Architecture:** Choose the appropriate processor architecture (e.g., `x86_64` or `arm64`).

5.  **Configure Permissions:**
    * Expand **Change default execution role**.
    * Select **Use an existing role**.
    * From the **Existing role** dropdown, choose the IAM role you created in Step 2 (e.g., `MyLambdaSQSProcessorRole`).

6.  **Click "Create function."**

7.  **Write Your Lambda Function Code:**
    In the **Code source** section, you'll see an inline editor or options to upload a `.zip` file or use an S3 location.


    ```
    import json
    
    def lambda_handler(event, context):
        record = event['Records']
    
        for rec in record:
            body = rec['body']
            print(body)
            print(rec['attributes'])
    ```


8.  **Configure Lambda Settings (Optional but Recommended):**
    * **Basic settings:** Adjust memory and timeout. The timeout should be longer than your SQS queue's visibility timeout to allow for processing and retries if needed, but also consider the Lambda max timeout (15 minutes).
    * **Environment variables:** Useful for storing configuration details.
    * **Dead Letter Queue (for Lambda):** You can also configure a DLQ (SNS topic or another SQS queue) for the Lambda function itself, to handle cases where the Lambda function fails unexpectedly (e.g., due to code errors, not message processing errors). This is different from the SQS DLQ. You can configure this in the "Configuration" tab under "Asynchronous invocation."

## Step 4: Configure the SQS Trigger for the Lambda Function

This step connects your SQS queue to the Lambda function.

1.  **In the Lambda Function Configuration:**
    Select your Lambda function.
    Go to the **Function overview** section and click on **+ Add trigger**.
    Alternatively, go to the **Configuration** tab and select **Triggers**, then click **Add trigger**.

2.  **Select SQS as the Trigger Source:**
    From the **Select a trigger** dropdown, choose **SQS**.

3.  **Configure the Trigger:**
    * **SQS queue:** Select the SQS queue you created in Step 1.
    * **Batch size:** The maximum number of messages that Lambda will retrieve from the queue in a single batch (up to 10 for Standard queues, or 1 to 10 for FIFO queues, but can also be up to 10,000 with a higher `MaximumBatchingWindowInSeconds`). Start with a small batch size (e.g., 1 or 10) and adjust based on your processing logic and performance.
    * **Batch window (MaximumBatchingWindowInSeconds):** The maximum amount of time Lambda will wait to gather a full batch of messages before invoking your function. This can help improve efficiency for low-traffic queues.
    * **Enable trigger:** Ensure this is checked.
    * **Additional settings (Important):**
        * **Report batch item failures (Recommended):** If your function code is designed to process messages individually within a batch and can report which specific messages failed (by throwing an error or returning a specific response format), enable this. This allows Lambda to only return the failed messages to the queue for reprocessing, instead of the entire batch. This requires your Lambda function to return an object with a `batchItemFailures` array listing the `itemIdentifier` (message ID) of the failed messages.
        * **Concurrent executions:** You can limit the number of concurrent Lambda invocations for this SQS trigger.

4.  **Click "Add."** AWS will automatically try to set up the necessary permissions for SQS to invoke your Lambda function. If there are any permission issues, you might need to adjust the Lambda function's resource-based policy.

## Step 5: Test the Setup

1.  **Send a Message to the SQS Queue:**
    Go back to the [SQS console](https://console.aws.amazon.com/sqs/v2/home).
    Select your queue.
    Click on **Send and receive messages**.
    In the **Message body** field, enter some test data (e.g., simple text or a JSON string like `{"key": "value", "id": 123}`).
    Click **Send message**.

2.  **Monitor the Lambda Function:**
    Go to the [Lambda console](https://console.aws.amazon.com/lambda/home).
    Select your function.
    Go to the **Monitor** tab.
    Click on **View logs in CloudWatch**. This will take you to the CloudWatch Log Group for your Lambda function.
    Look for the latest log stream. You should see log entries from your Lambda function, including any `print` or `console.log` statements, indicating that it received and processed the message.

3.  **Verify Message Deletion (if successful):**
    Go back to the [SQS console](https://console.aws.amazon.com/sqs/v2/home) and check your queue. If the Lambda function executed successfully and didn't error out (and you haven't enabled "Report batch item failures" with specific failed messages), the message should have been automatically deleted from the queue. You can check the **Messages available** and **Messages in flight** metrics.

By following these steps, you have successfully integrated an AWS SQS queue with an AWS Lambda function to process messages. Remember to adjust the configurations based on your specific application requirements.
