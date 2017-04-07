
# WARNING - PYSPARK IN DEVELOPMENT

# spark-social-science
Automated Spark Cluster Builds with PySpark for [geografia.com.au](http://geografia.com.au) (adapted from https://github.com/UrbanInstitute/spark-social-science)

The goal of this project is to deliver powerful and elastic Spark clusters to researchers and data analysts with as little setup time and effort possible. To do that, at the Urban Institute, we use two critical components: (1) a Amazon Web Services (AWS) CloudFormation script to launch AWS Elastic MapReduce (EMR) clusters (2) a bootstrap script that runs on the Master node of the new cluster to install statistical programs and development environments (Jupyter Notebooks). Further down, you can also look at an AWS Command Line approach to using the bootstrap scripts.

This guide illustrates the (relatively) straight forward process to provide clusters for your analysts and researchers. For more information about using Spark via Python APIs, see these repositories:

* https://github.com/UrbanInstitute/pyspark-tutorials

### Security Disclaimer:

I am not a security expert and this guide does not specify security specifics necessary for secure data analysis. There are many important security considerations when doing data analysis in the cloud that this guide does not cover. Please make sure to consult with security experts whenever working in cloud compute.


## Setup

Just a few steps will get you to working Spark Clusters. We're going to setup the bootstrap scripts first, then the CloudFormation script. Note that all the required changes that you need to make involve replacing text that contains the phrase 'goes-here'. Search for that phrase within the CloudFormation script and bootstrap files to make sure you have replaced all those text fields.

### 1. Setup Your Bootstrap Scripts

Bootstrap scripts run at the start of the cluster launch. We're going to host them in AWS S3, then reference them in our CloudFormation Template. So, everytime we launch a cluster, the bootstrap scripts will run, setting up our statistical environment: Python and Jupyter Notebooks pointed at PySpark.

First, create an AWS S3 bucket for your EMR scripts and logs. You'll want to put the pertinent shell script (`jupyter_pyspark_emr5-proc.sh`) into that bucket. Then make a subfolder for your logs.

### 2. Setup Your CloudFormation Template

The CloudFormation Script needs a few changes to work as well.

We have created a `configuration.yml` file where you can specify your bucket locations:

```yaml
pyspark:
  aws_bootstrap_bucket: s3://sabman-european-cities-analysis
  aws_logs_bucket: s3://sabman-european-cities-analysis
```
Just replace these with your buckets and then run the `create_bootstrap_script.rb` script. This script will generate a new CloudFormation Template.

Also change the CIDR IP to your organzation's or your personal computer's IP. This will only allow your organization or your computer to access the ports you are opening for Jupyter / Ganglia. This is optional, but know that if you do not do this, anyone can access your cluster at these ports.


### 3.a. Launch a Cluster with CloudFormation
* Go to CloudFormation on the AWS Dashboard - Hit Create Stack
* Upload your CloudFormation Script - Hit Next
* On the 'Specify Details' page, you need to make a few changes, though once you have these figured out you can add them to the CloudFormation script.
	* Create a Stack Name
	* Set a Key Pair setup for your account (can set as a default within CloudFormation);
	* Set a VPC - the default VPC that came with your AWS account will work;
	* Set a Subnet ([can be private or public](https://aws.amazon.com/about-aws/whats-new/2015/12/launch-amazon-emr-clusters-in-amazon-vpc-private-subnets/));
	* Set other options as needed, including changing the number of cores, the type of EC2 instances, and the tags (you can, but I don't recommend changing the ports).

* Hit next at the bottom of this screen, add tags if you want on the next screen, and hit Create Cluster.
* Go to your EMR dashboard and grab the DNS for the Master node. The whole string is your public DNS. 

You should then be able to go to these URLs.
* Jupyter Notebooks at DNS:8194
* Ganglia Cluster Monitoring at DNS/ganglia


### 3.b. Launch a Cluster with the AWS Command Line

If you have installed and configured the AWS Command Line Interfance (CLI), you can run a single line to create a cluster. Note the CloudFormation scripts creates a security group during bootstrap and assigns it to the cluster. Below, you have to assign an existing security group `addtl-master-security-group` that opens up the correct port (8194 for Jupyter).

```shell
aws emr create-cluster --release-label emr-5.3.1 ^
  --name 'pyspark-2.0' ^
  --applications Name=Spark Name=Ganglia ^
  --ec2-attributes KeyName=your-key-pair,InstanceProfile=EMR_EC2_DefaultRole,AdditionalMasterSecurityGroups="addtl-master-security-group",SubnetId="your-subnet" ^
  --service-role EMR_DefaultRole ^
  --instance-groups ^
    InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m4.xlarge ^
    InstanceGroupType=CORE,InstanceCount=2,InstanceType=m4.xlarge ^
  --region us-east-1 ^
  --log-uri s3://logs-bucket-name-goes-here ^
  --bootstrap-actions Path="s3://your-bucket-name-goes-here/jupyter_pyspark_emr5-proc.sh"
```


