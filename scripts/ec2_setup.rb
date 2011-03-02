# coding: utf-8
require 'right_aws'
require 'yaml'
require 'logger'

config = YAML::load_file('../config.yml')
ACCESS = config['aws']['access']
SECRET = config['aws']['secret']
log = Logger.new(STDOUT)

ec2 = RightAws::Ec2.new(ACCESS, SECRET, :region => 'ap-northeast-1')

# EC2立ち上げ
instances = ec2.run_instances('ami-8e08a38f', 1, 1, ['default'],
                             "Satoshi's Keys",'from ruby script', nil, 't1.micro')

# インスタンスIDとインスタンスのアベイラビリティゾーンを取得
instance_id = instances[0][:aws_instance_id]
availability_zone = instances[0][:aws_availability_zone]

log.info("Instance ID: #{instance_id}, Availability Zone: #{availability_zone}")

# ステータスがrunningになるまでポーリング
running = false
begin
  state = ec2.describe_instances(instance_id)[0][:aws_state]
  if state == 'running'
    running = true
  else
    sleep 10
  end
  log.info("State: #{state}")
end until running

# IPアドレスの割り当て
ip = ec2.allocate_address
ec2.associate_address(instance_id, ip)
log.info("IP: #{ip}")

# 1GBのEBSボリュームを1つ作成し、IDを求める
ebs = ec2.create_volume(nil, 1, availability_zone)
ebs_id = ebs[:aws_id]
log.info("EBS ID: #{ebs_id}")

# EBSボリュームを割り当てる
ec2.attach_volume(ebs_id, instance_id, '/dev/sdf')
log.info("Mission Completed!")
