

## Deploying Bastion host with OpenTofu

1) Change directory to Terraform folder

```sh
cd iac/terraform
```

2) Initialize

```sh
tofu init
```

3) Deploy resources

```sh
tofu apply
```

4) Port forward session to Bastion (using System Manager)

```sh
export BASTION_NAME="bastion-terraform"
export DATABASE_NAME="database-terraform"
export AWS_REGION="us-east-1"

SECRET_ARN=$(aws rds describe-db-instances --db-instance-identifier \
  $DATABASE_NAME --query 'DBInstances[0].MasterUserSecret.SecretArn' --output text)
SECRET_VALUE_RAW=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN | jq '.SecretString')
DB_USERNAME=$(echo $SECRET_VALUE_RAW | jq -r | jq -r ".username")
DB_PASSWORD=$(echo $SECRET_VALUE_RAW | jq -r | jq -r ".password")
DB_PORT=$(aws rds describe-db-instances --db-instance-identifier \
  $DATABASE_NAME --query 'DBInstances[0].Endpoint.Port' --output text)
DB_DATABASE=$(aws rds describe-db-instances \
  --db-instance-identifier $DATABASE_NAME \
  --query 'DBInstances[0].DBName' --output text)
echo "Connect to the database using the following inputs:"
echo "\n\nHost => localhost\nDatabase => $DB_DATABASE\nUSERNAME => $DB_USERNAME\nPASSWORD => $DB_PASSWORD\nPORT => $DB_PORT"

CLUSTER_HOST=$(aws rds describe-db-instances \
  --db-instance-identifier $DATABASE_NAME \
  --query 'DBInstances[0].Endpoint.Address' --output text)
BASTION_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$BASTION_NAME" \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].InstanceId" --output text)
aws --region=us-east-1 ssm start-session \
  --target $BASTION_INSTANCE_ID \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$CLUSTER_HOST\"],\"portNumber\":[\"5432\"], \"localPortNumber\":[\"$DB_PORT\"]}"
```

Notice that your terminal will be "blocked" with a pending session with the bastion host. If you close or cancel the command the connection is lost and you won't be able to reach the database.

5) Connect to the database

Now use your preferred GUI tool (e.g. DBeaver) to connect to your database or use the CLI (e.g. psql). Use the credentials/endpoint that were printed in the previour step (step 4).

6) Connect to the instance via SSM Agent

```sh
BASTION_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$BASTION_NAME" \
    --filters "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)
aws ssm start-session --target $BASTION_INSTANCE_ID --region us-east-1
```

## Deploying Bastion host with CDK


1) Change directory to CDK folder

```sh
cd iac/cdk
```

1) Install dependencies

```sh
yarn
```

2) Deploy resources

```sh
yarn deploy
```

Make sure that before doing that your AWS Account is [CDK Bootstrapped](https://docs.aws.amazon.com/cdk/v2/guide/bootstrapping.html) in the desired AWS region.