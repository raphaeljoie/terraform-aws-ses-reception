import boto3
from email.parser import BytesParser
from email import policy
import json
import mimetypes
import logging
import os
from urllib import parse

logger = logging.getLogger('lambda')
logger.setLevel('DEBUG')

s3 = boto3.resource('s3')
s3_client = boto3.client('s3')
# Make sure to provide the bucket name in 'AWS_BUCKET_NAME' environment variable
BUCKET = os.getenv('AWS_BUCKET_NAME')
bucket = s3.Bucket(BUCKET)
#
OBJECT_PREFIX = os.getenv('AWS_BUCKET_OBJECT_PREFIX', '')


class ByteHolder:
    def __init__(self, content):
        self.content = content

    def read(self, *args, **kwargs):
        return self.content


def lambda_handler(event, context):
    logger.debug(json.dumps(event))

    records = event.get('Records', [])
    ses = (dict() if len(records) == 0 else records[0]).get('ses')

    if ses is None:
        raise Exception(
            'Unexpected event. see https://docs.aws.amazon.com/ses/latest/dg/receiving-email-action-lambda-event.html')

    ses_mail = ses.get('mail')
    message_id = ses_mail.get('messageId')
    source = ses_mail.get('source')
    destination = ses_mail.get('destination')
    meta = {
        'source': source,
        'destination': destination[0],  # TODO cover multiple destination case
    }
    object_key = f'{message_id}'

    logger.info(f'Reception of SES mail with messageId={message_id}')

    # security check
    receipt = ses.get('receipt')
    statuses = [
        receipt['spamVerdict']['status'],
        receipt['virusVerdict']['status'],
        receipt['spfVerdict']['status'],
        receipt['dkimVerdict']['status']
    ]
    if 'FAIL' in statuses:
        raise Exception('Message security check failed')

    # Ensure metadata to message email.
    s3_client.put_object_tagging(
        Bucket=BUCKET,
        Key=object_key,
        Tagging={'TagSet': list(map(lambda i: {'Key': i[0], 'Value': str(i[1])}, meta.items()))})
    # Load message email
    raw_email = bucket.Object(message_id).get()['Body'].read()
    # parse message email
    msg = BytesParser(policy=policy.SMTP).parsebytes(raw_email)

    for attachment in msg.iter_attachments():
        file_name = attachment.get_filename()  # TODO default value
        content_type = attachment.get_content_type()
        extension = os.path.splitext(attachment.get_filename())[1] if file_name else None
        extension = mimetypes.guess_extension(attachment.get_content_type()) if extension is None else extension
        data = attachment.get_content()

        logger.info(f'Message have attachment "{file_name}" ({len(data)} bytes "{content_type}")')

        s3_client.upload_fileobj(ByteHolder(data), Bucket=BUCKET, Key=f'{message_id}/{file_name}', ExtraArgs={
            'ContentType': content_type,
            'Tagging': parse.urlencode(meta),
            'Metadata': meta
        })

    body = {}
    for body_type in ['plain', 'html']:
        body[body_type] = msg.get_body(preferencelist=(body_type))
        if body[body_type] is None:
            logger.info(f"Message have no {body_type} content")
        else:
            body[body_type] = ''.join(body[body_type].get_content().splitlines(keepends=True))
            logger.info(f"Message have '{body_type}' content with len {len(body[body_type])}")
