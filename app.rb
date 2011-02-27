# coding: utf-8
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
  @errors = []
  begin
    bucket = S3.bucket(params[:bucket], true)
    redirect '/buckets'
  rescue RightAws::AwsError => e
    @errors << e.message
    @buckets = S3.buckets
    haml :buckets
  end
end
  
