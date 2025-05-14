# AWS Project: SQS, IAM Roles, and EC2 Instance with NodeJS (Step-by-Step)

This guide outlines the general steps involved in an AWS project demonstrating the use of SQS, IAM Roles, and an EC2 instance running a NodeJS application. **Please note that without the specific YouTube video, these steps are a general interpretation and might need adjustments based on the video's content.**

## Step 1: Set Up the SQS Queue (as Message Broker)

1.  **Navigate to the SQS Console:**
    Open the [AWS Management Console](https://aws.amazon.com/console/) and search for **SQS**.

2.  **Create a New Queue:**
    Click **Create queue**.

3.  **Choose Queue Type:**
    Select either **Standard** or **FIFO** based on the video's demonstration. Note the naming convention for FIFO queues (`.fifo` suffix).

4.  **Configure Queue Parameters:**
    * **Name:** Provide a descriptive name (e.g., `NodeJStoEC2Queue`).
    * **Visibility Timeout:** Set an appropriate timeout based on the expected processing time on the EC2 instance.
    * **Message Retention Period:** Choose how long messages should be kept.
    * **(Optional) Dead-letter queue (DLQ):** Consider creating a DLQ for handling processing failures.

5.  **Click "Create queue"** and note the **Queue ARN**.

## Step 2: Create an IAM Role for the EC2 Instance

This role will grant the EC2 instance permissions to interact with the SQS queue (specifically, to receive and potentially delete messages).

1.  **Navigate to the IAM Console:**
    Open the [AWS Management Console](https://aws.amazon.com/console/) and search for **IAM**.

2.  **Go to "Roles" and click "Create role".**

3.  **Select "AWS service" as the trusted entity type.**

4.  **Choose "EC2" as the use case.**

5.  **Click "Next: Permissions".**

6.  **Search for and attach the following policy:**
    * **AmazonSQSReadOnlyAccess** (if the EC2 instance only needs to receive messages)
    * **AmazonSQSFullAccess** (if the EC2 instance needs to send, receive, and delete messages)
    * **It's best practice to grant only the necessary permissions by creating a custom policy with specific SQS actions on your queue ARN.**

7.  **Click "Next: Tags" (optional) and then "Next: Review".**

8.  **Provide a "Role name"** (e.g., `EC2SQSNodeJSRole`) and click **"Create role"**. Note the **Role ARN**.

## Step 3: Launch an EC2 Instance

This instance will host the NodeJS application that will interact with the SQS queue.

1.  **Navigate to the EC2 Console:**
    Open the [AWS Management Console](https://aws.amazon.com/console/) and search for **EC2**.

2.  **Click "Launch instance".**

3.  **Choose an Amazon Machine Image (AMI):** Select an appropriate AMI (e.g., Amazon Linux 2, Ubuntu) that can run NodeJS.

4.  **Choose an Instance Type:** Select an instance type based on your needs (e.g., `t2.micro` for testing).

5.  **Configure Instance Details:**
    * **IAM role:** In the "IAM role" dropdown, select the IAM role you created in **Step 2** (`EC2SQSNodeJSRole`).
    * Configure other settings as needed (VPC, Subnet, Security Groups - ensure port 22 for SSH and any other necessary ports are open).

6.  **Add Storage:** Configure the instance's storage.

7.  **Add Tags (optional).**

8.  **Configure Security Group:**
    * Allow SSH access (port 22) from your IP address or a wider range if necessary.
    * Open any other ports required by your NodeJS application (if it serves a web interface, for example).

9.  **Review and Launch:** Review your instance configuration and click **"Launch"**. You will be prompted to select or create a key pair for SSH access.

## Step 4: Set Up NodeJS on the EC2 Instance

1.  **Connect to your EC2 instance via SSH:** Use the key pair you selected during launch and the public IP address or DNS name of your instance.

    ```bash
    ssh -i "your-key-pair.pem" ec2-user@your-instance-public-ip
    # or
    ssh -i "your-key-pair.pem" ubuntu@your-instance-public-dns
    ```

2.  **Install NodeJS and npm:** Follow the instructions specific to your AMI to install NodeJS and npm (Node Package Manager). For example, on Amazon Linux 2:

    ```bash
    sudo yum update -y
    sudo yum install -y nodejs npm
    ```

    For Ubuntu:

    ```bash
    sudo apt update -y
    sudo apt install -y nodejs npm
    ```

3.  **Verify installation:**

    ```bash
    node -v
    npm -v
    ```

## Step 5: Create the NodeJS Application on the EC2 Instance

This application will interact with the SQS queue using the AWS SDK for JavaScript.

1.  **Create a project directory:**

    ```bash
    mkdir sqs-consumer
    cd sqs-consumer
    ```

2.  **Initialize a NodeJS project:**

    ```bash
    npm init -y
    ```

3.  **Install the AWS SDK for JavaScript:**

    ```bash
    npm install aws-sdk
    ```

4.  **Create a JavaScript file (e.g., `sqs_consumer.js`):**

    ```javascript
    // sqs_consumer.js
    const AWS = require('aws-sdk');

    // Configure the AWS region
    AWS.config.update({ region: 'YOUR_AWS_REGION' }); // Replace with your AWS region

    // Create an SQS service object
    const sqs = new AWS.SQS({ apiVersion: '2012-11-05' });

    const queueURL = 'YOUR_SQS_QUEUE_URL'; // Replace with your SQS queue URL

    async function receiveMessage() {
      const params = {
        QueueUrl: queueURL,
        MaxNumberOfMessages: 10, // Adjust as needed
        WaitTimeSeconds: 20, // Enable long polling
      };

      try {
        const data = await sqs.receiveMessage(params).promise();

        if (data.Messages) {
          data.Messages.forEach(message => {
            console.log('Received message:', message.Body);
            // **Process your message here**

            // Delete the message from the queue after processing
            const deleteParams = {
              QueueUrl: queueURL,
              ReceiptHandle: message.ReceiptHandle,
            };

            sqs.deleteMessage(deleteParams, (err, data) => {
              if (err) {
                console.error('Error deleting message:', err);
              } else {
                console.log('Message deleted successfully');
              }
            });
          });
        } else {
          // No messages in the queue
          // console.log('No messages available.');
        }
      } catch (err) {
        console.error('Error receiving messages:', err);
      }
    }

    // Poll for messages every few seconds (or use a more robust approach)
    setInterval(receiveMessage, 5000);
    console.log('SQS consumer started...');
    ```

    **Replace `YOUR_AWS_REGION` and `YOUR_SQS_QUEUE_URL` with your actual values.** You can find the Queue URL in the SQS console when you select your queue.

5.  **Run the NodeJS application:**

    ```bash
    node sqs_consumer.js
    ```

    This application will now periodically poll the SQS queue for messages and process them.

## Step 6: (Optional) Set Up a Producer (e.g., another EC2 instance or AWS CLI)

The video might also demonstrate sending messages to the SQS queue. Here's a basic example using the AWS CLI from your local machine or another EC2 instance:

1.  **Ensure you have the AWS CLI installed and configured with appropriate credentials.**

2.  **Use the `aws sqs send-message` command:**

    ```bash
    aws sqs send-message --queue-url YOUR_SQS_QUEUE_URL --message-body "Hello from the producer!" --region YOUR_AWS_REGION
    ```

    Replace `YOUR_SQS_QUEUE_URL` and `YOUR_AWS_REGION` with your values.

## Step 7: Monitor and Test

1.  **Send messages to the SQS queue (if you set up a producer).**

2.  **Observe the output of your NodeJS application running on the EC2 instance.** You should see the messages being received and processed.

3.  **Check the SQS queue metrics in the AWS Management Console** to see the number of messages, messages in flight, and messages deleted.

4.  **If you configured a DLQ, monitor it for any messages that failed processing.**

## Important Considerations (Based on Potential Video Content):

* **Error Handling:** The NodeJS application should include robust error handling for message processing and deletion.
* **Scalability:** The video might touch upon how SQS and EC2 can scale to handle more messages and processing demands.
* **Security:** Ensure proper security group configurations and the principle of least privilege for IAM roles.
* **NodeJS AWS SDK Configuration:** The video might show different ways to configure the AWS SDK credentials (though using IAM roles attached to the EC2 instance is the recommended approach for this scenario).
* **Message Format:** The video might specify a particular message format (e.g., JSON). Adjust your NodeJS application accordingly.
* **Polling vs. Event-Driven (for Lambda):** The video specifically uses an EC2 instance. If a Lambda function were involved, the trigger mechanism would be event-driven via the Event Source Mapping (as shown in the previous response).

Remember to adapt these steps based on the specific details and implementation shown in the YouTube video you are following. Good luck with your AWS project!
