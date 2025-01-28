import * as cdk from "aws-cdk-lib";
import {
  BastionHostLinux,
  InstanceClass,
  InstanceSize,
  IpAddresses,
  Port,
  SubnetType,
  Vpc,
} from "aws-cdk-lib/aws-ec2";
import { Construct } from "constructs";
import { InstanceType } from "aws-cdk-lib/aws-ec2";
import {
  Credentials,
  DatabaseInstance,
  DatabaseInstanceEngine,
  PostgresEngineVersion,
} from "aws-cdk-lib/aws-rds";

export interface BastionProps extends cdk.StackProps {
  vpcCidrBlock: string;
  instanceType: InstanceType;
}

export class Stack extends cdk.Stack {
  public readonly vpc: Vpc;

  constructor(scope: Construct, id: string, props: BastionProps) {
    super(scope, id, props);

    this.vpc = new Vpc(this, "Vpc", {
      ipAddresses: IpAddresses.cidr(props.vpcCidrBlock),
      subnetConfiguration: [
        {
          cidrMask: 22,
          name: "Private",
          subnetType: SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 22,
          name: "PrivateForDB",
          subnetType: SubnetType.PRIVATE_ISOLATED,
        },
        {
          cidrMask: 22,
          name: "Public",
          subnetType: SubnetType.PUBLIC,
        },
      ],
      natGateways: 1,
    });

    const database = new DatabaseInstance(this, "Database", {
      vpc: this.vpc,
      engine: DatabaseInstanceEngine.postgres({
        version: PostgresEngineVersion.VER_14,
      }),
      instanceType: InstanceType.of(InstanceClass.T4G, InstanceSize.LARGE),
      multiAz: false,
      allocatedStorage: 5,
      vpcSubnets: {
        subnetType: SubnetType.PRIVATE_ISOLATED,
      },
      credentials: Credentials.fromGeneratedSecret("postgres"),
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      databaseName: "main",
      instanceIdentifier: "database-cdk",
    });

    const bastion = new BastionHostLinux(this, "BastionEc2", {
      vpc: this.vpc,
      instanceName: "bastion-cdk",
      instanceType: props.instanceType,
      subnetSelection: {
        subnetType: SubnetType.PRIVATE_WITH_EGRESS,
      },
    });
    bastion.connections.allowTo(database, Port.tcp(5432));
  }
}
