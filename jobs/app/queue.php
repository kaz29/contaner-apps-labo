<?php
declare(strict_types=1);

require_once __DIR__ . '/vendor/autoload.php';

use MicrosoftAzure\Storage\Queue\Models\ListMessagesOptions;
use MicrosoftAzure\Storage\Queue\QueueRestProxy;

class Queue
{
    protected QueueRestProxy $client;

    public function __construct(
        private readonly string $connectionString,
        private readonly string $queueName
    ) {
        $this->client = QueueRestProxy::createQueueService($connectionString);
    }

    public function exec(): int
    {
        $message_options = new ListMessagesOptions();
        $message_options->setVisibilityTimeoutInSeconds(600);
        $message_options->setNumberOfMessages(1);
        $message_options->setTimeout('3');

        $listMessagesResult = $this->client->listMessages($this->queueName, $message_options);

        $messages = $listMessagesResult->getQueueMessages();
        if (count($messages) === 0) {
            echo 'No messages in the queue.' . PHP_EOL;

            return 0;
        }

        foreach ($messages as $message) {
            try {
                $data = json_decode(base64_decode($message->getMessageText()), true);
                if (json_last_error() !== JSON_ERROR_NONE) {
                    throw new \Exception('Invalid JSON in message: ' . json_last_error_msg());
                }

                if (!isset($data['id'])) {
                    throw new \Exception('Message does not contain an ID.');
                }

                echo "Processing message: id: {$data['id']}" . PHP_EOL;
                $this->client->deleteMessage(
                    $this->queueName,
                    $message->getMessageId(),
                    $message->getPopReceipt()
                );
            } catch (\Exception $e) {
                echo sprintf('Failed to process message: %s', $e->getMessage()) . PHP_EOL;
            }
        }

        return 0;
    }
}

$connectionString = getenv('QUEUE_CONNECTION_STRING');
$queue = new Queue($connectionString, getenv('QUEUE_NAME'));

$queue->exec();
