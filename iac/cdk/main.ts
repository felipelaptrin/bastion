import "source-map-support/register";
import * as cdk from "aws-cdk-lib";
import { Stack } from "./stack";
import { InstanceClass, InstanceSize, InstanceType } from "aws-cdk-lib/aws-ec2";

const app = new cdk.App();

new Stack(app, "BastionStack", {
  env: {
    region: "us-east-1",
  },
  instanceType: InstanceType.of(InstanceClass.T3, InstanceSize.SMALL),
  vpcCidrBlock: "10.130.0.0/16",
});
