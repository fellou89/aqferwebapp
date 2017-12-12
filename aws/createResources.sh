#!/usr/bin/env bash
# set -e

VERSION=3
REGION=us-east-1
AWS_ACCOUNT=545654232789
AMI=ami-55ef662f
KEYPAIR=AqferKeyPair
SECURITY_GROUP=launch-wizard-$VERSION

ROOT_NAME=aqfer
APP_NAME=$ROOT_NAME$VERSION
TABLE_NAME=aqfer-idsync$VERSION

# Bucket name must be all lowercase, and start/end with lowecase letter or number
ARTIFACTS_BUCKET=cloudformation-art

PIPELINE_NAME=$ROOT_NAME'Pipeline'$VERSION
CODE_PIPELINE_ROLE=$ROOT_NAME'CodepipelineRole'$VERSION
CODE_BUILD_ROLE=$ROOT_NAME'CodeBuildRole'$VERSION
CODE_BUILD_NAME=$ROOT_NAME'CodeBuild'$VERSION

UNAUTH_ROLE_NAME=$ROOT_NAME'UnauthRole'$VERSION
AUTH_ROLE_NAME=$ROOT_NAME'AuthRole'$VERSION

# Create key pair
aws ec2 create-key-pair --key-name $KEYPAIR

# Create security group
# aws ec2 create-security-group --group-name $SECURITY_GROUP

# Create cloudformation bucket
aws s3 mb s3://$ARTIFACTS_BUCKET/ --region $REGION

# Create app_spec file from template
cat app_spec_o.json | sed 's/REGION/'$REGION'/' > /tmp/app_spec1.json
cat /tmp/app_spec1.json | sed 's/APP_NAME/'$APP_NAME'/' > /tmp/app_spec2.json
cat /tmp/app_spec2.json | sed 's/AMI_SUB/'$AMI'/' > /tmp/app_spec3.json
cat /tmp/app_spec3.json | sed 's/KEY_NAME_SUB/'$KEYPAIR'/' > /tmp/app_spec4.json
cat /tmp/app_spec4.json | sed 's/SECURITY_GROUP_SUB/'$SECURITY_GROUP'/' > /tmp/app_spec5.json
cat /tmp/app_spec5.json | sed 's/TABLE_NAME_SUB/'$TABLE_NAME'/' > app_spec.json

# Launch cloudformation stack
aws cloudformation package --template-file app_spec.json --output-template-file new_app_spec.json --s3-bucket $ARTIFACTS_BUCKET
aws cloudformation deploy --template-file new_app_spec.json --stack-name $APP_NAME --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
aws cloudformation describe-stack-resources --stack-name $APP_NAME | grep -B 1 "LogicalResource.*Pool[^Roles]" > /tmp/pool_ids

# Get ids
identityPoolId=$(cat /tmp/pool_ids | sed -n "N;s/.*\"\(.*\)\",.*\n.*IdentityPool\"/\1/p")
userPoolId=$(grep -b1 "\"UserPool\"" /tmp/pool_ids | grep -o $REGION[_a-zA-Z0-9]*)
userPoolClientId=$(cat /tmp/pool_ids | sed -n "N;s/.*\"\(.*\)\",.*\n.*UserPoolClient\"/\1/p")

echo "Identity Pool id: "$identityPoolId
echo "User Pool id: "$userPoolId
echo "Client id: "$userPoolClientId
echo "App name: " $APP_NAME
