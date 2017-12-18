#!/usr/bin/env bash
# set -e

VERSION=8
REGION=us-east-1
AWS_ACCOUNT=545654232789
GIT_TOKEN=`cat github_token.txt`

ROOT_NAME=aqfer
APP_NAME=$ROOT_NAME$VERSION
TABLE_NAME=aqfer-idsync$VERSION
EC2_TAG_KEY=Key$APP_NAME
EC2_TAG_VAL=Value$APP_NAME
EC2_INSTANCE_ROLE=$ROOT_NAME'EC2InstanceRole'$VERSION

AMI=ami-55ef662f
KEYPAIR=AqferKeyPair
SECURITY_GROUP=launch-wizard-$VERSION

# Bucket name must be all lowercase, and start/end with lowecase letter or number
ARTIFACTS_BUCKET=cloudformation-art

PIPELINE_NAME=$ROOT_NAME'Pipeline'$VERSION
CODE_PIPELINE_ROLE=$ROOT_NAME'CodepipelineRole'$VERSION
CODE_BUILD_ROLE=$ROOT_NAME'CodeBuildRole'$VERSION
CODE_BUILD_NAME=$ROOT_NAME'CodeBuild'$VERSION
CODE_DEPLOY_APP=$ROOT_NAME'CodeDeploy'$VERSION
CODE_DEPLOY_ROLE=$ROOT_NAME'CodeDeployRole'$VERSION
CODE_DEPLOY_GROUP=$ROOT_NAME'CodeDeployGroup'$VERSION
PIPELINE_BUCKET=$ROOT_NAME-cloudformation$VERSION

# Create key pair
aws ec2 create-key-pair --key-name $KEYPAIR

# Create security group
# aws ec2 create-security-group --group-name $SECURITY_GROUP

# Create cloudformation bucket
aws s3 mb s3://$ARTIFACTS_BUCKET/ --region $REGION

# Create app_spec file from template
cat app_spec_o.json | sed 's/REGION_SUB/'$REGION'/' > /tmp/app_spec1.json
cat /tmp/app_spec1.json | sed 's/APP_NAME_SUB/'$APP_NAME'/' > /tmp/app_spec2.json
cat /tmp/app_spec2.json | sed 's/AMI_SUB/'$AMI'/' > /tmp/app_spec3.json
cat /tmp/app_spec3.json | sed 's/KEY_NAME_SUB/'$KEYPAIR'/' > /tmp/app_spec4.json
cat /tmp/app_spec4.json | sed 's/SECURITY_GROUP_SUB/'$SECURITY_GROUP'/' > /tmp/app_spec5.json
cat /tmp/app_spec5.json | sed 's/PIPELINE_BUCKET_SUB/'$PIPELINE_BUCKET'/' > /tmp/app_spec6.json
cat /tmp/app_spec6.json | sed 's/CODE_BUILD_ROLE_SUB/'$CODE_BUILD_ROLE'/' > /tmp/app_spec7.json
cat /tmp/app_spec7.json | sed 's/CODE_BUILD_NAME_SUB/'$CODE_BUILD_NAME'/' > /tmp/app_spec8.json
cat /tmp/app_spec8.json | sed 's/CODE_PIPELINE_ROLE_SUB/'$CODE_PIPELINE_ROLE'/' > /tmp/app_spec9.json
cat /tmp/app_spec9.json | sed 's/PIPELINE_NAME_SUB/'$PIPELINE_NAME'/' > /tmp/app_spec10.json
cat /tmp/app_spec10.json | sed 's/GIT_TOKEN_SUB/'$GIT_TOKEN'/' > /tmp/app_spec11.json 
cat /tmp/app_spec11.json | sed 's/AWS_ACCOUNT_SUB/'$AWS_ACCOUNT'/' > /tmp/app_spec12.json 
cat /tmp/app_spec12.json | sed 's/EC2_TAG_KEY_SUB/'$EC2_TAG_KEY'/' > /tmp/app_spec13.json 
cat /tmp/app_spec13.json | sed 's/EC2_TAG_VAL_SUB/'$EC2_TAG_VAL'/' > /tmp/app_spec14.json 
cat /tmp/app_spec14.json | sed 's/CODE_DEPLOY_APP_SUB/'$CODE_DEPLOY_APP'/' > /tmp/app_spec15.json
cat /tmp/app_spec15.json | sed 's/CODE_DEPLOY_GROUP_SUB/'$CODE_DEPLOY_GROUP'/' > /tmp/app_spec16.json
cat /tmp/app_spec16.json | sed 's/CODE_DEPLOY_ROLE_SUB/'$CODE_DEPLOY_ROLE'/' > /tmp/app_spec17.json
cat /tmp/app_spec17.json | sed 's/EC2_INSTANCE_ROLE_SUB/'$EC2_INSTANCE_ROLE'/' > /tmp/app_spec18.json
cat /tmp/app_spec18.json | sed 's/TABLE_NAME_SUB/'$TABLE_NAME'/' > app_spec.json

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
