#!/bin/bash

echo "export TF_VAR_S3_ACCESS_KEY=\"${TF_VAR_S3_ACCESS_KEY}\"" >> /home/centos/tf3.sh
echo "export TF_VAR_S3_SECRET_KEY=\"${TF_VAR_S3_SECRET_KEY}\"" >> /home/centos/tf3.sh
echo "export TF_VAR_S3_BUCKET_NAME=\"${TF_VAR_S3_BUCKET_NAME}\"" >> /home/centos/tf3.sh

sudo cp /home/centos/tf3.sh /etc/profile.d/tf3.sh