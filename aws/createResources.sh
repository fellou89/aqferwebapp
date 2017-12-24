#!/usr/bin/env bash
# set -e


# "ECSTaskService" : {
#       "Type" : "AWS::ECS::Service",
#       "Properties" : {
#         "Cluster" : !Ref ECSCluster,
#         "DeploymentConfiguration" : DeploymentConfiguration,
#         "DesiredCount" : Integer,
#         "LaunchType" : String,
#         "LoadBalancers" : [ Load Balancer Objects, ... ],
#         "NetworkConfiguration" : NetworkConfiguration,
#         "PlacementConstraints" : [ PlacementConstraints, ... ],
#         "Role" : String,
#         "PlacementStrategies" : [ PlacementStrategies, ... ],
#         "PlatformVersion" : String,
#         "ServiceName" : "ECS_SERVICE_SUB",
#         "TaskDefinition" : !Ref ECSTaskDefinition.
#       }
#     },


VERSION=1
REGION=us-east-1
AMI=ami-55ef662f
#  AMI=ami-fad25980 # ecs optimized ami
AWS_ACCOUNT=545654232789
KEYPAIR=AqferKeyPair

ROOT_NAME=aqfer
APP_NAME=$ROOT_NAME$VERSION
DYNAMO_TABLE=$ROOT_NAME-idsync$VERSION
ECS_CLUSTER=$ROOT_NAME'Cluster'$VERSION
ECS_SERVICE=$ROOT_NAME'Service'$VERSION
EC2_INSTANCE_ROLE=$ROOT_NAME'EC2InstanceRole'$VERSION
TASK_DEFINITION=$ROOT_NAME'TaskDefinition'$VERSION
SECURITY_GROUP=$ROOT_NAME-sg$VERSION

# Bucket name must be all lowercase, and start/end with lowecase letter or number
ARTIFACTS_BUCKET=cloudformation-art

# Create ecr repo for docker image
aws ecr create-repository --region $REGION --repository-name ecr-$ROOT_NAME'1' > /tmp/ecrUri
aws ecr describe-repositories --region $REGION --repository-name ecr-$ROOT_NAME'1' > /tmp/ecrUri
ecrRepoUri=$(cat /tmp/ecrUri | sed -n "N;s/.*repositoryUri.*\"\(.*\)\".*/\1/p")

# Log into ecr
aws ecr get-login --region $REGION --no-include-email | sed 's/docker login -u AWS -p \([^ ]*\) .*/\1/' | docker login -u AWS --password-stdin $ecrRepoUri

# ecr
docker tag $ROOT_NAME-caddy:latest $ecrRepoUri
docker push $ecrRepoUri

# Create key pair
aws ec2 create-key-pair --key-name $KEYPAIR
   
#  # Create security group
#  aws ec2 create-security-group --group-name $SECURITY_GROUP
   
# Create cloudformation bucket
aws s3 mb s3://$ARTIFACTS_BUCKET/ --region $REGION
   
# Create app_spec file from template
cat app_spec_o.json | sed 's/REGION_SUB/'$REGION'/' > /tmp/app_spec1.json
cat /tmp/app_spec1.json | sed 's/AMI_SUB/'$AMI'/' > /tmp/app_spec2.json
cat /tmp/app_spec2.json | sed 's/AWS_ACCOUNT_SUB/'$AWS_ACCOUNT'/' > /tmp/app_spec3.json 
cat /tmp/app_spec3.json | sed 's/KEY_NAME_SUB/'$KEYPAIR'/' > /tmp/app_spec4.json
cat /tmp/app_spec4.json | sed 's/SECURITY_GROUP_SUB/'$SECURITY_GROUP'/' > /tmp/app_spec5.json
cat /tmp/app_spec5.json | sed 's/EC2_INSTANCE_ROLE_SUB/'$EC2_INSTANCE_ROLE'/' > /tmp/app_spec6.json
cat /tmp/app_spec6.json | sed 's/TASK_DEFINITION_SUB/'$TASK_DEFINITION'/' > /tmp/app_spec7.json
cat /tmp/app_spec7.json | sed 's/ECS_CLUSTER_SUB/'$ECS_CLUSTER'/' > /tmp/app_spec8.json
cat /tmp/app_spec8.json | sed 's/ECS_SERVICE_SUB/'$ECS_SERVICE'/' > /tmp/app_spec9.json
cat /tmp/app_spec9.json | sed 's#ECR_REPO_URI_SUB#'$ecrRepoUri'#' > /tmp/app_spec10.json
cat /tmp/app_spec10.json | sed 's/DYNAMO_TABLE_SUB/'$DYNAMO_TABLE'/' > app_spec.json
   
# Launch cloudformation stack
aws cloudformation package --template-file app_spec.json --output-template-file new_app_spec.json --s3-bucket $ARTIFACTS_BUCKET
aws cloudformation deploy --template-file new_app_spec.json --stack-name $APP_NAME --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM

echo "App name: " $APP_NAME
