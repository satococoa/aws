# coding: utf-8
require 'pp'
configure do
  config = YAML::load_file('config.yml')
  ACCESS = config['aws']['access']
  SECRET = config['aws']['secret']

  S3 = RightAws::S3.new(ACCESS, SECRET)
end

get '/' do
  haml :index
end

# bucketの操作
get '/buckets' do
  @buckets = S3.buckets
  haml :buckets
end

# 新しいbucketの作成
post '/buckets' do
  begin
    bucket = S3.bucket(params[:bucket], true)
  rescue RightAws::AwsError => e
    @errors = []
    @errors << e.message
  end
  @buckets = S3.buckets
  haml :buckets
end

# keyの一覧
get '/bucket/:bucket_name/keys' do |bucket_name|
  @bucket = S3.bucket(bucket_name)
  @keys = @bucket.keys
  haml :keys
end

# ファイルアップロード
post '/bucket/:bucket_name/keys' do |bucket_name|
  @bucket = S3.bucket(bucket_name)
  file = params[:object]
  begin
    key = @bucket.put(file[:filename], file[:tempfile], {}, 'public-read-write')
  rescue => e
    pp e
  end
  @keys = @bucket.keys
  haml :keys
end
