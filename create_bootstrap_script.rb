require 'erb'
require 'yaml'

config               = YAML.load_file('./configuration.yml')
output               = './pyspark/EMR_SPARK_JUPYTER_TEMPLATE.json'
bootstrap_script     = 'jupyter_pyspark_emr5-proc.sh'
aws_bootstrap_bucket = config["pyspark"]["aws_bootstrap_bucket"] + "/#{bootstrap_script}"
aws_logs_bucket      = config["pyspark"]["aws_logs_bucket"]
template             = File.read('./pyspark/EMR_SPARK_JUPYTER_TEMPLATE.json.erb')
renderer             = ERB.new(template)

puts "Using the following AWS configuration values:"
puts aws_bootstrap_bucket, aws_logs_bucket

File.open(output, 'w+'){ |f| f.puts(renderer.result()) }
puts "new CloudFormation configuration written to: #{output}"
