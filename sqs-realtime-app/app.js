// app.js

require('dotenv').config(); // Load environment variables

const express = require('express');
const { SQSClient, SendMessageCommand, ReceiveMessageCommand } = require('@aws-sdk/client-sqs');
const bodyParser = require('body-parser');
const ejs = require('ejs');
const path = require('path');

const app = express();
const port = 3000;

// Initialize AWS SQS client using v3
const sqs = new SQSClient({ region: process.env.AWS_REGION });

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Routes

// Home page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Send message form
app.get('/send', (req, res) => {
  res.sendFile(path.join(__dirname, 'send.html'));
});

// Handle message send
app.post('/send', async (req, res) => {
  const { message } = req.body;

  const params = {
    MessageBody: message,
    QueueUrl: process.env.QUEUE_URL,
  };

  try {
    const command = new SendMessageCommand(params);
    const data = await sqs.send(command);
    console.log('Message sent to SQS:', data.MessageId);
    res.redirect('/');
  } catch (err) {
    console.error('Error sending message to SQS:', err);
    res.status(500).send('Error sending message to SQS');
  }
});

// View messages
app.get('/messages', async (req, res) => {
  const params = {
    QueueUrl: process.env.QUEUE_URL,
    AttributeNames: ['All'],
    MaxNumberOfMessages: 10,
    WaitTimeSeconds: 0,
  };

  try {
    const command = new ReceiveMessageCommand(params);
    const data = await sqs.send(command);
    const messages = data.Messages || [];
    res.render('messages', { messages });
  } catch (err) {
    console.error('Error receiving messages from SQS:', err);
    res.status(500).send('Error receiving messages from SQS');
  }
});

// Start server
app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});

